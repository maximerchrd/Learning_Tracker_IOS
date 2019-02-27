//
//  QuestionMultipleChoiceViewController.swift
//  Learning_Tracker_IOS
//
//  Created by Maxime Richard on 24.02.18.
//  Copyright © 2018 Maxime Richard. All rights reserved.
//

import Foundation
import UIKit

class QuestionMultipleChoiceViewController: UITableViewController {
    var isSyncTest: Bool
    var isCorrection: Bool
    var questionMultipleChoice: QuestionMultipleChoice

    var checkBoxArray: [CheckBox]
    var stackView: UIStackView!
    var directCorrection = 0
    var isBackButton = true
    var startTime: TimeInterval = 0.0
    var firstLabel:UILabel = UILabel()
    
    @IBOutlet weak var QuestionTextView: UITextView!
    @IBOutlet weak var PictureView: UIImageView!
    @IBOutlet weak var SubmitButton: UIButton!
    @IBOutlet weak var OptionsView: UIView!
    @IBOutlet weak var QuestionCell: UITableViewCell!
    @IBOutlet weak var ImageCell: UITableViewCell!
    @IBOutlet weak var OptionsCell: UITableViewCell!
    @IBOutlet weak var ButtonCell: UITableViewCell!
    
    required init?(coder aDecoder: NSCoder) {
        questionMultipleChoice = QuestionMultipleChoice()
        checkBoxArray = [CheckBox]()
        isCorrection = false
        isSyncTest = false
        super.init(coder: aDecoder)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Set question text
        QuestionTextView.text = questionMultipleChoice.question
        QuestionTextView.sizeToFit()
        print("questionTextView height: " + String(describing: QuestionTextView.frame.height))
        
        
        // Display picture
        if questionMultipleChoice.image != "none" {
            let nsDocumentDirectory = FileManager.SearchPathDirectory.documentDirectory
            let nsUserDomainMask    = FileManager.SearchPathDomainMask.userDomainMask
            let paths               = NSSearchPathForDirectoriesInDomains(nsDocumentDirectory, nsUserDomainMask, true)
            if let dirPath          = paths.first {
                let imageURL = URL(fileURLWithPath: dirPath).appendingPathComponent(questionMultipleChoice.image)
                PictureView.image    = UIImage(contentsOfFile: imageURL.path)
            }
        } else {
            PictureView.frame = CGRect(x: 0, y:0, width: 0, height: 0)
            ImageCell.isHidden = true
        }
        
        if isCorrection {
            SubmitButton.setTitle(NSLocalizedString("OK", comment: "OK button"), for: .normal)
        }

        //send receipt to server
        let transferable = ClientToServerTransferable(prefix: ClientToServerTransferable.activeIdPrefix,
                optionalArgument: String(questionMultipleChoice.id))
        AppDelegate.wifiCommunicationSingleton?.sendData(data: transferable.getTransferableData())

        //start timer
        startTime = Date.timeIntervalSinceReferenceDate

        //start timer if necessary
        if questionMultipleChoice.timerSeconds > 0 {
            if let navigationBar = self.navigationController?.navigationBar {
                let firstFrame = CGRect(x: navigationBar.frame.width/2, y: 0, width: navigationBar.frame.width/2, height: navigationBar.frame.height)

                firstLabel = UILabel(frame: firstFrame)
                firstLabel.text = String(questionMultipleChoice.timerSeconds)

                navigationBar.addSubview(firstLabel)
            }
            DispatchQueue.global(qos: .utility).async {
                var timeInterval = Date.timeIntervalSinceReferenceDate - self.startTime
                while (self.questionMultipleChoice.timerSeconds - Int(Date.timeIntervalSinceReferenceDate - self.startTime)) > 0 {
                    sleep(1)
                    DispatchQueue.main.async {
                        self.firstLabel.text = String(self.questionMultipleChoice.timerSeconds - Int(Date.timeIntervalSinceReferenceDate - self.startTime))
                    }
                }
                //disable button
                DispatchQueue.main.async {
                    self.SubmitButton.isEnabled = false
                    self.SubmitButton.alpha = 0.4
                }
            }
        }
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        //get the answer options to adapt the size of the imageview
        questionMultipleChoice = QuestionsTools.removeEmptyOptions(question: questionMultipleChoice)
        var optionsArray = questionMultipleChoice.options
        
        // DISPLAY OPTIONS
        //First implements stackview inside scrollview
        stackView = UIStackView()
        stackView.translatesAutoresizingMaskIntoConstraints = false
        stackView.axis = .vertical
        OptionsView.addSubview(stackView)
        
        if !isCorrection {
            optionsArray = shuffle(arrayArg: optionsArray)
        }
        var i = 1
        for singleOption in optionsArray {
            let checkBox = CheckBox()
            checkBox.isChecked = false
            if isCorrection {
                if i <= questionMultipleChoice.NbCorrectAnswers {
                    checkBox.isChecked = true
                }
                checkBox.isEnabled = false
            }
            checkBox.setTitle(singleOption, for: .normal)
            checkBox.addTarget(checkBox, action: #selector(checkBox.buttonClicked(sender:)), for: .touchUpInside)
            checkBox.setTitleColor(.black, for: .normal)
            checkBox.titleLabel?.lineBreakMode = NSLineBreakMode.byWordWrapping
            checkBox.widthAnchor.constraint(equalToConstant: OptionsView.frame.width - checkBox.checkedImage.size.width * 1).isActive = true
            checkBox.contentEdgeInsets = UIEdgeInsetsMake(0,OptionsView.frame.width / 30,0,0)
            
            //make some tweaks to put more space above and below longer answer options
            var factorAccordingTextLength = 1
            if UIScreen.main.traitCollection.userInterfaceIdiom == .pad {
                factorAccordingTextLength = Int(((checkBox.titleLabel?.text?.count) ?? 200) / 200)
            } else {
                factorAccordingTextLength = Int(((checkBox.titleLabel?.text?.count) ?? 75) / 75)
            }
            for _ in 0..<factorAccordingTextLength {
                let ghostButton = UIButton(frame: CGRect(x: 0, y: 0, width: 30, height: 2))
                ghostButton.setTitle(" ", for: .normal)
                ghostButton.titleLabel?.font =  UIFont(name: "Times New Roman", size: 1)
                stackView.addArrangedSubview(ghostButton)
            }
            stackView.addArrangedSubview(checkBox)
            for _ in 0..<factorAccordingTextLength {
                let ghostButton = UIButton(frame: CGRect(x: 0, y: 0, width: 30, height: 2))
                ghostButton.setTitle(" ", for: .normal)
                ghostButton.titleLabel?.font =  UIFont(name: "Times New Roman", size: 1)
                stackView.addArrangedSubview(ghostButton)
            }
            if UIScreen.main.traitCollection.userInterfaceIdiom == .pad {
                stackView.spacing = checkBox.checkedImage.size.height * 0.5
            } else {
                stackView.spacing = checkBox.checkedImage.size.height * 1.7
            }
            checkBoxArray.append(checkBox)
            i = i + 1
        }
        
        /**
         * START CODE USED FOR TESTING
         */
        if questionMultipleChoice.question.contains("*ç%&") {
            AppDelegate.wifiCommunicationSingleton?.sendAnswerToServer(answers: [optionsArray[0]], answer: optionsArray[0], globalID: questionMultipleChoice.id, questionType: "ANSW0", timeSpent: 2.63)
            if let navController = self.navigationController {
                //set cached view controller to nil to prevent students answering several times to same question
                isBackButton = false
                ClassroomActivityViewController.navQuestionMultipleChoiceViewController = nil
                print( ClassroomActivityViewController.navQuestionMultipleChoiceViewController as Any )
                
                navController.popViewController(animated: true)
            }
        }
        /**
         * END CODE USED FOR TESTING
         */
        
        //set scrolling size
        /*OptionsScrollView.frame = CGRect(x: scrollViewX, y: scrollViewY, width: scrollViewWidth, height: scrollViewHeight)
        OptionsScrollView.contentSize = CGSize(width: stackView.frame.width, height: stackView.frame.height)*/

        if SubmitButton.isEnabled {
            self.firstLabel.isHidden = false
        }
    }
    
    override func viewWillLayoutSubviews() {
        super.viewWillLayoutSubviews()
        //scrollPosition = OptionsScrollView.contentOffset.y
    }
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        /*OptionsScrollView.frame = CGRect(x: scrollViewX, y: scrollViewY, width: scrollViewWidth, height: scrollViewHeight)
        OptionsScrollView.contentSize = CGSize(width: stackView.frame.width, height: stackView.frame.height)
        OptionsScrollView.contentOffset.y = scrollPosition
        OptionsScrollView.flashScrollIndicators()*/
    }
    override func viewWillDisappear(_ animated: Bool) {
        if isBackButton {
            ClassroomActivityViewController.navQuestionShortAnswerViewController = nil
            ClassroomActivityViewController.navQuestionMultipleChoiceViewController = self
        }
        self.firstLabel.isHidden = true
    }
    
