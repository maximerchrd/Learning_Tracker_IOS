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
    
    var wifiCommunication: WifiCommunication?
    
    @IBOutlet weak var InstructionsLabel: UILabel!
    
    public func showMultipleChoiceQuestion(question: QuestionMultipleChoice) {
        // Safe Push VC
        if let newViewController = UIStoryboard(name: "Main", bundle: nil).instantiateViewController(withIdentifier: "QuestionMultipleChoiceViewController") as? QuestionMultipleChoiceViewController {
            if let navigator = navigationController {
                newViewController.questionMultipleChoice = question
                newViewController.wifiCommunication = wifiCommunication
                navigator.pushViewController(newViewController, animated: true)
            }
        }
    }
    
    public func showShortAnswerQuestion(question: QuestionShortAnswer) {
        // Safe Push VC
        if let newViewController = UIStoryboard(name: "Main", bundle: nil).instantiateViewController(withIdentifier: "QuestionShortAnswerViewController") as? QuestionShortAnswerViewController {
            if let navigator = navigationController {
                newViewController.questionShortAnswer = question
                newViewController.wifiCommunication = wifiCommunication
                navigator.pushViewController(newViewController, animated: true)
            }
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        //showMultipleChoiceQuestion(strin: "from view did load")
        wifiCommunication = WifiCommunication(classroomActivityViewControllerArg: self)
        if (wifiCommunication!.connectToServer()) {
            InstructionsLabel.text = NSLocalizedString("AND WAIT FOR NEXT QUESTION", comment: "instruction after the KEEP CALM")
        } else {
            InstructionsLabel.text = NSLocalizedString("AND RESTART THE CLASSROOM ACTIVITY (but before, check that you have the right IP address in settings)", comment: "instruction after the KEEP CALM if connection failed")
        }
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    
}
