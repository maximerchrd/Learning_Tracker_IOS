//
//  ClassroomActivityViewController.swift
//  Learning_Tracker_IOS
//
//  Created by Maxime Richard on 24.02.18.
//  Copyright © 2018 Maxime Richard. All rights reserved.
//

import Foundation
import UIKit

class ClassroomActivityViewController: UIViewController {
    
    @IBOutlet weak var InstructionsLabel: UILabel!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        let wifiCommunication = WifiCommunication()
        if (wifiCommunication.connectToServer()) {
            InstructionsLabel.text = "AND WAIT FOR NEXT QUESTION"
        } else {
            InstructionsLabel.text = "AND RESTART THE CLASSROOM ACTIVITY (but before, check that you have the right IP address in settings"
        }
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    
}
