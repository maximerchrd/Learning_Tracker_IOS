//
//  ResultsTableController.swift
//  Learning_Tracker_IOS
//
//  Created by Maxime Richard on 12.04.18.
//  Copyright © 2018 Maxime Richard. All rights reserved.
//

import Foundation
import UIKit

class ResultsTableViewCell: UITableViewCell {
    @IBOutlet weak var QuestionLabel: UILabel!
    @IBOutlet weak var AnswerLabel: UILabel!
    @IBOutlet weak var EvaluationLabel: UILabel!
    @IBOutlet weak var medalImage: UIImageView!
}


class ResultsTableController: UITableViewController {
    var results = [[String]]()
    var questions = [String]()
    var answers = [String]()
    var evaluations = [Double]()
    var dates = [String]()
    var questionType = [String]()
    var rightAnswerOptions = [[String]]()
    var wrongAnswerOptions = [[String]]()
    var imagePaths = [String]()
    @IBOutlet var resultsTableView: UITableView!
    
    //array for filtering according to subject
    var selectedSubject = NSLocalizedString("All subjects", comment: "All subjects in the database")
    var subjects = [String]()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        reloadTable(subject: "All")
        
        //load the subjects and setup the corresponding picker view
        do {
            subjects = try DbTableSubject.getAllSubjects()
        } catch let error {
            print(error)
        }
        subjects.insert(NSLocalizedString("All subjects", comment: "All subjects in the database"), at: 0)
        let indexOfEmpty = subjects.index(of: "")
        if indexOfEmpty != nil {
            subjects.remove(at: subjects.index(of: "")!)
        }
        
        let uiButtonSubject = UIButton(frame: CGRect(x: 0, y: 0, width: 250, height: 30))
        var titleString = NSLocalizedString("Subject: ", comment: "on button to chose subject") + selectedSubject
        if titleString.count < 28 {
            for _ in titleString.count..<28 {
                titleString.append(" ")
            }
        }
        uiButtonSubject.setTitle(titleString, for: .normal)
        uiButtonSubject.backgroundColor = UIColor.gray
        uiButtonSubject.tintColor = UIColor.blue
        uiButtonSubject.layer.cornerRadius = 4.0
        uiButtonSubject.layer.masksToBounds = true
        uiButtonSubject.addTarget(self, action: #selector(addTapped), for: .touchUpInside)
        let subjectsButton = UIBarButtonItem(customView: uiButtonSubject)
        
        navigationItem.rightBarButtonItems = [subjectsButton]
    }
    
    func reloadTable(subject: String) {
        do {
            if subject == NSLocalizedString("All subjects", comment: "All subjects in the database") {
                results = try DbTableIndividualQuestionForResult.getResultsForSubject(subject: "All")
            } else {
                results = try DbTableIndividualQuestionForResult.getResultsForSubject(subject: subject)
            }
        } catch let error {
            print(error)
        }
        
        results.reverse()
        
        questions.removeAll()
        answers.removeAll()
        evaluations.removeAll()
        dates.removeAll()
        questionType.removeAll()
        rightAnswerOptions.removeAll()
        wrongAnswerOptions.removeAll()
        imagePaths.removeAll()
        for result in results {
            questions.append(result[0])
            answers.append(result[1])
            evaluations.append(Double(result[2]) ?? -1.0)
            dates.append(result[3])
            imagePaths.append(result[4])
            questionType.append(result[5])
            rightAnswerOptions.append([String]())
            wrongAnswerOptions.append([String]())
            if result[5] == "SHRTAQ" {
                if result.count > 5 {
                    for i in 6..<result.count {
                        rightAnswerOptions[rightAnswerOptions.count - 1].append(result[i])
                    }
                }
            } else if result[5] == "MCQ" {
                if result.count > 6 {
                    for i in 7..<(7 + (Int(result[6]))!) {
                        rightAnswerOptions[rightAnswerOptions.count - 1].append(result[i])
                    }
                    for i in (7 + (Int(result[6]))!)..<result.count {
                        wrongAnswerOptions[wrongAnswerOptions.count - 1].append(result[i])
                    }
                }
            }
        }
        resultsTableView.reloadData()
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if (indexPath.section == 1) {
            if let newViewController = UIStoryboard(name: "Main", bundle: nil).instantiateViewController(withIdentifier: "ResultFullViewController") as? ResultFullViewController {
                if let navigator = self.navigationController {
                    if questionType[indexPath.row] != "3" {
                        newViewController.questionText = questions[indexPath.row]
                        newViewController.studentAnswerText = answers[indexPath.row]
                        newViewController.evaluation = String(evaluations[indexPath.row])
                        newViewController.date = dates[indexPath.row]
                        newViewController.rightAnswers = rightAnswerOptions[indexPath.row]
                        newViewController.wrongAnswers = wrongAnswerOptions[indexPath.row]
                        newViewController.imagePath = imagePaths[indexPath.row]
                        navigator.pushViewController(newViewController, animated: true)
                    }
                } else {
                    NSLog("%@", "Error trying to show Result Full View: the view controller wasn't pushed on a navigation controller")
                }
            }
        }
    }
    
