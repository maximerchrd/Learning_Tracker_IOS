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
    var directCorrection = 0
    
    //store all the questions view controllers
    var questionMultipleChoiceViewControllers = [QuestionMultipleChoiceViewController]()
    var questionShortAnswerViewControllers = [QuestionShortAnswerViewController]()
    
    @IBOutlet var testTableView: UITableView!
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        ClassroomActivityViewController.navTestTableViewController = self
        AppDelegate.activeTest.buildIDsArraysFromMap()
        questionIDs = AppDelegate.activeTest.questionIDs
        
        //start the timer
        AppDelegate.activeTest.startTime = Date.timeIntervalSinceReferenceDate
        reloadTable()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        //update current test if exists
        if AppDelegate.activeTest.calculateScoreAndCheckIfOver() {
            //test over
            if AppDelegate.activeTest.score >= Double(AppDelegate.activeTest.medalsInstructions[2].1) ?? 0.0 && AppDelegate.activeTest.finishTime <= Double(AppDelegate.activeTest.medalsInstructions[2].0) ?? 0.0 {
                //gold medal
                displayMedal(medalName: "gold-medal.png", message: "You got the GOLD MEDAL")
            } else if AppDelegate.activeTest.score >= Double(AppDelegate.activeTest.medalsInstructions[1].1) ?? 0.0 && AppDelegate.activeTest.finishTime <= Double(AppDelegate.activeTest.medalsInstructions[1].0) ?? 0.0 {
                //silver medal
                displayMedal(medalName: "silver-medal.png", message: "You got the SILVER MEDAL")
            } else if AppDelegate.activeTest.score >= Double(AppDelegate.activeTest.medalsInstructions[0].1) ?? 0.0 && AppDelegate.activeTest.finishTime <= Double(AppDelegate.activeTest.medalsInstructions[0].0) ?? 0.0 {
                //bronze medal
                displayMedal(medalName: "bronze-medal.png", message: "You got the BRONZE MEDAL")
            }
        }
    }
    
    func displayMedal(medalName: String, message: String) {
        let alert = UIAlertController(title: NSLocalizedString("You are a Champ!", comment: ""), message: message + "\n\n\n\n\n\n\n\n\n", preferredStyle: .alert)
        let medalImage = UIImage(named: medalName)
        let imageView = UIImageView(frame: CGRect(origin: CGPoint(x:self.view.frame.width * 0.3, y:self.view.frame.height * 0.2), size: CGSize(width: (medalImage?.size.width ?? 0.0) / (medalImage?.size.height ?? 1.0) * 100, height: 100)) )
        imageView.image = medalImage
        alert.view.addSubview(imageView)
    
        alert.addAction(UIAlertAction(title: "OK", style: .cancel, handler: nil))
        self.present(alert, animated: true, completion: nil)
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        ClassroomActivityViewController.navQuestionShortAnswerViewController = nil
        ClassroomActivityViewController.navQuestionMultipleChoiceViewController = nil
    }
    
    func reloadTable() {
        AppDelegate.activeTest.refreshActiveIds()
        do {
            for questionID in questionIDs {
                let questionMultipleChoice = try DbTableQuestionMultipleChoice.retrieveQuestionMultipleChoiceWithID(globalID: Int64(questionID) ?? 0)
                if questionMultipleChoice.ID > 0 {
                    questionsMultipleChoice[questionID] = questionMultipleChoice
                } else {
                    let questionShortAnswer = try DbTableQuestionShortAnswer.retrieveQuestionShortAnswerWithID(globalID: Int64(questionID) ?? 0)
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
                showTestShortAnswerQuestion(question: questionShortAnswer!, isCorr: false, directCorrection: directCorrection)
            } else {
                showTestMultipleChoiceQuestion(question: questionMultipleChoice!, isCorr: false, directCorrection: directCorrection)
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
        } else if AppDelegate.activeTest.answeredIds.contains(questionIDs[indexPath.row]) {
            let attributeString: NSMutableAttributedString =  NSMutableAttributedString(string: cell.QuestionLabel.text ?? "")
            attributeString.addAttribute(NSAttributedStringKey.strikethroughStyle, value: 2, range: NSMakeRange(0, attributeString.length))
            cell.QuestionLabel.attributedText = attributeString
        } else {
            cell.QuestionLabel.textColor = UIColor.black
        }
        
        return cell
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
}
