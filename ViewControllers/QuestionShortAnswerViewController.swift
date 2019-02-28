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
    var screenHeight: CGFloat
    var screenWidth: CGFloat
    var scrollViewWidth: CGFloat = 0
    var scrollViewHeight: CGFloat = 0
    var scrollViewX: CGFloat = 0
    var scrollViewY: CGFloat = 0
    var scrollPosition: CGFloat = 0
    var directCorrection = 0
    var isBackButton = true
    var startTime: TimeInterval = 0.0
    var firstLabel:UILabel = UILabel()
    
    var stackView: UIStackView!
    var AnswerTextField: UITextField!
    var PictureView: UIImageView!
    @IBOutlet weak var scrollView: UIScrollView!
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
        screenWidth = screenSize.width
        screenHeight = screenSize.height
        
        //First implements stackview inside scrollview
        scrollViewWidth = scrollView.frame.size.width
        scrollViewHeight = scrollView.frame.size.height
        scrollViewX = scrollView.frame.minX
        scrollViewY = scrollView.frame.minY
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        self.view.addSubview(scrollView)
        
        self.view.addConstraints(NSLayoutConstraint.constraints(withVisualFormat: "H:|[scrollView]|", options: .alignAllCenterX, metrics: nil, views: ["scrollView": scrollView]))
        self.view.addConstraints(NSLayoutConstraint.constraints(withVisualFormat: "V:|[scrollView]|", options: .alignAllCenterX, metrics: nil, views: ["scrollView": scrollView]))
        
        
        stackView = UIStackView()
        stackView.translatesAutoresizingMaskIntoConstraints = false
        stackView.axis = .vertical
        stackView.spacing = 15
        scrollView.addSubview(stackView)
        
        scrollView.addConstraints(NSLayoutConstraint.constraints(withVisualFormat: "H:|[stackView]|", options: NSLayoutFormatOptions.alignAllCenterX, metrics: nil, views: ["stackView": stackView]))
        scrollView.addConstraints(NSLayoutConstraint.constraints(withVisualFormat: "V:|[stackView]", options: NSLayoutFormatOptions.alignAllCenterX, metrics: nil, views: ["stackView": stackView]))
        
        // Set question text
        let label = UILabel()
        label.widthAnchor.constraint(equalToConstant: screenWidth).isActive = true
        label.attributedText = justifyLabel(str: questionShortAnswer.question)
        label.numberOfLines = 0
        label.sizeToFit()
        stackView.addArrangedSubview(label)
        
        // Display picture
        if questionShortAnswer.image != "none" {
            let nsDocumentDirectory = FileManager.SearchPathDirectory.documentDirectory
            let nsUserDomainMask    = FileManager.SearchPathDomainMask.userDomainMask
            let paths               = NSSearchPathForDirectoriesInDomains(nsDocumentDirectory, nsUserDomainMask, true)
            if let dirPath          = paths.first {
                let imageURL = URL(fileURLWithPath: dirPath).appendingPathComponent(questionShortAnswer.image)
                let image = UIImage(contentsOfFile: imageURL.path) ?? UIImage()
                let ratio = image.size.height / image.size.width
                let PictureView = UIImageView()
                PictureView.image = UIImage(contentsOfFile: imageURL.path) ?? UIImage()
                PictureView.contentMode = .scaleAspectFit
                PictureView.heightAnchor.constraint(equalToConstant: screenWidth * ratio).isActive = true
                stackView.addArrangedSubview(PictureView)
            }
        }
        
        AnswerTextField = UITextField(frame: CGRect(x: 0, y: 0, width: screenWidth, height: 40))
        AnswerTextField.borderStyle = UITextBorderStyle.roundedRect
        AnswerTextField.autocorrectionType = UITextAutocorrectionType.no
        stackView.addArrangedSubview(AnswerTextField)
        //set delegate to hide keyboard when return pressed
        self.AnswerTextField.delegate = self
        
        NotificationCenter.default.addObserver(self, selector: #selector(QuestionShortAnswerViewController.keyboardWillShow), name: NSNotification.Name.UIKeyboardWillShow, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(QuestionShortAnswerViewController.keyboardWillHide), name: NSNotification.Name.UIKeyboardWillHide, object: nil)
        
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
        let transferable = ClientToServerTransferable(prefix: ClientToServerTransferable.activeIdPrefix,
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
    
    @objc func keyboardWillShow(notification: NSNotification) {
        if let keyboardSize = (notification.userInfo?[UIKeyboardFrameBeginUserInfoKey] as? NSValue)?.cgRectValue {
            if self.view.frame.origin.y == 0 {
                self.view.frame.origin.y -= keyboardSize.height
            }
        }
    }
    
    @objc func keyboardWillHide(notification: NSNotification) {
        if self.view.frame.origin.y != 0 {
            self.view.frame.origin.y = 0
        }
    }
    
    override func viewDidAppear(_ animated: Bool) {
        //dismiss keyboard if we are coming back to question
        self.view.endEditing(true)
        
        scrollView.frame = CGRect(x: scrollViewX, y: scrollViewY, width: scrollViewWidth, height: scrollViewHeight)
        scrollView.contentSize = CGSize(width: stackView.frame.width, height: stackView.frame.height)
        
        if SubmitButton.isEnabled {
            self.firstLabel.isHidden = false
        }
    }
    
    override func viewWillLayoutSubviews() {
        super.viewWillLayoutSubviews()
        scrollPosition = scrollView.contentOffset.y
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        scrollView.frame = CGRect(x: scrollViewX, y: scrollViewY, width: scrollViewWidth, height: scrollViewHeight)
        scrollView.contentSize = CGSize(width: stackView.frame.width, height: stackView.frame.height)
        scrollView.contentOffset.y = scrollPosition
        scrollView.flashScrollIndicators()
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
    
    @IBAction func submitAnswerButtonTouched(_ sender: Any) {
        //stop timer
        let timeInterval = Date.timeIntervalSinceReferenceDate - startTime
        
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
    
    func justifyLabel(str: String) -> NSAttributedString
    {
        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.alignment = NSTextAlignment.justified
        let attributedString = NSAttributedString(string: str,
                                                  attributes: [
                                                    NSAttributedStringKey.paragraphStyle: paragraphStyle,
                                                    NSAttributedStringKey.baselineOffset: NSNumber(value: 0)
            ])
        
        return attributedString
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