    override func numberOfSections(in tableView: UITableView) -> Int {
        return 2
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if (section == 1) {
            return evaluations.count
        } else {
            return 1
        }
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "ResultCell", for: indexPath) as! ResultsTableViewCell
        
        if (indexPath.section == 1) {
            if questionType[indexPath.row] == "3" {
                cell.QuestionLabel?.text = questions[indexPath.row]
                cell.EvaluationLabel?.text = String(evaluations[indexPath.row])
                cell.medalImage.image = UIImage(named: imagePaths[indexPath.row])
            } else {
                let question = questions[indexPath.row]
                cell.QuestionLabel?.text = question
                let answer = answers[indexPath.row]
                cell.AnswerLabel?.text = answer
                let evaluation = evaluations[indexPath.row]
                cell.EvaluationLabel?.text = String(evaluation)
                cell.medalImage.image = nil
            }
        } else {
            cell.QuestionLabel?.text = "Question"
            cell.QuestionLabel?.font = UIFont.boldSystemFont(ofSize: 16.0)
            cell.AnswerLabel?.text = "Your Answer"
            cell.AnswerLabel?.font = UIFont.boldSystemFont(ofSize: 16.0)
            cell.EvaluationLabel?.text = "Evaluation"
            cell.EvaluationLabel?.font = UIFont.boldSystemFont(ofSize: 16.0)
        }
        return cell
    }
    
    @objc func addTapped() {
        let alertView = UIAlertController(
            title: NSLocalizedString("Choose a subject", comment: "in the item picker for the evaluation charts"),
            message: "\n\n\n\n\n\n\n\n\n",
            preferredStyle: .alert)
        
        let pickerView = UIPickerView(frame:
            CGRect(x: 0, y: 50, width: 260, height: 162))
        pickerView.dataSource = self as UIPickerViewDataSource
        pickerView.delegate = self as UIPickerViewDelegate
        
        // comment this line to use white color
        pickerView.backgroundColor = UIColor.lightGray.withAlphaComponent(0.2)
        pickerView.selectRow(subjects.index(of: selectedSubject) ?? 0, inComponent: 0, animated: false)
        
        alertView.view.addSubview(pickerView)
        
        let action = UIAlertAction(title: "OK", style: UIAlertActionStyle.default, handler: {(alert: UIAlertAction!) in self.OKButtonPressed()})
        
        alertView.addAction(action)
        present(alertView, animated: true)
    }
    
    func OKButtonPressed() {
        reloadTable(subject: selectedSubject)
        (navigationItem.rightBarButtonItems![0].customView as! UIButton).titleLabel?.text = NSLocalizedString("Subject:", comment: "on button to chose subject") + selectedSubject       
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
}

extension ResultsTableController: UIPickerViewDelegate, UIPickerViewDataSource {
    
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
