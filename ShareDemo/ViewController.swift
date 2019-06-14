//
//  ViewController.swift
//  ShareDemo
//
//  Created by Jitendra Singh on 13/06/19.
//  Copyright © 2019 Jitendra Singh. All rights reserved.
//

import UIKit

class ViewController: UIViewController {

    var imageToShow:UIImage?
    @IBOutlet weak var imgv: UIImageView!
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
    }
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        if let img = imageToShow {
            imgv.image = img
        }
        
    }

}

