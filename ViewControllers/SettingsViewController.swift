//
//  SettingsViewController.swift
//  Learning_Tracker_IOS
//
//  Created by Maxime Richard on 23.02.18.
//  Copyright © 2018 Maxime Richard. All rights reserved.
//

import Foundation
import UIKit

class SettingsViewController: UIViewController {
    
    
    @IBOutlet weak var NameTextField: UITextField!
    @IBOutlet weak var IpAddressTextField: UITextField!
    
    @IBAction func SaveAndGoBackButtonPressed(_ sender: Any) {
        DbTableSettings.setNameAndMaster(name: NameTextField.text!, master: IpAddressTextField.text!)
        self.navigationController?.popViewController(animated: true)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        do {
            NameTextField.text = try DbTableSettings.retrieveName();
            IpAddressTextField.text = try DbTableSettings.retrieveMaster();
        } catch {
            
        }
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    
}
