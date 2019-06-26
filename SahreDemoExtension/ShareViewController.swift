//
//  ShareViewController.swift
//  ProductHuntExtension
//
//  Created by Jitendra Singh on 13/06/19.
//  Copyright © 2019 Jitendra Singh. All rights reserved.
//

import UIKit
import Social
import MobileCoreServices
import AVFoundation
class ShareViewController: SLComposeServiceViewController {
    let contentTypeURL = kUTTypeURL as String
    let contentTypeText = kUTTypeText as String
    let contentTypeImage =  kUTTypeImage  as String
    var docPath = ""
    var typeOfData = ""
    override func viewDidLoad() {
        super.viewDidLoad()
        
        let containerURL = FileManager().containerURL(forSecurityApplicationGroupIdentifier: "group.test.DemoShareExtensiontest.ShareExtension")!
        docPath = "\(containerURL.path)/share"
        
        //  Create directory if not exists
        do {
            try FileManager.default.createDirectory(atPath: docPath, withIntermediateDirectories: true, attributes: nil)
        } catch let error as NSError {
            print("Could not create the directory \(error)")
        } catch {
            fatalError()
        }
        
        //  removing previous stored files
        let files = try! FileManager.default.contentsOfDirectory(atPath: docPath)
        for file in files {
            try? FileManager.default.removeItem(at: URL(fileURLWithPath: "\(docPath)/\(file)"))
        }
    }
    
    override func viewDidAppear(_ animated: Bool) {
        let alertView = UIAlertController(title: "Export", message: " ", preferredStyle: .alert)
        self.present(alertView, animated: true, completion: {
            let group = DispatchGroup()
            NSLog("inputItems: \(self.extensionContext!.inputItems.count)")
            for item: Any in self.extensionContext!.inputItems {
                let inputItem = item as! NSExtensionItem
                for provider: Any in inputItem.attachments! {
                    let itemProvider = provider as! NSItemProvider
                    group.enter()
                    guard let prefs = UserDefaults(suiteName: "group.test.DemoShareExtensiontest.ShareExtension") else{
                        return
                    }
                    self.removePreviousSavedData(prefs: prefs)
                    if itemProvider.isURL{
                        self.shareURL(itemProvider: itemProvider, dispatchGroup: group, prefs: prefs)
                    }
                    if itemProvider.isImage{
                        self.shareImage(itemProvider: itemProvider, dispatchGroup: group, prefs: prefs)
                    }
                    if itemProvider.isText{
                        self.shareText(itemProvider: itemProvider, dispatchGroup: group, prefs: prefs)
                    }
                    if itemProvider.isVideo{
                        self.shareVideo(itemProvider: itemProvider, dispatchGroup: group, prefs: prefs)
                    }
                }
            }
            group.notify(queue: DispatchQueue.main) {
                NSLog("done")
                _ = self.openURL(URL(string: "ImageSharing://\(self.typeOfData)")!)
                self.dismiss(animated: false) {
                    self.extensionContext!.completeRequest(returningItems: [], completionHandler: nil)
                }
            }
        })
    }
    
