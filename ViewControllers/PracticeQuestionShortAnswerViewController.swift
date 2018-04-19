//
//  PracticeQuestionShortAnswerViewController.swift
//  Learning_Tracker_IOS
//
//  Created by Maxime Richard on 05.03.18.
//  Copyright © 2018 Maxime Richard. All rights reserved.
//

import Foundation
import UIKit

class PracticeQuestionShortAnswerViewController: UIViewController, UITextFieldDelegate {
    var questionShortAnswer: QuestionShortAnswer
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
    
    @IBOutlet weak var SubmitButton: UIButton!
    @IBOutlet weak var AnswerTextField: UITextField!
    @IBOutlet weak var QuestionTextView: UITextView!
    @IBOutlet weak var PictureView: UIImageView!
    
    required init?(coder aDecoder: NSCoder) {
        questionShortAnswer = QuestionShortAnswer()
        screenHeight = 0
        screenWidth = 0
        super.init(coder: aDecoder)
    }
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        let screenSize = UIScreen.main.bounds
        screenWidth = Float(screenSize.width)
        screenHeight = Float(screenSize.height)
        
        // Set question text
        QuestionTextView.text = questionShortAnswer.Question
        QuestionTextView.isEditable = false
        
        // Display picture
        let nsDocumentDirectory = FileManager.SearchPathDirectory.documentDirectory
        let nsUserDomainMask    = FileManager.SearchPathDomainMask.userDomainMask
        let paths               = NSSearchPathForDirectoriesInDomains(nsDocumentDirectory, nsUserDomainMask, true)
        if let dirPath          = paths.first {
            let imageURL = URL(fileURLWithPath: dirPath).appendingPathComponent(questionShortAnswer.Image)
            PictureView.image    = UIImage(contentsOfFile: imageURL.path)
        }
        originaImageWidth = PictureView.frame.width
        originalImageHeight = PictureView.frame.height
        originalImageX = PictureView.frame.minX
        originalImageY = PictureView.frame.minY
        newImageWidth = screenWidth
        newImageHeight = Float(originalImageHeight) / Float(originaImageWidth) * screenWidth
        newImageX = 0
        
        //add observer to push view when keyboard shows up
        NotificationCenter.default.addObserver(self, selector: #selector(QuestionShortAnswerViewController.keyboardWillShow), name: NSNotification.Name.UIKeyboardWillShow, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(QuestionShortAnswerViewController.keyboardWillHide), name: NSNotification.Name.UIKeyboardWillHide, object: nil)
        
        //set delegate to hide keyboard when return pressed
        self.AnswerTextField.delegate = self
    }
    
    @objc func keyboardWillShow(notification: NSNotification) {
        if let keyboardSize = (notification.userInfo?[UIKeyboardFrameBeginUserInfoKey] as? NSValue)?.cgRectValue {
            if self.view.frame.origin.y == 0{
                self.view.frame.origin.y -= keyboardSize.height
            }
        }
    }
    
    @objc func keyboardWillHide(notification: NSNotification) {
        if let keyboardSize = (notification.userInfo?[UIKeyboardFrameBeginUserInfoKey] as? NSValue)?.cgRectValue {
            if self.view.frame.origin.y != 0{
                self.view.frame.origin.y += keyboardSize.height
            }
        }
    }
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        AnswerTextField.endEditing(true)
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
        var evaluation = -1.0
        let studentAnswer = AnswerTextField.text!
        var rightAnswers = [String]()
        let options = questionShortAnswer.Options
        for option in options {
            rightAnswers.append(option)
        }
        if rightAnswers.contains(studentAnswer) {
            evaluation = 100.0
            let alert = UIAlertController(title: NSLocalizedString("Correct!", comment: "pop up if answer right"), message: "", preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "OK", style: .cancel, handler: nil))
            self.present(alert, animated: true)
            SubmitButton.isEnabled = false
            SubmitButton.alpha = 0.4
        } else {
            evaluation = 0.0
            var message = NSLocalizedString("There was no right answer.", comment: "pop up message if answer wrong and no answer right")
            if rightAnswers.count > 0 {
                message = NSLocalizedString("The right answer was for example: ", comment: "pop up message if answer wrong") + rightAnswers[0]
            }
            let alert = UIAlertController(title: NSLocalizedString("Incorrect :-(", comment: "pop up if answer wrong"), message: message, preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "OK", style: .cancel, handler: nil))
            self.present(alert, animated: true)
            SubmitButton.isEnabled = false
            SubmitButton.alpha = 0.4
        }
        do {
            try DbTableIndividualQuestionForResult.insertIndividualQuestionForResult(questionID: questionShortAnswer.ID, quantitativeEval: String(evaluation))
        } catch let error {
            print(error)
        }
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
}
