//
//  ResultsTargetRepresentationViewController.swift
//  Learning_Tracker_IOS
//
//  Created by Maxime Richard on 27.02.18.
//  Copyright © 2018 Maxime Richard. All rights reserved.
//

import Foundation
import UIKit

class ResultsTargetRepresentationViewController: UIViewController {
    //used to know which pickerView Button was tapped when displaying pickerView
    var activePickerType = 0
    //arrays for filtering according to subject or test
    var selectedSubject = NSLocalizedString("All subjects", comment: "All subjects in the database")
    var subjects = [String]()
    var selectedTest = NSLocalizedString("All tests", comment: "All tests in the database")
    var tests = [String]()
    var testIDs = [Int]()
    
    var evaluations_low = [String]()
    var evaluations_middle = [String]()
    var evaluations_high = [String]()
    var evaluations_top = [String]()
    var labelsArray = [UILabel]()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
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
        let subjectsButton = UIBarButtonItem(title: NSLocalizedString("Subject: ", comment: "on button to chose subject") + selectedSubject, style: .plain, target: self, action: #selector(addTapped))
        
        //load the tests and setup the corresponding picker view
        do {
            let allTests = try DbTableTests.getAllTests()
            for test in allTests {
                tests.append(test[0])
                testIDs.append(Int(test[1]) ?? -1)
            }
        } catch let error {
            print(error)
        }
        tests.insert(NSLocalizedString("All tests", comment: "All tests in the database"), at: 0)
        testIDs.insert(0, at: 0)
        let testsButton = UIBarButtonItem(title: NSLocalizedString("Test: ", comment: "on button to chose subject") + selectedTest, style: .plain, target: self, action: #selector(addTestTapped))
        navigationItem.rightBarButtonItems = [subjectsButton, testsButton]
        
        
        updateTargetRepresentation(subject: NSLocalizedString("All subjects", comment: "All subjects in the database"), testID: 0)
    }
    
    public func updateTargetRepresentation(subject: String, testID: Int) {
        for singleLabel in labelsArray {
            singleLabel.removeFromSuperview()
        }
        evaluations_low.removeAll(keepingCapacity: true)
        evaluations_middle.removeAll(keepingCapacity: true)
        evaluations_high.removeAll(keepingCapacity: true)
        evaluations_top.removeAll(keepingCapacity: true)
        var allEvals = [[String]]()
        do {
            allEvals = try DbTableLearningObjective.getResultsPerObjective(subject: subject)
        } catch let error {
            print(error)
        }
        var allObjectives = allEvals[0]
        var allResults = allEvals[1]
        
        //filter test objectives if a test is selected
        if testID != 0 {
            let testObjectives = DbTableTests.getObjectivesFromTestID(testID: testID)
            var indexesToDelete = [Int]()
            for i in 0..<allObjectives.count {
                if !testObjectives.contains(allObjectives[i]) {
                    indexesToDelete.append(i)
                }
            }
            indexesToDelete.reverse()
            for index in indexesToDelete {
                allResults.remove(at: index)
                allObjectives.remove(at: index)
            }
        }
        
        for i in 0..<allObjectives.count {
            if Double(allResults[i]) ?? 0 < 50.0 {
                evaluations_low.append(allObjectives[i])
            } else if Double(allResults[i]) ?? 0 < 70.0 {
                evaluations_middle.append(allObjectives[i])
            } else if Double(allResults[i]) ?? 0 < 90.0 {
                evaluations_high.append(allObjectives[i])
            } else {
                evaluations_top.append(allObjectives[i])
            }
        }
        displayObjectives(objectives: evaluations_low, color: UIColor.red, performanceFactor: 0.5)
        displayObjectives(objectives: evaluations_middle, color: UIColor(red: 0, green: 0.6392, blue: 0.0314, alpha: 1.0), performanceFactor: 0.3)
        displayObjectives(objectives: evaluations_high, color: UIColor.blue, performanceFactor: 0.1)
        displayObjectives(objectives: evaluations_top, color: UIColor.magenta, performanceFactor: 0.0)
    }
    
    private func displayObjectives(objectives: [String], color: UIColor, performanceFactor: Double) {
        let screenSize = UIScreen.main.bounds
        let width = Int(screenSize.width)
        let height = Int(screenSize.height)
        for i in 0..<objectives.count {
            //calculate coordinates
            let stepper = 1 - (i % 3);
            let horizontalStep = width/3 * (stepper) + 100;
            let leftMargin = width / 3 + horizontalStep;
            let verticalStep = (i / 3) * height/20 + 100;
            let topMargin = Int(Double(height) * performanceFactor + Double(verticalStep));    //should increase one step every 3 textViews
            let label = UILabel(frame: CGRect(x: 0, y: 0, width: 200, height: 21))
            label.center = CGPoint(x: leftMargin, y: topMargin)
            label.textAlignment = .center
            label.textColor = color
            label.text = objectives[i]
            self.view.addSubview(label)
            labelsArray.append(label)
            
            //add action listener to the label
            let tap = UITapGestureRecognizer(target: self, action: #selector(self.tapFunction))
            label.isUserInteractionEnabled = true
            label.addGestureRecognizer(tap)
        }
    }
    @objc func tapFunction(sender:UITapGestureRecognizer) {
        let label = sender.view as? UILabel
        let center = label?.center
        if label?.numberOfLines != 10 {
            label?.numberOfLines = 10
            label?.backgroundColor = UIColor.white
            label?.sizeToFit()
            label?.center = center!
            label?.layer.zPosition = 1;
        } else {
            label?.backgroundColor = UIColor.clear
            label?.textAlignment = .center
            label?.numberOfLines = 1
            label?.bounds = CGRect(x: 0, y: 0, width: 200, height: 21)
            label?.center = center!
        }
    }
    
    //functions for pickerView
    @objc func addTestTapped() {
        activePickerType = 1
        let alertView = UIAlertController(
            title: NSLocalizedString("Choose a test", comment: "in the item picker for the evaluation charts"),
            message: "\n\n\n\n\n\n\n\n\n",
            preferredStyle: .alert)
        
        let pickerViewTest = UIPickerView(frame:
            CGRect(x: 0, y: 50, width: 260, height: 162))
        
        pickerViewTest.dataSource = self as UIPickerViewDataSource
        pickerViewTest.delegate = self as UIPickerViewDelegate
        
        // comment this line to use white color
        pickerViewTest.backgroundColor = UIColor.lightGray.withAlphaComponent(0.2)
        pickerViewTest.selectRow(tests.index(of: selectedTest) ?? 0, inComponent: 0, animated: false)
        
        alertView.view.addSubview(pickerViewTest)
        
        let action = UIAlertAction(title: "OK", style: UIAlertActionStyle.default, handler: {(alert: UIAlertAction!) in self.OKTestButtonPressed()})
        
        alertView.addAction(action)
        present(alertView, animated: true)
    }
    
    func OKTestButtonPressed() {
        let testIndex = tests.index(of: selectedTest) ?? 0
        let testID = testIDs[testIndex]
        updateTargetRepresentation(subject: selectedSubject, testID: testID)
        navigationItem.rightBarButtonItems![1].title = NSLocalizedString("Test:", comment: "on button to chose subject") + selectedTest
        selectedSubject = NSLocalizedString("All subjects", comment: "All subjects in the database")
        navigationItem.rightBarButtonItems![0].title = NSLocalizedString("Subject:", comment: "on button to chose subject") + selectedSubject
    }
    @objc func addTapped() {
        activePickerType = 0
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
        updateTargetRepresentation(subject: selectedSubject, testID: 0)
        navigationItem.rightBarButtonItems![0].title = NSLocalizedString("Subject:", comment: "on button to chose subject") + selectedSubject
        selectedTest = NSLocalizedString("All tests", comment: "All tests in the database")
        navigationItem.rightBarButtonItems![1].title = NSLocalizedString("Test:", comment: "on button to chose subject") + selectedTest
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
}

extension ResultsTargetRepresentationViewController: UIPickerViewDelegate, UIPickerViewDataSource {
    
    func numberOfComponents(in pickerView: UIPickerView) -> Int {
        return 1
    }
    
    
    func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        if activePickerType == 0 {
            return subjects.count
        } else {
            return tests.count
        }
    }
    
    
    func pickerView(_ pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String? {
        if activePickerType == 0 {
            return subjects[row]
        } else {
            return tests[row]
        }
    }
    
    
    func pickerView(_ pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int) {
        if activePickerType == 0 {
            selectedSubject = subjects[row]
        } else {
            selectedTest = tests[row]
        }
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
        
        if activePickerType == 0 {
            label.text = subjects[row]
        } else {
            label.text = tests[row]
        }
        
        return label
    }
}
