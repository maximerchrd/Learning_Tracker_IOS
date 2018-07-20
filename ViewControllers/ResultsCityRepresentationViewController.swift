//
//  ResultsCityRepresentationViewController.swift
//  Learning_Tracker_IOS
//
//  Created by Maxime Richard on 03.07.18.
//  Copyright © 2018 Maxime Richard. All rights reserved.
//

import Foundation
import UIKit

class ResultsCityRepresentationViewController: UIViewController {
    //used to know which pickerView Button was tapped when displaying pickerView
    var activePickerType = 0
    
    var selectedSubject = NSLocalizedString("All subjects", comment: "All subjects in the database")
    var subjects = [String]()
    var selectedTest = NSLocalizedString("All tests", comment: "All tests in the database")
    var tests = [String]()
    var testIDs = [Int64]()
    
    var objectiveLeftSide = CGFloat(0.0)
    
    @IBOutlet weak var scrollView: UIScrollView!
    
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
        
        let uiButtonSubject = UIButton(frame: CGRect(x: 0, y: 0, width: 210, height: 30))
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
                testIDs.append(Int64(test[1]) ?? -1)
            }
        } catch let error {
            print(error)
        }
        tests.insert(NSLocalizedString("All tests", comment: "All tests in the database"), at: 0)
        testIDs.insert(0, at: 0)
        
        let uiButtonTest = UIButton(frame: CGRect(x: 0, y: 0, width: 210, height: 30))
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
        
        //initialize scroll View and draw the results
        let origin = scrollView.bounds.origin
        let offset = scrollView.contentOffset
        drawCity(subject: "All", testID: 0)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        AppDelegate.AppUtility.lockOrientation(.landscape, andRotateTo: .landscapeRight)
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        AppDelegate.AppUtility.lockOrientation(.all, andRotateTo: .portrait)
    }
    
    func drawCity(subject: String, testID: Int64, test: String = "") {
        do {
            //START selecting the right objectives and results
            var evalForObjectives = try DbTableLearningObjective.getResultsPerObjective(subject: subject)
            var objectives = evalForObjectives[0]
            var results = evalForObjectives[1]
            
            var certifObjectives = [String]()
            var certifResults = [String]()
            
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
                
                //get results for objectives if the test is certificative
                let testType = DbTableTests.getTypeFromTestID(testID: testID)
                if testType.range(of:"CERTIF") != nil {
                    let certifEvalForObjectives = try DbTableIndividualQuestionForResult.getResultsPerObjectiveForCertificativeTest(test: test)
                    certifObjectives = certifEvalForObjectives[0]
                    certifResults = certifEvalForObjectives[1]
                }
            }
            //END selecting the right objectives and results
            
            //START drawing the buildings
            //first clean up the scroll view
            objectiveLeftSide = 0.0
            for subView in scrollView.subviews {
                subView.removeFromSuperview()
            }
            
            if certifObjectives.count > 0 {
                //we display a certificative test
                for i in 0..<certifObjectives.count {
                    let objIndex = objectives.index(of: certifObjectives[i]) ?? -1
                    if objIndex >= 0 {
                        drawBuilding(objective: certifObjectives[i], formativeResult: Double(results[objIndex]) ?? -1.0, certificativeResult: Double(certifResults[i]) ?? -1.0)
                    } else {
                        drawBuilding(objective: certifObjectives[i], formativeResult: -1.0, certificativeResult: Double(certifResults[i]) ?? -1.0)
                    }
                }
            } else {
                for i in 0..<objectives.count {
                    drawBuilding(objective: objectives[i], formativeResult: Double(results[i]) ?? -1.0)
                }
            }
            //END drawing the buildings
        } catch let error {
            print(error)
        }
    }
    
    func drawBuilding(objective: String, formativeResult: Double = -1.0, certificativeResult: Double = -1.0) {
        var screenWidth = UIScreen.main.bounds.width
        var screenHeight = UIScreen.main.bounds.height
        if screenWidth > screenHeight {
            let saveWidth = screenWidth
            screenWidth = screenHeight
            screenHeight = saveWidth
        }
        let objectiveWidth = screenWidth * 0.4
        
        var qualitativeEvaluation = ""
        
        var nbOfObjectives = 0
        
        if (formativeResult != -1 && certificativeResult != -1) {
            nbOfObjectives = 2
        } else {
            nbOfObjectives = 1
        }
        
        //format objective label
        let objectiveLabel = UILabel(frame: CGRect(x: objectiveLeftSide, y: 0, width: objectiveWidth * CGFloat(nbOfObjectives), height: screenWidth * 0.15))
        objectiveLabel.text = objective
        objectiveLabel.lineBreakMode = .byWordWrapping
        objectiveLabel.numberOfLines = 3
        
        scrollView.addSubview(objectiveLabel)
        
        var offsetIndex = CGFloat(0)
        for i in 0..<2 {
            if i == 0 && formativeResult != -1 || i == 1 && certificativeResult != -1 {
                var result = -1.0
                var indication = ""
                
                if i == 0 && formativeResult != -1 {
                    result = formativeResult
                    indication = "Formative: "
                } else if i == 1 && certificativeResult != -1 {
                    result = certificativeResult
                    indication = "Certificative: "
                }
                
                //format image
                let imageView = UIImageView(frame: CGRect(x: objectiveLeftSide + objectiveWidth * offsetIndex, y: screenWidth * 0.15, width: objectiveWidth, height: screenWidth * 0.55))
                
                if result < 50 {
                    imageView.image = UIImage(named: "building_worst")
                    qualitativeEvaluation = "Can do better :-|"
                } else if result < 70 {
                    imageView.image = UIImage(named: "building_worst")
                    qualitativeEvaluation = "OK"
                } else if result < 90 {
                    imageView.image = UIImage(named: "building_best")
                    qualitativeEvaluation = "Good!"
                } else {
                    imageView.image = UIImage(named: "building_best")
                    qualitativeEvaluation = "Excellent!!! :-))"
                }
                
                scrollView.addSubview(imageView)
                
                //format indication and evaluation label
                let indicationLabel = UILabel(frame: CGRect(x: objectiveLeftSide + objectiveWidth * offsetIndex, y: screenWidth * 0.7, width: objectiveWidth, height: screenWidth * 0.15))
                indicationLabel.text = indication + qualitativeEvaluation
                indicationLabel.lineBreakMode = .byWordWrapping
                indicationLabel.numberOfLines = 3
                scrollView.addSubview(indicationLabel)
                
                offsetIndex += 1.0
            }
        }
        
        objectiveLeftSide += objectiveWidth * CGFloat(nbOfObjectives) + 30
        scrollView.contentSize = CGSize(width: objectiveLeftSide, height: 0)
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
        drawCity(subject: "All", testID: testID, test: selectedTest)
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
        drawCity(subject: selectedSubject, testID: 0)
        (navigationItem.rightBarButtonItems![0].customView as! UIButton).titleLabel?.text = NSLocalizedString("Subject:", comment: "on button to chose subject") + selectedSubject
        selectedTest = NSLocalizedString("All tests", comment: "All tests in the database")
        (navigationItem.rightBarButtonItems![1].customView as! UIButton).titleLabel?.text = NSLocalizedString("Test:", comment: "on button to chose subject") + selectedTest
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
}

extension ResultsCityRepresentationViewController: UIPickerViewDelegate, UIPickerViewDataSource {
    
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
