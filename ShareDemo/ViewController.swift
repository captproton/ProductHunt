//
//  ViewController.swift
//  ShareDemo
//
//  Created by Jitendra Singh on 13/06/19.
//  Copyright © 2019 Jitendra Singh. All rights reserved.
//

import UIKit
import AVFoundation
import AVKit

class ViewController: UIViewController {
    @IBOutlet weak var txtview: UITextView!
    @IBOutlet weak var imgv: UIImageView!
    var lcoalFilePath = ""
    let playerViewController = AVPlayerViewController()
    var deeplinkType: DeeplinkType!{
        didSet{
            self.manageViewsAccoringToDeepLinktype()
        }
    }
    override func viewDidLoad() {
        super.viewDidLoad()
    }
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
    }
    func manageViewsAccoringToDeepLinktype() {
        let userDefaults = UserDefaults(suiteName: "group.test.ProductHuntExtensiontest.ShareExtension")
        switch self.deeplinkType {
        case .image?:
            if let imgData = userDefaults?.object(forKey: "image") as? Data{
                self.view.bringSubviewToFront(self.imgv)
                self.imgv.image = UIImage.init(data: imgData)
            }
        case .text?:
            if let textData = userDefaults?.object(forKey: "text") as? Data{
                self.view.bringSubviewToFront(self.txtview)
                self.txtview.text = String(data: textData, encoding: String.Encoding.utf8) as String?
            }
        case .url?:
            if let urlData = userDefaults?.object(forKey: "url") as? Data{
                self.imgv.removeFromSuperview()
                self.txtview.text = String(data: urlData, encoding: String.Encoding.utf8) as String?
            }
        case .video?:
            if let videoData = userDefaults?.object(forKey: "video") as? Data{
                do {
                    try AVAudioSession.sharedInstance().setCategory(AVAudioSession.Category.playback)
                } catch {
                }
                saveVideoDataToLocal(videoFromExtensionData: videoData as! Data)
            }
        default:
            break
        }
    }
    func play(videoFromExtensionData:Data, uniqueID:String){
        
        let paths = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true)
        let documentsDirectory = paths[0]
        
        let videoDataPath = documentsDirectory + "/" + uniqueID + "TEMPVIDEO.MOV"
        
        let filePathURL = URL(fileURLWithPath: videoDataPath)
        
        
        let player = AVPlayer(url: filePathURL)
        
        playerViewController.player = player
        playerViewController.delegate =  self
        self.present(playerViewController, animated: true) {
            player.play()
        }
    }
    func saveVideoDataToLocal(videoFromExtensionData:Data) {
        var uniqueVideoID = ""
        var uniqueID = ""
        
        //Add this to ViewDidLoad
        uniqueID = NSUUID().uuidString
        let myVideoVarData = videoFromExtensionData
        //Now writeing the data to the temp diroctory.
        let tempPath = NSSearchPathForDirectoriesInDomains(FileManager.SearchPathDirectory.documentDirectory, FileManager.SearchPathDomainMask.userDomainMask, true)
        let tempDocumentsDirectory: AnyObject = tempPath[0] as AnyObject
        uniqueVideoID = uniqueID  + "TEMPVIDEO.MOV"
        self.lcoalFilePath = uniqueVideoID
        let tempDataPath = tempDocumentsDirectory.appendingPathComponent(uniqueVideoID) as String
        try? myVideoVarData.write(to: URL(fileURLWithPath: tempDataPath), options: [])
        
        //Getting the time value of the movie.
        let fileURL = URL(fileURLWithPath: tempDataPath)
        let asset = AVAsset(url: fileURL)
        let duration : CMTime = asset.duration
        let assetImageGenerate = AVAssetImageGenerator(asset: asset)
        assetImageGenerate.appliesPreferredTrackTransform = true
        let time = CMTimeMake(value: asset.duration.value / 3, timescale: asset.duration.timescale)
        
        //This adds the thumbnail to the imageview.
        if let videoImage = try? assetImageGenerate.copyCGImage(at: time, actualTime: nil) {
            //            videoThumbnailOutlet.image = UIImage(cgImage: videoImage)
        }
        play(videoFromExtensionData: videoFromExtensionData, uniqueID: uniqueID)
    }
    func removeImageLocalPath(localPathName:String) {
        let filemanager = FileManager.default
        let documentsPath = NSSearchPathForDirectoriesInDomains(.documentDirectory,.userDomainMask,true)[0] as NSString
        let destinationPath = documentsPath.appendingPathComponent(localPathName)
        do {
            try filemanager.removeItem(atPath: destinationPath)
            print("Local path removed successfully")
        } catch let error as NSError {
            print("------Error",error.debugDescription)
        }
    }
    func clearAllFilesFromTempDirectory(){
        let fileManager = FileManager.default
        do {
            let strTempPath = getDocumentsDirectory().path
            let filePaths = try fileManager.contentsOfDirectory(atPath: strTempPath)
            for filePath in filePaths {
                try fileManager.removeItem(atPath: strTempPath + "/" + filePath)
            }
        } catch {
            print("Could not clear temp folder: \(error)")
        }
    }
    func getDocumentsDirectory() -> URL {
        //        let paths = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)
        //        return paths[0]
        
        let fileManager = FileManager.default
        if let tDocumentDirectory = fileManager.urls(for: .documentDirectory, in: .userDomainMask).first {
            let filePath =  tDocumentDirectory.appendingPathComponent("MY_TEMP")
            if !fileManager.fileExists(atPath: filePath.path) {
                do {
                    try fileManager.createDirectory(atPath: filePath.path, withIntermediateDirectories: true, attributes: nil)
                } catch {
                    NSLog("Couldn't create folder in document directory")
                    NSLog("==> Document directory is: \(filePath)")
                    return fileManager.urls(for: .documentDirectory, in: .userDomainMask).first!
                }
            }
            
            NSLog("==> Document directory is: \(filePath)")
            return filePath
        }
        return fileManager.urls(for: .documentDirectory, in: .userDomainMask).first!
    }
}
//Video Work
extension ViewController:AVPlayerViewControllerDelegate{
    
}
