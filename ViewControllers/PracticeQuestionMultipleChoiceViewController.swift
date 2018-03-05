//
//  PracticeQuestionMultipleChoiceViewController.swift
//  Learning_Tracker_IOS
//
//  Created by Maxime Richard on 05.03.18.
//  Copyright © 2018 Maxime Richard. All rights reserved.
//

import Foundation
import UIKit

class PracticeQuestionMultipleChoiceViewController: UIViewController {
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
    var wifiCommunication: WifiCommunication?
    var checkBoxArray: [CheckBox]
    
    @IBOutlet weak var SubmitAnswerButton: UIButton!
    @IBOutlet weak var QuestionLabel: UILabel!
    @IBOutlet weak var PictureView: UIImageView!
    
    required init?(coder aDecoder: NSCoder) {
        questionMultipleChoice = QuestionMultipleChoice()
        screenHeight = 0
        screenWidth = 0
        checkBoxArray = [CheckBox]()
        super.init(coder: aDecoder)
    }
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        let screenSize = UIScreen.main.bounds
        screenWidth = Float(screenSize.width)
        screenHeight = Float(screenSize.height)
        
        // Set question text
        QuestionLabel.text = questionMultipleChoice.Question
        
        // Display picture
        let nsDocumentDirectory = FileManager.SearchPathDirectory.documentDirectory
        let nsUserDomainMask    = FileManager.SearchPathDomainMask.userDomainMask
        let paths               = NSSearchPathForDirectoriesInDomains(nsDocumentDirectory, nsUserDomainMask, true)
        if let dirPath          = paths.first {
            let imageURL = URL(fileURLWithPath: dirPath).appendingPathComponent(questionMultipleChoice.Image)
            PictureView.image    = UIImage(contentsOfFile: imageURL.path)
        }
        originaImageWidth = PictureView.frame.width
        originalImageHeight = PictureView.frame.height
        originalImageX = PictureView.frame.minX
        originalImageY = PictureView.frame.minY
        newImageWidth = screenWidth
        newImageHeight = Float(originalImageHeight) / Float(originaImageWidth) * screenWidth
        newImageX = 0
        
        // Display options
        questionMultipleChoice.removeEmptyOptions()
        var optionsArray = questionMultipleChoice.Options
        optionsArray = shuffle(arrayArg: optionsArray)
        var i = 1
        for singleOption in optionsArray {
            let computedX = Int(screenWidth / 15)
            let computedY = Int(Float(PictureView.frame.maxY) + (screenHeight / 15) * Float(i))
            let computedWidth = Int(screenWidth * 0.9)
            let computedHeight = Int(screenHeight / 20)
            let checkBox = CheckBox(frame: CGRect(x: computedX, y: computedY, width: computedWidth, height: computedHeight))
            checkBox.isChecked = false
            checkBox.setTitle(singleOption, for: .normal)
            checkBox.addTarget(checkBox, action: #selector(checkBox.buttonClicked(sender:)), for: .touchUpInside)
            checkBox.setTitleColor(.black, for: .normal)
            checkBox.titleLabel?.lineBreakMode = NSLineBreakMode.byWordWrapping
            checkBox.contentHorizontalAlignment = .left
            self.view.addSubview(checkBox)
            checkBoxArray.append(checkBox)
            i = i + 1
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
        var answers = ""
        var answersArray = [String]()
        for singleCheckBox in checkBoxArray {
            if singleCheckBox.isChecked {
                answers += (singleCheckBox.titleLabel?.text)! + "|||"
                answersArray.append((singleCheckBox.titleLabel?.text)!)
            }
        }
        var evaluation = -1.0
        var options = questionMultipleChoice.Options
        var rightAnswers = [String]()
        for i in 0..<questionMultipleChoice.NbCorrectAnswers {
            rightAnswers.append(options[i])
        }
        if rightAnswers.containsSameElements(as: answersArray) {
            evaluation = 100.0
            let alert = UIAlertController(title: "Correct!", message: "", preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "OK", style: .cancel, handler: nil))
            self.present(alert, animated: true)
            SubmitAnswerButton.isEnabled = false
            SubmitAnswerButton.alpha = 0.4
        } else {
            evaluation = 0.0
            var message = "The right answer was: "
            for answer in rightAnswers {
                message += answer + "; "
            }
            let alert = UIAlertController(title: "Incorrect :-(", message: message, preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "OK", style: .cancel, handler: nil))
            self.present(alert, animated: true)
            SubmitAnswerButton.isEnabled = false
            SubmitAnswerButton.alpha = 0.4
        }
        do {
            try DbTableIndividualQuestionForResult.insertIndividualQuestionForResult(questionID: questionMultipleChoice.ID, quantitativeEval: String(evaluation))
        } catch let error {
            print(error)
        }
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    
}

extension Array where Element: Comparable {
    func containsSameElements(as other: [Element]) -> Bool {
        return self.count == other.count && self.sorted() == other.sorted()
    }
}