    //  Function must be named exactly like this so a selector can be found by the compiler!
    //  Anyway - it's another selector in another instance that would be "performed" instead.
    @objc func openURL(_ url: URL) -> Bool {
        var responder: UIResponder? = self
        while responder != nil {
            if let application = responder as? UIApplication {
                return application.perform(#selector(openURL(_:)), with: url) != nil
            }
            responder = responder?.next
        }
        return false
    }
}
extension NSItemProvider {
    var isURL: Bool {
        return hasItemConformingToTypeIdentifier(kUTTypeURL as String)
    }
    var isText: Bool {
        return hasItemConformingToTypeIdentifier(kUTTypeText as String)
    }
    var isImage:Bool{
        return hasItemConformingToTypeIdentifier(kUTTypeImage as String)
    }
    var isVideo:Bool {
        return hasItemConformingToTypeIdentifier(kUTTypeMPEG4 as String)
    }
}
extension ShareViewController{
    func removePreviousSavedData(prefs:UserDefaults) {
        prefs.removeObject(forKey: "image")
        prefs.removeObject(forKey: "url")
        prefs.removeObject(forKey: "text")
        prefs.removeObject(forKey: "video")
    }
    func shareURL(itemProvider:NSItemProvider,dispatchGroup:DispatchGroup, prefs:UserDefaults) {
        itemProvider.loadItem(forTypeIdentifier: kUTTypeURL as String, options: nil) { data, error in
            if error == nil {
                var urlString = ""
                self.typeOfData = "url"
                itemProvider.loadItem(forTypeIdentifier: "public.url", options: nil, completionHandler: { (results, error) in
                    let url = results as! URL?
                    urlString = url!.absoluteString
                    prefs.set(urlString.data(using: String.Encoding.utf8), forKey: "url")
                })
            } else {
                NSLog("\(String(describing: error))")
            }
            dispatchGroup.leave()
        }
    }
    func shareImage(itemProvider:NSItemProvider,dispatchGroup:DispatchGroup, prefs:UserDefaults ) {
        itemProvider.loadItem(forTypeIdentifier: kUTTypeImage as String, options: [:]) { (data, error) in
            var image: UIImage?
            if let someURl = data as? URL {
                image = UIImage(contentsOfFile: someURl.path)
            }else if let someImage = data as? UIImage {
                image = someImage
            }
            if let someImage = image {
                guard let compressedImagePath = FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask).first?.appendingPathComponent("shareImage.jpg", isDirectory: false) else {
                    return
                }
                let compressedImageData = someImage.jpegData(compressionQuality:1)
                guard (try? compressedImageData?.write(to: compressedImagePath)) != nil else {
                    return
                }
                prefs.set(compressedImageData, forKey: "image")
                self.typeOfData = "image"
            }else{
                print("bad share data")
            }
            dispatchGroup.leave()
        }
    }
    func shareText(itemProvider:NSItemProvider,dispatchGroup:DispatchGroup, prefs:UserDefaults ) {
        itemProvider.loadItem(forTypeIdentifier: self.contentTypeText, options: nil, completionHandler: { (results, error) in
            let text = results as! String
            prefs.set(text.data(using: String.Encoding.utf8), forKey: "text")
            self.typeOfData = "text"
            _ = self.isContentValid()
            dispatchGroup.leave()
        })
    }
    func shareVideo(itemProvider:NSItemProvider,dispatchGroup:DispatchGroup, prefs:UserDefaults ) {
        itemProvider.loadItem(forTypeIdentifier: kUTTypeMovie as String, options: [:]) { (data, error) in
            self.encodeVideo(data as! URL, dispatchGroup: dispatchGroup,prefs: prefs)
            self.typeOfData = "video"
//            let opts = [AVURLAssetPreferPreciseDurationAndTimingKey : NSNumber(value: false)]
//            let urlAsset = AVURLAsset(url: data as! URL, options: opts as? [String : Any])
//            let second = Int(Int(urlAsset.duration.value) / Int(urlAsset.duration.timescale))
            //            dispatchGroup.leave()
        }
    }
    func encodeVideo(_ videoURL: URL,dispatchGroup:DispatchGroup,prefs:UserDefaults)  {
        let avAsset = AVURLAsset(url: videoURL, options: nil)
        let startDate = Foundation.Date()
        //Create Export session
        var exportSession = AVAssetExportSession(asset: avAsset, presetName: AVAssetExportPresetPassthrough)
        // exportSession = AVAssetExportSession(asset: composition, presetName: mp4Quality)
        //Creating temp path to save the converted video
        let documentsDirectory = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true)[0]
        let myDocumentPath = URL(fileURLWithPath: documentsDirectory).appendingPathComponent("temp.mp4").absoluteString
        let url = URL(fileURLWithPath: myDocumentPath)
        
        let documentsDirectory2 = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0] as URL
        
        let filePath = documentsDirectory2.appendingPathComponent("rendered-Video.mp4")
        deleteFile(filePath)
        
        //Check if the file already exists then remove the previous file
        if FileManager.default.fileExists(atPath: myDocumentPath) {
            do {
                try FileManager.default.removeItem(atPath: myDocumentPath)
            }
            catch let error {
                print(error)
            }
        }

        exportSession!.outputURL = filePath
        exportSession!.outputFileType = AVFileType.mp4
        exportSession!.shouldOptimizeForNetworkUse = true
        let start = CMTimeMakeWithSeconds(0.0, preferredTimescale: 0)
        let range = CMTimeRangeMake(start: start, duration: avAsset.duration)
        exportSession?.timeRange = range
        
        exportSession?.exportAsynchronously(completionHandler: {() -> Void in
            switch exportSession!.status {
            case .failed:
                print("%@",exportSession?.error as Any)
            case .cancelled:
                print("Export canceled")
            case .completed:
                //Video conversion finished
                let endDate = Foundation.Date()
                
                let time = endDate.timeIntervalSince(startDate)
                print(time)
                print("Successful!")
                print(exportSession?.outputURL as Any)
                let mediaPath = exportSession?.outputURL?.path as NSString?
                var videoData:NSData?
                do {
                    videoData = try NSData(contentsOf: ((exportSession?.outputURL!)!), options: .mappedIfSafe)
                }catch{
                    
                }
                if videoData != nil{
                    prefs.set(videoData, forKey: "video")
                }
                dispatchGroup.leave()
                
                //self.mediaPath = String(self.exportSession.outputURL!)
            // self.mediaPath = self.mediaPath.substringFromIndex(7)
            default:
                break
            }
            
        })
        
        
    }
    
    func deleteFile(_ filePath:URL) {
        guard FileManager.default.fileExists(atPath: filePath.path) else {
            return
        }
        
        do {
            try FileManager.default.removeItem(atPath: filePath.path)
        }catch{
            fatalError("Unable to delete file: \(error) : \(#function).")
        }
    }
}
