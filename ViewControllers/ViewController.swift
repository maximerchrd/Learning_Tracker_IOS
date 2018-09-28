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
        //code for testing
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
    
    override func shouldPerformSegue(withIdentifier identifier: String, sender: Any?) -> Bool {
        if identifier == "showClassroomActivity" {
            do {
            let name = try DbTableSettings.retrieveName()
                if name == NSLocalizedString("No name", comment: "No name") {
                    let alert = UIAlertController(title: "", message: NSLocalizedString("Please change the user name in \"Settings\" before starting the classroom activity", comment: "change username"), preferredStyle: .alert)
                    alert.addAction(UIAlertAction(title: "OK", style: .cancel, handler: nil))
                    self.present(alert, animated: true)
                    return false
                } else {
                    return true
                }
            } catch let error {
                print(error)
                return true
            }
        } else {
            return true
        }
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }


}

