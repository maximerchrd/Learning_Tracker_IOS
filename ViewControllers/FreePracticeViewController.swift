//
//  FreePracticeViewController.swift
//  Learning_Tracker_IOS
//
//  Created by Maxime Richard on 01.03.18.
//  Copyright © 2018 Maxime Richard. All rights reserved.
//

import Foundation
import UIKit


class FreePracticeViewController: UIViewController {
    
    var selectedSubject = NSLocalizedString("All subjects", comment: "All subjects in the database")
    var subjects = [String]()
    
    @IBOutlet weak var SubjectPicker: UIPickerView!
    @IBAction func StartPracticeButtonTouched(_ sender: Any) {
        var questionIds = [Int64]()
        var results = [Double]()
        do {
            questionIds = try DbTableRelationQuestionSubject.getQuestionsForSubject(subject: selectedSubject)
            for questionId in questionIds {
                let result = try DbTableIndividualQuestionForResult.getLatestEvaluationForQuestionID(questionID: questionId)
                results.append(result)
            }
        } catch let error {
            print(error)
        }
        var i = 0
        while i < results.count {
            if results[i] > 90 {
                questionIds.remove(at: i)
                results.remove(at: i)
                i = i - 1
            }
            i = i + 1
        }
        if questionIds.count > 0 {
            let newViewController = storyboard?.instantiateViewController(withIdentifier: "freePractice") as! FreePracticePageViewController
            do {
                for questionId in questionIds {
                    let questionMC = try DbTableQuestionMultipleChoice.retrieveQuestionMultipleChoiceWithID(globalID: questionId)
                    if questionMC.question.count < 1 || questionMC.question == "none" {
                        let questionSA = try DbTableQuestionShortAnswer.retrieveQuestionShortAnswerWithID(globalID: questionId)
                        newViewController.questionsShortAnswer.append(questionSA)
                    } else {
                        newViewController.questionsMultipleChoice.append(questionMC)
                    }
                }
            } catch let error {
                print(error)
            }
            navigationController?.pushViewController(newViewController, animated: true)
        } else {
            let alert = UIAlertController(title: NSLocalizedString("You are quite good! You don\'t have any more questions needing practice.", comment: "message when all questions on the device have been answered correctly"), message: "", preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "OK", style: .cancel, handler: nil))
            self.present(alert, animated: true)
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        SubjectPicker.delegate = self
        do {
            subjects = try DbTableSubject.getAllSubjects()
            subjects.insert(NSLocalizedString("All subjects", comment: "All subjects in the database"), at: 0)
        } catch let error {
            print(error)
        }
        let index = subjects.index(of: "")
        if index != nil {
            subjects.remove(at: index!)
        }
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    
}

extension FreePracticeViewController: UIPickerViewDelegate, UIPickerViewDataSource {
    func numberOfComponents(in pickerView: UIPickerView) -> Int {
        return 1
    }
    
    
    func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        return subjects.count
    }
    
    
    func pickerView(_ pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String? {
        return subjects[row]
    }
    
    
    func pickerView(_ pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int) {
        
        selectedSubject = subjects[row]
    }
    
    func pickerView(_ pickerView: UIPickerView, viewForRow row: Int, forComponent component: Int, reusing view: UIView?) -> UIView {
        var label: UILabel
        
        if let view = view as? UILabel {
            label = view
        } else {
            label = UILabel()
        }
        
        label.textAlignment = .center
        label.font = UIFont(name: "Menlo-Regular", size: 17)
        
        label.text = subjects[row]
        
        return label
    }
}
