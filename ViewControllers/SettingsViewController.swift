//
//  SettingsViewController.swift
//  Learning_Tracker_IOS
//
//  Created by Maxime Richard on 23.02.18.
//  Copyright © 2018 Maxime Richard. All rights reserved.
//

import Foundation
import UIKit
import MessageUI

class SettingsViewController: UIViewController, MFMailComposeViewControllerDelegate, UITextFieldDelegate {
    
    var logs = [String]()
    
    @IBOutlet weak var NameTextField: UITextField!
    @IBOutlet weak var IpAddressTextField: UITextField!
    @IBOutlet weak var automaticConnectionSwitch: UISwitch!
    

    @IBAction func automaticConnectionAction(_ sender: Any) {
        if automaticConnectionSwitch.isOn {
            DbTableSettings.setAutomaticConnection(automaticConnection: 1)
            IpAddressTextField.isEnabled = false
            IpAddressTextField.textColor = UIColor.gray
        } else {
            DbTableSettings.setAutomaticConnection(automaticConnection: 0)
            IpAddressTextField.isEnabled = true
            IpAddressTextField.textColor = UIColor.black
        }
    }
    
    func deleteImages() -> Bool {
        guard let directory = try? FileManager.default.url(for: .documentDirectory, in: .userDomainMask, appropriateFor: nil, create: false) as NSURL else {
            let error = "error trying to delete images: problem with directory"
            print(error)
            DbTableLogs.insertLog(log: error)
            return false
        }
        let fileManager = FileManager.default
        let fileUrls = fileManager.enumerator(at: directory as URL, includingPropertiesForKeys: nil)
        while let fileUrl = fileUrls?.nextObject() {
            do {
                try fileManager.removeItem(at: fileUrl as! URL)
            } catch {
                print(error)
                return false
            }
        }
        return true
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()

        do {
            NameTextField.text = try DbTableSettings.retrieveName()
            IpAddressTextField.text = try DbTableSettings.retrieveMaster()
            let automaticConnection = try DbTableSettings.retrieveAutomaticConnection()
            if automaticConnection == 1 {
                IpAddressTextField.isEnabled = false
                IpAddressTextField.textColor = UIColor.gray
            } else {
                automaticConnectionSwitch.isOn = false
            }
            self.NameTextField.delegate = self;
            self.IpAddressTextField.delegate = self;
        } catch let error {
            print(error)
        }
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        DbTableSettings.setNameAndMaster(name: NameTextField.text!, master: IpAddressTextField.text!)
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    //function enabling dismissing of keyboard when return pressed
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        self.view.endEditing(true)
        return false
    }
}
