//
//  QuestionShortAnswerViewController.swift
//  Learning_Tracker_IOS
//
//  Created by Maxime Richard on 27.02.18.
//  Copyright © 2018 Maxime Richard. All rights reserved.
//

import Foundation
import UIKit

class QuestionShortAnswerViewController: UIViewController, UITextFieldDelegate {
    var questionShortAnswer: QuestionShortAnswer
    var isSyncTest: Bool
    var isCorrection: Bool
    var screenHeight: Float
    var screenWidth: Float
    var imageMagnified = false
    var originaImageWidth:CGFloat = 0
    var originalImageHeight:CGFloat = 0
    var originalImageX:CGFloat = 0
    var originalImageY:CGFloat = 0
    var newImageWidth:Float = 0
    var newImageHeight:Float = 0
    var newImageX:Float = 0
    var directCorrection = 0
    var isBackButton = true
    var startTime: TimeInterval = 0.0
    var firstLabel:UILabel = UILabel()
    
    @IBOutlet weak var AnswerTextField: UITextField!
    @IBOutlet weak var QuestionTextView: UITextView!
    @IBOutlet weak var PictureView: UIImageView!
    @IBOutlet weak var SubmitButton: UIButton!
    
    required init?(coder aDecoder: NSCoder) {
        questionShortAnswer = QuestionShortAnswer()
        screenHeight = 0
        screenWidth = 0
        isCorrection = false
        isSyncTest = false
        super.init(coder: aDecoder)
    }
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Do any additional setup after loading the view, typically from a nib.
        let screenSize = UIScreen.main.bounds
        screenWidth = Float(screenSize.width)
        screenHeight = Float(screenSize.height)
        
        // Set question text
        QuestionTextView.text = questionShortAnswer.question
        QuestionTextView.isEditable = false
        
        // Display picture
        let nsDocumentDirectory = FileManager.SearchPathDirectory.documentDirectory
        let nsUserDomainMask    = FileManager.SearchPathDomainMask.userDomainMask
        let paths               = NSSearchPathForDirectoriesInDomains(nsDocumentDirectory, nsUserDomainMask, true)
        if let dirPath          = paths.first {
            let imageURL = URL(fileURLWithPath: dirPath).appendingPathComponent(questionShortAnswer.image)
            PictureView.image    = UIImage(contentsOfFile: imageURL.path)
        }
        originaImageWidth = PictureView.frame.width
        originalImageHeight = PictureView.frame.height
        originalImageX = PictureView.frame.minX
        originalImageY = PictureView.frame.minY
        newImageWidth = screenWidth
        newImageHeight = Float(originalImageHeight) / Float(originaImageWidth) * screenWidth
        newImageX = 0
        
        //set delegate to hide keyboard when return pressed
        self.AnswerTextField.delegate = self
        
        //if in correction mode, give the answer and change button label
        if isCorrection {
            var exampleAnswer = NSLocalizedString("The right answer was for example: ", comment: "in short answer question text field")
            if questionShortAnswer.options.count > 0 {
                exampleAnswer += questionShortAnswer.options[0]
            }
            self.AnswerTextField.text = exampleAnswer
            self.AnswerTextField.isEnabled = false
            SubmitButton.setTitle(NSLocalizedString("OK", comment: "OK button"), for: .normal)
        }

        //send receipt to server
        var transferable = ClientToServerTransferable(prefix: ClientToServerTransferable.activeIdPrefix,
                optionalArgument: String(questionShortAnswer.id))
        AppDelegate.wifiCommunicationSingleton?.sendData(data: transferable.getTransferableData())

        //start timer
        startTime = Date.timeIntervalSinceReferenceDate

