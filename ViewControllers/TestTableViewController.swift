//
//  TestTableViewController.swift
//  Learning_Tracker_IOS
//
//  Created by Maxime Richard on 05.05.18.
//  Copyright © 2018 Maxime Richard. All rights reserved.
//

import Foundation
import UIKit

class TestTableViewCell: UITableViewCell {
    @IBOutlet weak var IndexLabel: UILabel!
    @IBOutlet weak var QuestionLabel: UILabel!
}


class TestTableViewController: UITableViewController {
    var questionIDs = [String]()
    var questionsMultipleChoice = [String: QuestionMultipleChoice]()
    var questionsShortAnswer = [String: QuestionShortAnswer]()
    
    //store all the questions view controllers
    var questionMultipleChoiceViewControllers = [QuestionMultipleChoiceViewController]()
    var questionShortAnswerViewControllers = [QuestionShortAnswerViewController]()
    
    @IBOutlet var testTableView: UITableView!
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        ClassroomActivityViewController.navTestTableViewController = self
        AppDelegate.activeTest.buildIDsArraysFromMap()
        questionIDs = AppDelegate.activeTest.questionIDs
        reloadTable()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        ClassroomActivityViewController.navQuestionShortAnswerViewController = nil
        ClassroomActivityViewController.navQuestionMultipleChoiceViewController = nil
    }
    
    func reloadTable() {
        AppDelegate.activeTest.refreshActiveIds()
        do {
            for questionID in questionIDs {
                let questionMultipleChoice = try DbTableQuestionMultipleChoice.retrieveQuestionMultipleChoiceWithID(globalID: Int(questionID) ?? 0)
                if questionMultipleChoice.ID > 0 {
                    questionsMultipleChoice[questionID] = questionMultipleChoice
                } else {
                    let questionShortAnswer = try DbTableQuestionShortAnswer.retrieveQuestionShortAnswerWithID(globalID: Int(questionID) ?? 0)
                    questionsShortAnswer[questionID] = questionShortAnswer
                }
            }
        } catch let error {
            NSLog("%@", error.localizedDescription)
        }
        testTableView.reloadData()
    }
    
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if AppDelegate.activeTest.IDactive[questionIDs[indexPath.row]] ?? true {
            let questionMultipleChoice = questionsMultipleChoice[questionIDs[indexPath.row]]
            if questionMultipleChoice == nil {
                let questionShortAnswer = questionsShortAnswer[questionIDs[indexPath.row]]
                showTestShortAnswerQuestion(question: questionShortAnswer!, isCorr: false)
            } else {
                showTestMultipleChoiceQuestion(question: questionMultipleChoice!, isCorr: false)
            }
        }
    }
    
    fileprivate func showTestMultipleChoiceQuestion(question: QuestionMultipleChoice, isCorr: Bool, directCorrection: Int = 0) {
        //first check if the view controller was already pushed (question was seen before)
        var controllerIndex = -1
        for i in 0..<questionMultipleChoiceViewControllers.count {
            if questionMultipleChoiceViewControllers[i].questionMultipleChoice.ID == question.ID {
                controllerIndex = i
            }
        }
        // if the controller was stored, show it, else, load a new one
        if controllerIndex >= 0, let navigator = self.navigationController {
            navigator.pushViewController(questionMultipleChoiceViewControllers[controllerIndex], animated: true)
        } else if let newViewController = UIStoryboard(name: "Main", bundle: nil).instantiateViewController(withIdentifier: "QuestionMultipleChoiceViewController") as? QuestionMultipleChoiceViewController {
            if let navigator = self.navigationController {
                newViewController.questionMultipleChoice = question
                newViewController.isCorrection = isCorr
                newViewController.directCorrection = directCorrection
                navigator.pushViewController(newViewController, animated: true)
                questionMultipleChoiceViewControllers.append(newViewController)
            } else {
                NSLog("%@", "Error trying to show Multiple choice question: the view controller wasn't pushed on a navigation controller")
            }
        }
    }
    
    fileprivate func showTestShortAnswerQuestion(question: QuestionShortAnswer, isCorr: Bool, directCorrection: Int = 0) {
        //first check if the view controller was already pushed (question was seen before)
        var controllerIndex = -1
        for i in 0..<questionShortAnswerViewControllers.count {
            if questionShortAnswerViewControllers[i].questionShortAnswer.ID == question.ID {
                controllerIndex = i
            }
        }
        // if the controller was stored, show it, else, load a new one
        if controllerIndex >= 0, let navigator = self.navigationController {
            navigator.pushViewController(questionShortAnswerViewControllers[controllerIndex], animated: true)
        } else if let newViewController = UIStoryboard(name: "Main", bundle: nil).instantiateViewController(withIdentifier: "QuestionShortAnswerViewController") as? QuestionShortAnswerViewController {
            if let navigator = navigationController {
                newViewController.questionShortAnswer = question
                newViewController.isCorrection = isCorr
                newViewController.directCorrection = directCorrection
                navigator.pushViewController(newViewController, animated: true)
            } else {
                NSLog("%@", "Error trying to show Short answer question: the view controller wasn't pushed on a navigation controller")
            }
        }
    }
    
    
    override func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return questionIDs.count
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "QuestionCell", for: indexPath) as! TestTableViewCell
        
        cell.IndexLabel?.text = String(indexPath.row + 1)
        
        let questionMultipleChoice = questionsMultipleChoice[questionIDs[indexPath.row]]
        if questionMultipleChoice == nil {
            let questionShortAnswer = questionsShortAnswer[questionIDs[indexPath.row]]
            cell.QuestionLabel?.text = questionShortAnswer?.Question
        } else {
            cell.QuestionLabel?.text = questionMultipleChoice?.Question
        }
        
        //if the question isn't activated, color text in gray
        if !(AppDelegate.activeTest.IDactive[questionIDs[indexPath.row]] ?? false) {
            cell.QuestionLabel.textColor = UIColor.lightGray
        } else {
            cell.QuestionLabel.textColor = UIColor.black
        }
        
        return cell
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
}
