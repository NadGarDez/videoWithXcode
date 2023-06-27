//
//  ViewController.swift
//  custom-video
//
//  Created by Nad on 21/6/23.
//

import UIKit

class ViewController: UIViewController {
    
    var video:Video?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        video = Video(frame: CGRect(x: 0, y: 0, width:UIScreen.main.bounds.width, height: UIScreen.main.bounds.height))
        self.view.addSubview(video!)
        // Do any additional setup after loading the view.
    }
    
    override func viewDidAppear(_ animated: Bool) {
        video?.play()
    }

}