        //start timer if necessary
        if questionShortAnswer.timerSeconds > 0 {
            if let navigationBar = self.navigationController?.navigationBar {
                let firstFrame = CGRect(x: navigationBar.frame.width/2, y: 0, width: navigationBar.frame.width/2, height: navigationBar.frame.height)

                firstLabel = UILabel(frame: firstFrame)
                firstLabel.text = String(questionShortAnswer.timerSeconds)

                navigationBar.addSubview(firstLabel)
            }
            DispatchQueue.global(qos: .utility).async {
                var timeInterval = Date.timeIntervalSinceReferenceDate - self.startTime
                while (self.questionShortAnswer.timerSeconds - Int(Date.timeIntervalSinceReferenceDate - self.startTime)) > 0 {
                    sleep(1)
                    DispatchQueue.main.async {
                        self.firstLabel.text = String(self.questionShortAnswer.timerSeconds - Int(Date.timeIntervalSinceReferenceDate - self.startTime))
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
        //dismiss keyboard if we are coming back to question
        self.view.endEditing(true)
        if SubmitButton.isEnabled {
            self.firstLabel.isHidden = false
        }
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        if isBackButton {
            ClassroomActivityViewController.navQuestionShortAnswerViewController = self
            ClassroomActivityViewController.navQuestionMultipleChoiceViewController = nil
        }
        self.firstLabel.isHidden = true
    }
    
    
    //function enabling dismissing of keyboard when return pressed
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        self.view.endEditing(true)
        return false
    }
    
    @IBAction func imageTouched(_ sender: Any) {
        if imageMagnified {
            PictureView.frame = CGRect(x: originalImageX, y: originalImageY, width: originaImageWidth, height: originalImageHeight)
            imageMagnified = false
        } else {
            PictureView.frame = CGRect(x: CGFloat(newImageX), y: originalImageY, width: CGFloat(newImageWidth), height: CGFloat(newImageHeight))
            self.view.bringSubview(toFront: PictureView)
            imageMagnified = true
        }
    }
    
    @IBAction func submitAnswerButtonTouched(_ sender: Any) {
        //stop timer
        let timeInterval = Date.timeIntervalSinceReferenceDate - (startTime ?? 0)
        
        //disable button
        SubmitButton.isEnabled = false
        SubmitButton.alpha = 0.4
        
        //first send answer to server
        if !isCorrection {
            AppDelegate.wifiCommunicationSingleton?.sendAnswerToServer(answers: [AnswerTextField.text!], answer: AnswerTextField.text!,
                    globalID: questionShortAnswer.id, questionType: "ANSW1", timeSpent: timeInterval)
        }
        
        //add question ID to answered ids for the test
        AppDelegate.activeTest.answeredIds.append(String(questionShortAnswer.id))
        
        //show correct/incorrect message if direct correction mode activated
        if (directCorrection == 1) {
            let studentAnswer = AnswerTextField.text!
            var rightAnswers = [String]()
            let options = questionShortAnswer.options
            for option in options {
                rightAnswers.append(option)
            }
            if rightAnswers.contains(studentAnswer) {
                let alert = UIAlertController(title: NSLocalizedString("Correct!", comment: "pop up if answer right"), message: "", preferredStyle: .alert)
                alert.addAction(UIAlertAction(title: "OK", style: .cancel, handler: handleNavigation))
                self.present(alert, animated: true)
                SubmitButton.isEnabled = false
                SubmitButton.alpha = 0.4
            } else {
                var message = NSLocalizedString("There was no right answer.", comment: "pop up message if answer wrong and no answer right")
                if rightAnswers.count > 0 && rightAnswers[0] != "" {
                    message = NSLocalizedString("The right answer was for example: ", comment: "pop up message if answer wrong") + rightAnswers[0]
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
                    ClassroomActivityViewController.navQuestionShortAnswerViewController = nil
                    
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
                ClassroomActivityViewController.navQuestionShortAnswerViewController = nil
                
                navController.popViewController(animated: true)
            }
        } else {
            SubmitButton.isEnabled = false
            SubmitButton.alpha = 0.4
        }
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
}
