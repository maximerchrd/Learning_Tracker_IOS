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
    
    @IBAction func SaveAndGoBackButtonPressed(_ sender: Any) {
        DbTableSettings.setNameAndMaster(name: NameTextField.text!, master: IpAddressTextField.text!)
        self.navigationController?.popViewController(animated: true)
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
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    @IBAction func sendMail(_ sender: Any) {
        let mailComposeViewController = configureMailController()
        if MFMailComposeViewController.canSendMail() {
            self.present(mailComposeViewController, animated: true, completion: nil)
        } else {
            showMailError()
        }
    }
    
    func configureMailController() -> MFMailComposeViewController {
        let mailComposerVC = MFMailComposeViewController()
        mailComposerVC.mailComposeDelegate = self
        
        mailComposerVC.setToRecipients(["learning.tracker.dev@gmail.com"])
        mailComposerVC.setSubject(modelIdentifier())
        
        do {
            logs = try DbTableLogs.getNotSentLogs();
        } catch let error {
            print(error)
        }
        var fullLog = ""
        for log in logs {
            fullLog = fullLog + log + "\n"
        }
        mailComposerVC.setMessageBody(fullLog, isHTML: false)
        
        return mailComposerVC
    }
    
    func modelIdentifier() -> String {
        if let simulatorModelIdentifier = ProcessInfo().environment["SIMULATOR_MODEL_IDENTIFIER"] { return simulatorModelIdentifier }
        var sysinfo = utsname()
        uname(&sysinfo) // ignore return value
        return String(bytes: Data(bytes: &sysinfo.machine, count: Int(_SYS_NAMELEN)), encoding: .ascii)!.trimmingCharacters(in: .controlCharacters)
    }
    
    func showMailError() {
        let sendMailErrorAlert = UIAlertController(title: "Could not send email", message: "Your device could not send email", preferredStyle: .alert)
        let dismiss = UIAlertAction(title: "Ok", style: .default, handler: nil)
        sendMailErrorAlert.addAction(dismiss)
        self.present(sendMailErrorAlert, animated: true, completion: nil)
    }
    
    func mailComposeController(_ controller: MFMailComposeViewController, didFinishWith result: MFMailComposeResult, error: Error?) {
        controller.dismiss(animated: true, completion: nil)
        if result.rawValue == MFMailComposeResult.sent.rawValue {
            do {
                try DbTableLogs.deleteLog()
            } catch let error {
                print(error)
            }
        }
    }
    
    //function enabling dismissing of keyboard when return pressed
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        self.view.endEditing(true)
        return false
    }
}
