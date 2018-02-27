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
    
    public func showMultipleChoiceQuestion(question: QuestionMultipleChoice) {
        let storyBoard: UIStoryboard = UIStoryboard(name: "Main", bundle: nil)
        let newViewController = storyBoard.instantiateViewController(withIdentifier: "QuestionMultipleChoiceViewController") as! QuestionMultipleChoiceViewController
        newViewController.questionMultipleChoice = question
        self.present(newViewController, animated: true, completion: nil)
    }
    
    public func showShortAnswerQuestion(question: QuestionShortAnswer) {
        let storyBoard: UIStoryboard = UIStoryboard(name: "Main", bundle: nil)
        let newViewController = storyBoard.instantiateViewController(withIdentifier: "QuestionShortAnswerViewController") as! QuestionShortAnswerViewController
        newViewController.questionShortAnswer = question
        self.present(newViewController, animated: true, completion: nil)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        //showMultipleChoiceQuestion(strin: "from view did load")
        let wifiCommunication = WifiCommunication(classroomActivityViewControllerArg: self)
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
