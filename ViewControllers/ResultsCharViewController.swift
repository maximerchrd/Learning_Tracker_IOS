//
//  ResultsCharViewController.swift
//  Learning_Tracker_IOS
//
//  Created by Maxime Richard on 27.02.18.
//  Copyright © 2018 Maxime Richard. All rights reserved.
//

import Foundation
import UIKit
import Charts

class ResultsChartViewController: UIViewController {
    
    //used to know which pickerView Button was tapped when displaying pickerView
    var activePickerType = 0
    
    var selectedSubject = NSLocalizedString("All subjects", comment: "All subjects in the database")
    var subjects = [String]()
    var selectedTest = NSLocalizedString("All tests", comment: "All tests in the database")
    var tests = [String]()
    var testIDs = [Int]()
    
    @IBOutlet weak var BarChart: HorizontalBarChartView!
    
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
        
        let uiButtonTest = UIButton(frame: CGRect(x: 0, y: 0, width: 250, height: 30))
        var testTitleString = NSLocalizedString("Test: ", comment: "on button to chose subject") + selectedTest
        if testTitleString.count < 28 {
            for _ in testTitleString.count..<28 {
                testTitleString.append(" ")
            }
        }
        uiButtonTest.setTitle(testTitleString, for: .normal)
        uiButtonTest.backgroundColor = UIColor.gray
        uiButtonTest.tintColor = UIColor.blue
        uiButtonTest.layer.cornerRadius = 4.0
        uiButtonTest.layer.masksToBounds = true
        uiButtonTest.addTarget(self, action: #selector(addTestTapped), for: .touchUpInside)
        let testsButton = UIBarButtonItem(customView: uiButtonTest)
        
        
        //add buttons to the navigation bar
        navigationItem.rightBarButtonItems = [subjectsButton, testsButton]
        
        barChartUpdate(subject: "All", testID: 0)
    }
    
    public func barChartUpdate (subject: String, testID: Int) {
        do {
            var evalForObjectives = try DbTableLearningObjective.getResultsPerObjective(subject: subject)
            var objectives = evalForObjectives[0]
            var results = evalForObjectives[1]
            
            //filter test objectives if a test is selected
            if testID != 0 {
                let testObjectives = DbTableTests.getObjectivesFromTestID(testID: testID)
                var indexesToDelete = [Int]()
                for i in 0..<objectives.count {
                    if !testObjectives.contains(objectives[i]) {
                        indexesToDelete.append(i)
                    }
                }
                indexesToDelete.reverse()
                for index in indexesToDelete {
                    results.remove(at: index)
                    objectives.remove(at: index)
                }
            }
            
            objectives.insert("", at: 0)
            results.insert("0.0", at: 0)
            
            var entries = [BarChartDataEntry]()
            for i in 0..<results.count {
                let entry = BarChartDataEntry(x: Double(i) - 0.5, yValues: [Double(results[i]) ?? 0.0])
                entries.append(entry)
            }
            let dataSet = BarChartDataSet(values: entries, label: NSLocalizedString("Evaluation for each learning objective", comment: "chart label"))
            dataSet.drawValuesEnabled = false
            let data = BarChartData(dataSets: [dataSet])
            
            BarChart.data = data
            
            let xAxis = BarChart.xAxis
            xAxis.granularity = 0.5
            //xAxis.setDrawGridLines(false);
            xAxis.valueFormatter = IndexAxisValueFormatter(values: objectives)
            xAxis.labelPosition = XAxis.LabelPosition.bottomInside
            xAxis.labelCount = results.count * 2
            xAxis.axisMinimum = 0.0
            xAxis.drawGridLinesEnabled = false
            
            
            
            let yAxis = BarChart.leftAxis
            yAxis.axisMaximum = 100.0
            yAxis.axisMinimum = 0.0
            yAxis.labelCount = 10
            let yAxisright = BarChart.rightAxis
            yAxisright.axisMaximum = 100.0
            yAxisright.axisMinimum = 0.0
            yAxisright.labelCount = 10

            BarChart.notifyDataSetChanged()
        } catch let error {
            print(error)
        }
    }
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
        barChartUpdate(subject: "All", testID: testID)
        (navigationItem.rightBarButtonItems![1].customView as! UIButton).titleLabel?.text = NSLocalizedString("Test:", comment: "on button to chose subject") + selectedTest
        selectedSubject = NSLocalizedString("All subjects", comment: "All subjects in the database")
        (navigationItem.rightBarButtonItems![0].customView as! UIButton).titleLabel?.text = NSLocalizedString("Subject:", comment: "on button to chose subject") + selectedSubject
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
        barChartUpdate(subject: selectedSubject, testID: 0)
        (navigationItem.rightBarButtonItems![0].customView as! UIButton).titleLabel?.text = NSLocalizedString("Subject:", comment: "on button to chose subject") + selectedSubject
        selectedTest = NSLocalizedString("All tests", comment: "All tests in the database")
        (navigationItem.rightBarButtonItems![1].customView as! UIButton).titleLabel?.text = NSLocalizedString("Test:", comment: "on button to chose subject") + selectedTest
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
}
extension ResultsChartViewController: UIPickerViewDelegate, UIPickerViewDataSource {

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
