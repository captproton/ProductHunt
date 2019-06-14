//
//  ShareViewController.swift
//  SahreDemoExtension
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
    }
    func shareURL(itemProvider:NSItemProvider,dispatchGroup:DispatchGroup, prefs:UserDefaults) {
        itemProvider.loadItem(forTypeIdentifier: kUTTypeURL as String, options: nil) { data, error in
            if error == nil {
                var urlString = ""
                if itemProvider.isURL {
                    itemProvider.loadItem(forTypeIdentifier: "public.url", options: nil, completionHandler: { (results, error) in
                        let url = results as! URL?
                        urlString = url!.absoluteString
                        prefs.set(urlString, forKey: "url")
                    })
                }
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
            }else{
                print("bad share data")
            }
            dispatchGroup.leave()
        }
    }
    func shareText(itemProvider:NSItemProvider,dispatchGroup:DispatchGroup, prefs:UserDefaults ) {
        itemProvider.loadItem(forTypeIdentifier: self.contentTypeText, options: nil, completionHandler: { (results, error) in
            let text = results as! String
            prefs.set(text, forKey: "text")
            _ = self.isContentValid()
            dispatchGroup.leave()
        })
    }
    func shareVideo(itemProvider:NSItemProvider,dispatchGroup:DispatchGroup, prefs:UserDefaults ) {
        itemProvider.loadItem(forTypeIdentifier: "com.apple.quicktime-movie", options: [:]) { (data, error) in
//            let opts = [AVURLAssetPreferPreciseDurationAndTimingKey : NSNumber(value: false)]
//            
//            let urlAsset = AVURLAsset(url: data as! URL, options: opts as? [String : Any])
//            let second = Int(urlAsset.duration.value / urlAsset.duration.timescale)
//            
            
            
            
            dispatchGroup.leave()
        }
    }
    func dummy(itemProvider:NSItemProvider)  {
        itemProvider.loadItem(forTypeIdentifier: kUTTypeData as String, options: nil) { data, error in
            if error == nil {
                //  Note: "data" may be another type (e.g. Data or UIImage). Casting to URL may fail. Better use switch-statement for other types.
                //  "screenshot-tool" from iOS11 will give you an UIImage here
                guard let prefs = UserDefaults(suiteName: "group.test.DemoShareExtensiontest.ShareExtension") else{
                    return
                }
                
                
                let url = data as! URL
                if let imageData = try? Data(contentsOf: url) {
                    if let prefs = UserDefaults(suiteName: "group.test.DemoShareExtensiontest.ShareExtension") {
                        prefs.removeObject(forKey: "color")
                        prefs.set(imageData, forKey: "color")
                    }
                }
                let path = "\(self.docPath)/\(url.pathComponents.last ?? "")"
                print(">>> sharepath: \(String(describing: url.path))")
                
                try? FileManager.default.copyItem(at: url, to: URL(fileURLWithPath: path))
                let myImage: UIImage?
                var urlString = ""
                var textString = ""
                if itemProvider.isImage{ //Image
                    switch data {
                    case let image as UIImage:
                        myImage = image
                    case let data as Data:
                        myImage = UIImage(data: data)
                    case let url as URL:
                        myImage = UIImage(contentsOfFile: url.path)
                    default:
                        //There may be other cases...
                        print("Unexpected data:", type(of: data))
                        myImage = nil
                    }
                    if myImage != nil{
                        prefs.removeObject(forKey: "image")
                        prefs.set(myImage, forKey: "image")
                    }
                }
                if itemProvider.isVideo {//Video
                    
                }
                if itemProvider.isURL {
                    itemProvider.loadItem(forTypeIdentifier: self.contentTypeURL, options: nil, completionHandler: { (results, error) in
                        let url = results as! URL?
                        urlString = url!.absoluteString
                        prefs.removeObject(forKey: "url")
                        prefs.set(urlString, forKey: "url")
                    })
                }
                if itemProvider.isText {
                    itemProvider.loadItem(forTypeIdentifier: self.contentTypeText, options: nil, completionHandler: { (results, error) in
                        let text = results as! String
                        textString = text
                        prefs.removeObject(forKey: "text")
                        prefs.set(textString, forKey: "text")
                        _ = self.isContentValid()
                    })
                }
            } else {
                NSLog("\(String(describing: error))")
            }
//            group.leave()
        }

    }
}
