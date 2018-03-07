//
//  ViewController.swift
//  Learning_Tracker_IOS
//
//  Created by Maxime Richard on 22.02.18.
//  Copyright © 2018 Maxime Richard. All rights reserved.
//

import UIKit

class ViewController: UIViewController {

    @IBOutlet weak var welcomeMessageLabel: UILabel!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
    }
    
    override func viewDidAppear(_ animated: Bool) {
        var name = ""
        do {
            name = try DbTableSettings.retrieveName()
        } catch let error {
            print (error)
        }
        var welcomeMessage = NSLocalizedString("Hello ", comment: "first part of welcome message")
        welcomeMessage += name.components(separatedBy: " ")[0]
        welcomeMessage += NSLocalizedString(". Welcome to Learning Tracker. Check in parameters that you have the right ip address before starting a classroom activity.", comment: "second part of welcome message")
        welcomeMessageLabel.text = welcomeMessage
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }


}

