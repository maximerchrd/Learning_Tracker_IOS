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
    static var navQuestionMultipleChoiceViewController: QuestionMultipleChoiceViewController?
    static var navQuestionShortAnswerViewController: QuestionShortAnswerViewController?
    
    @IBOutlet weak var InstructionsLabel: UILabel!
    
    public func showMultipleChoiceQuestion(question: QuestionMultipleChoice, isCorr: Bool, directCorrection: Int = 0) {
        // Safe Push VC
        if let newViewController = UIStoryboard(name: "Main", bundle: nil).instantiateViewController(withIdentifier: "QuestionMultipleChoiceViewController") as? QuestionMultipleChoiceViewController {
            if let navigator = navigationController {
                newViewController.questionMultipleChoice = question
                newViewController.wifiCommunication = wifiCommunication
                newViewController.isCorrection = isCorr
                newViewController.directCorrection = directCorrection
                navigator.pushViewController(newViewController, animated: true)
            }
        }
    }
    
    public func showShortAnswerQuestion(question: QuestionShortAnswer, isCorr: Bool, directCorrection: Int = 0) {
        // Safe Push VC
        if let newViewController = UIStoryboard(name: "Main", bundle: nil).instantiateViewController(withIdentifier: "QuestionShortAnswerViewController") as? QuestionShortAnswerViewController {
            if let navigator = navigationController {
                newViewController.questionShortAnswer = question
                newViewController.wifiCommunication = wifiCommunication
                newViewController.isCorrection = isCorr
                newViewController.directCorrection = directCorrection
                navigator.pushViewController(newViewController, animated: true)
            }
        }
    }
    
    public func showTest(questionIDs: [Int], directCorrection: Int = 0) {
        if questionIDs.count > 0 {
            if let newViewController = UIStoryboard(name: "Main", bundle: nil).instantiateViewController(withIdentifier: "testNavigation") as? SynchroneousQuestionsTestViewController {
                if let navigator = navigationController {
                    do {
                        for questionId in questionIDs {
                            let questionMC = try DbTableQuestionMultipleChoice.retrieveQuestionMultipleChoiceWithID(globalID: questionId)
                            if questionMC.Question.count < 1 || questionMC.Question == "none" {
                                let questionSA = try DbTableQuestionShortAnswer.retrieveQuestionShortAnswerWithID(globalID: questionId)
                                newViewController.questionsShortAnswer.append(questionSA)
                            } else {
                                newViewController.questionsMultipleChoice.append(questionMC)
                            }
                        }
                        newViewController.wifiCommunication = wifiCommunication!
                        newViewController.directCorrection = directCorrection
                        navigator.pushViewController(newViewController, animated: true)
                    } catch let error {
                        print(error)
                    }
                }
            }
            
        } else {
            print("Problem trying to display test: no question ID received")
        }
    }
    
    @objc func goBackToQuestionMultChoice() {
        if let navigator = navigationController {
            if ClassroomActivityViewController.navQuestionMultipleChoiceViewController != nil {
                navigator.pushViewController(ClassroomActivityViewController.navQuestionMultipleChoiceViewController!, animated: true)
            } else {
                print("Problem going back to question MC: View Controller is unexpectedly nil")
            }
        }
    }
    @objc func goBackToQuestionShortAnswer() {
        if let navigator = navigationController {
            if ClassroomActivityViewController.navQuestionShortAnswerViewController != nil {
                navigator.pushViewController(ClassroomActivityViewController.navQuestionShortAnswerViewController!, animated: true)
            } else {
                print("Problem going back to SHRTAQ: View Controller is unexpectedly nil")
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
    
    override func viewDidAppear(_ animated: Bool) {
        if ClassroomActivityViewController.navQuestionMultipleChoiceViewController != nil {
            navigationItem.rightBarButtonItem = UIBarButtonItem(title: "Go back to Question >", style: .plain, target: self, action: #selector(goBackToQuestionMultChoice))
        } else if ClassroomActivityViewController.navQuestionShortAnswerViewController != nil {
            navigationItem.rightBarButtonItem = UIBarButtonItem(title: "Go back to Question >", style: .plain, target: self, action: #selector(goBackToQuestionShortAnswer))
        } else {
            navigationItem.rightBarButtonItem = nil
        }
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    
}
