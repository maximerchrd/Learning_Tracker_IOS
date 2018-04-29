//
//  QuestionMultipleChoiceViewController.swift
//  Learning_Tracker_IOS
//
//  Created by Maxime Richard on 24.02.18.
//  Copyright © 2018 Maxime Richard. All rights reserved.
//

import Foundation
import UIKit

class QuestionMultipleChoiceViewController: UIViewController {
    var isSyncTest: Bool
    var isCorrection: Bool
    var questionMultipleChoice: QuestionMultipleChoice
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
    var checkBoxArray: [CheckBox]
    var stackView: UIStackView!
    var scrollViewWidth: CGFloat
    var scrollViewHeight: CGFloat
    var scrollViewX: CGFloat
    var scrollViewY: CGFloat
    var scrollPosition: CGFloat
    var directCorrection = 0
    var isBackButton = true
    
    @IBOutlet weak var QuestionTextView: UITextView!
    @IBOutlet weak var PictureView: UIImageView!
    @IBOutlet weak var OptionsScrollView: UIScrollView!
    @IBOutlet weak var SubmitButton: UIButton!
    
    required init?(coder aDecoder: NSCoder) {
        questionMultipleChoice = QuestionMultipleChoice()
        screenHeight = 0
        screenWidth = 0
        checkBoxArray = [CheckBox]()
        scrollViewWidth = 0
        scrollViewHeight = 0
        scrollViewX = 0
        scrollViewY = 0
        scrollPosition = 0
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
        QuestionTextView.text = questionMultipleChoice.Question
        QuestionTextView.isEditable = false
        QuestionTextView.sizeToFit()
        
        
        // Display picture
        let nsDocumentDirectory = FileManager.SearchPathDirectory.documentDirectory
        let nsUserDomainMask    = FileManager.SearchPathDomainMask.userDomainMask
        let paths               = NSSearchPathForDirectoriesInDomains(nsDocumentDirectory, nsUserDomainMask, true)
        if let dirPath          = paths.first {
            let imageURL = URL(fileURLWithPath: dirPath).appendingPathComponent(questionMultipleChoice.Image)
            PictureView.image    = UIImage(contentsOfFile: imageURL.path)
        }
        //get the answer options to adapt the size of the imageview
        questionMultipleChoice.removeEmptyOptions()
        var optionsArray = questionMultipleChoice.Options
        originaImageWidth = PictureView.frame.width
        originalImageHeight = PictureView.frame.height
        originalImageX = PictureView.frame.minX
        originalImageY = PictureView.frame.minY
        newImageWidth = screenWidth
        newImageHeight = Float(originalImageHeight) / Float(originaImageWidth) * screenWidth
        newImageX = 0
        
        // DISPLAY OPTIONS
        //First implements stackview inside scrollview
        scrollViewWidth = OptionsScrollView.frame.size.width
        scrollViewHeight = OptionsScrollView.frame.size.height
        scrollViewX = OptionsScrollView.frame.minX
        scrollViewY = OptionsScrollView.frame.minY
        OptionsScrollView.translatesAutoresizingMaskIntoConstraints = false
        self.view.addSubview(OptionsScrollView)
        
        self.view.addConstraints(NSLayoutConstraint.constraints(withVisualFormat: "H:|[OptionsScrollView]|", options: .alignAllCenterX, metrics: nil, views: ["OptionsScrollView": OptionsScrollView]))
        self.view.addConstraints(NSLayoutConstraint.constraints(withVisualFormat: "V:|[OptionsScrollView]|", options: .alignAllCenterX, metrics: nil, views: ["OptionsScrollView": OptionsScrollView]))
        
        
        stackView = UIStackView()
        stackView.translatesAutoresizingMaskIntoConstraints = false
        stackView.axis = .vertical
        OptionsScrollView.addSubview(stackView)
        
        OptionsScrollView.addConstraints(NSLayoutConstraint.constraints(withVisualFormat: "H:|[stackView]|", options: NSLayoutFormatOptions.alignAllCenterX, metrics: nil, views: ["stackView": stackView]))
        OptionsScrollView.addConstraints(NSLayoutConstraint.constraints(withVisualFormat: "V:|[stackView]", options: NSLayoutFormatOptions.alignAllCenterX, metrics: nil, views: ["stackView": stackView]))
        
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
            checkBox.widthAnchor.constraint(equalToConstant: scrollViewWidth - checkBox.checkedImage.size.width * 1.3).isActive = true
            checkBox.contentEdgeInsets = UIEdgeInsetsMake(0,10,0,0)
            
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
        
        if isCorrection {
            SubmitButton.setTitle(NSLocalizedString("OK", comment: "OK button"), for: .normal)
        }
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        //set scrolling size
        OptionsScrollView.frame = CGRect(x: scrollViewX, y: scrollViewY, width: scrollViewWidth, height: scrollViewHeight)
        OptionsScrollView.contentSize = CGSize(width: stackView.frame.width, height: stackView.frame.height)
    }
    
    override func viewWillLayoutSubviews() {
        super.viewWillLayoutSubviews()
        scrollPosition = OptionsScrollView.contentOffset.y
    }
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        OptionsScrollView.frame = CGRect(x: scrollViewX, y: scrollViewY, width: scrollViewWidth, height: scrollViewHeight)
        OptionsScrollView.contentSize = CGSize(width: stackView.frame.width, height: stackView.frame.height)
        OptionsScrollView.contentOffset.y = scrollPosition
    }
    override func viewWillDisappear(_ animated: Bool) {
        if isBackButton {
            ClassroomActivityViewController.navQuestionShortAnswerViewController = nil
            ClassroomActivityViewController.navQuestionMultipleChoiceViewController = self
        }
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
        //first send answer to server
        if !isCorrection {
            var answers = ""
            var answersArray = [String]()
            for singleCheckBox in checkBoxArray {
                if singleCheckBox.isChecked {
                    answers += (singleCheckBox.titleLabel?.text)! + "|||"
                    answersArray.append((singleCheckBox.titleLabel?.text)!)
                }
            }
            if AppDelegate.isFirstLayer {
                AppDelegate.wifiCommunicationSingleton?.sendAnswerToServer(answer: answers, globalID: questionMultipleChoice.ID, questionType: "ANSW0")
            } else {
                AppDelegate.wifiCommunicationSingleton?.multipeerCommunication.sendAnswerToServer(answer: answers, globalID: questionMultipleChoice.ID, questionType: "ANSW0")
            }
        }
        
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
            var options = questionMultipleChoice.Options
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
            } else {
                SubmitButton.isEnabled = false
                SubmitButton.alpha = 0.4
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
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }    
}
