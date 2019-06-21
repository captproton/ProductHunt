//
//  DeepLinkManager.swift
//  ShareDemo
//
//  Created by Jitendra Singh on 17/06/19.
//  Copyright © 2019 Jitendra Singh. All rights reserved.
//

import UIKit

import Foundation
import UIKit

enum DeeplinkType {
    case image
    case url
    case video
    case text
}

let Deeplinker = DeepLinkManager()
class DeepLinkManager {
    
    fileprivate init() {}
    
    private var deeplinkType: DeeplinkType?
    
    @discardableResult
    func handleDeeplink(url: URL) -> Bool {
        deeplinkType = self.parseDeepLink(url)
        return deeplinkType != nil
    }
    func parseDeepLink(_ url: URL) -> DeeplinkType? {
        guard let host = url.host else {
            return nil
        }
        switch host {
        case "image":
            return DeeplinkType.image
        case "url":
            return DeeplinkType.url
        case "video":
            return DeeplinkType.video
        case "text":
            return DeeplinkType.text
        default:
            break
        }
        return nil
    }
    func proceedToDeeplink() {
        guard let deeplinkType = deeplinkType else {
            return
        }
        let appDelegate = UIApplication.shared.delegate as! AppDelegate
        guard let navigationController = appDelegate.window?.rootViewController as? UINavigationController  else{
            return
        }
        if let topVC = navigationController.topViewController as? ViewController {
            topVC.deeplinkType = deeplinkType
            return
        }
        let storyboard = UIStoryboard.init(name: "Main", bundle: nil)
        let vc = storyboard.instantiateViewController(withIdentifier: "ViewController") as! ViewController
        vc.deeplinkType = deeplinkType
        navigationController.pushViewController(vc, animated: true)
        self.deeplinkType = nil
    }
}
