//
//  ViewController.swift
//  Learning_Tracker_IOS
//
//  Created by Maxime Richard on 22.02.18.
//  Copyright © 2018 Maxime Richard. All rights reserved.
//

import UIKit

class ViewController: UIViewController {

    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
    }
    
    override func viewDidAppear(_ animated: Bool) {
        if AppDelegate.testConnection != 0 {
            DispatchQueue.global(qos: .utility).async {
                Thread.sleep(forTimeInterval: 1)
                if let navigator = self.navigationController {
                    DispatchQueue.main.async {
                        DbTableSettings.setNameAndMaster(name: String(AppDelegate.testConnection), master: "kill the masters")
                        if let newViewController = UIStoryboard(name: "Main", bundle: nil).instantiateViewController(withIdentifier: "classroomActivity") as? ClassroomActivityViewController {
                            if let navigator = self.navigationController {
                                navigator.pushViewController(newViewController, animated: true)
                                AppDelegate.testConnection = AppDelegate.testConnection + 1
                            }
                        }
                    }
                }
            }
        }
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }


}