    func shuffle(arrayArg: [String]) -> [String] {
        var array = arrayArg
        //implementing Fisher-Yates shuffle
        for i in 0..<array.count {
            let random = arc4random_uniform(UInt32(array.count))
            let index = Int(random)
            // Simple swap
            let a = array[index];
            array[index] = array[i];
            array[i] = a;
        }
        return array
    }
    
    
    @IBAction func submitAnswerButtonTouched(_ sender: Any) {
        //stop timer
        var timeInterval = Date.timeIntervalSinceReferenceDate - startTime
        timeInterval = Double(round(10*timeInterval)/10)
        
        //disable button
        SubmitButton.isEnabled = false
        SubmitButton.alpha = 0.4
        
        //first send answer to server
        if !isCorrection {
            var answers = ""
            var answersArray = [String]()
            for singleCheckBox in checkBoxArray {
                if singleCheckBox.isChecked {
                    answers += (singleCheckBox.titleLabel?.text ?? " ") + "|||"
                    answersArray.append((singleCheckBox.titleLabel?.text) ?? " ")
                }
            }
            AppDelegate.wifiCommunicationSingleton?.sendAnswerToServer(answers: answersArray, answer: answers, globalID: questionMultipleChoice.id, questionType: "ANSW0", timeSpent: timeInterval)
        }
        
        //add question ID to answered ids for the test
        AppDelegate.activeTest.answeredIds.append(String(questionMultipleChoice.id))
        
        //show correct/incorrect message if direct correction mode activated
        if (directCorrection == 1) {
            var answers = ""
            var answersArray = [String]()
            for singleCheckBox in checkBoxArray {
                if singleCheckBox.isChecked {
                    answers += (singleCheckBox.titleLabel?.text)! + "|||"
                    answersArray.append((singleCheckBox.titleLabel?.text)!)
                }
            }
            var options = questionMultipleChoice.options
            var rightAnswers = [String]()
            for i in 0..<questionMultipleChoice.NbCorrectAnswers {
                rightAnswers.append(options[i])
            }
            if rightAnswers.containsSameElements(as: answersArray) {
                let alert = UIAlertController(title: NSLocalizedString("Correct!", comment: "pop up if answer right"), message: "", preferredStyle: .alert)
                alert.addAction(UIAlertAction(title: "OK", style: .cancel, handler: handleNavigation))
                self.present(alert, animated: true)
            } else {
                var message = NSLocalizedString("The right answer was: ", comment: "pop up message if answer wrong")
                for answer in rightAnswers {
                    message += answer + "; "
                }
                let alert = UIAlertController(title: NSLocalizedString("Incorrect :-(", comment: "pop up if answer wrong"), message: message, preferredStyle: .alert)
                alert.addAction(UIAlertAction(title: "OK", style: .cancel, handler: handleNavigation))
                self.present(alert, animated: true)
            }
        } else {
            if !isSyncTest {
                if let navController = self.navigationController {
                    //set cached view controller to nil to prevent students answering several times to same question
                    isBackButton = false
                    ClassroomActivityViewController.navQuestionMultipleChoiceViewController = nil
                    print( ClassroomActivityViewController.navQuestionMultipleChoiceViewController as Any )
                    
                    navController.popViewController(animated: true)
                }
            } 
        }
    }
    
    func handleNavigation(alert: UIAlertAction!) {
        if !isSyncTest {
            if let navController = self.navigationController {
                //set cached view controller to nil to prevent students answering several times to same question
                isBackButton = false
                ClassroomActivityViewController.navQuestionMultipleChoiceViewController = nil
                
                navController.popViewController(animated: true)
            }
        } else {
            SubmitButton.isEnabled = false
            SubmitButton.alpha = 0.4
        }
    }
    
    func tableView(tableView: UITableView, heightForRowAtIndexPath indexPath: NSIndexPath) -> CGFloat {
        return UITableViewAutomaticDimension
    }
    
    func tableView(tableView: UITableView, estimatedHeightForRowAtIndexPath indexPath: NSIndexPath) -> CGFloat {
        return UITableViewAutomaticDimension
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }    
}
