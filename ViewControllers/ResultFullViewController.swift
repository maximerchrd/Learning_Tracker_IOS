//
//  ResultFullViewController.swift
//  Learning_Tracker_IOS
//
//  Created by Maxime Richard on 15.05.18.
//  Copyright © 2018 Maxime Richard. All rights reserved.
//

import Foundation
import UIKit

class ResultFullViewController: UIViewController {
    
    @IBOutlet weak var questionTextView: UITextView!
    @IBOutlet weak var studentAnswerTextView: UITextView!
    @IBOutlet weak var allAnswersTextView: UITextView!
    @IBOutlet weak var dateLabel: UILabel!
    @IBOutlet weak var evaluationLabel: UILabel!
    @IBOutlet weak var ImageView: UIImageView!
    
    var questionText = ""
    var studentAnswerText = ""
    var date = ""
    var evaluation = ""
    var rightAnswers = [String]()
    var wrongAnswers = [String]()
    var questionType = ""
    var imagePath = ""
    
    override func viewDidLoad() {
        questionTextView.text = questionText
        studentAnswerTextView.text = studentAnswerText
        dateLabel.text = date
        evaluationLabel.text = evaluation
        

        var allAnswers = ""
        allAnswers += "Right Answer(s): \n"
        for answer in rightAnswers {
            allAnswers += answer + "\n"
        }
        allAnswers += "\nWrong Option(s): \n"
        for answer in wrongAnswers {
            allAnswers += answer + "\n"
        }
        
        allAnswersTextView.text = allAnswers
        

        //Display Picture
        let nsDocumentDirectory = FileManager.SearchPathDirectory.documentDirectory
        let nsUserDomainMask    = FileManager.SearchPathDomainMask.userDomainMask
        let paths               = NSSearchPathForDirectoriesInDomains(nsDocumentDirectory, nsUserDomainMask, true)
        if let dirPath          = paths.first {
            let imageURL = URL(fileURLWithPath: dirPath).appendingPathComponent(imagePath)
            ImageView.image    = UIImage(contentsOfFile: imageURL.path)
        }
    }
}

extension NSMutableAttributedString {
    @discardableResult func bold(_ text: String) -> NSMutableAttributedString {
        let attrs: [NSAttributedStringKey: Any] = [.font: UIFont(name: "AvenirNext-Medium", size: 12)!]
        let boldString = NSMutableAttributedString(string:text, attributes: attrs)
        append(boldString)
        
        return self
    }
    
    @discardableResult func normal(_ text: String) -> NSMutableAttributedString {
        let normal = NSAttributedString(string: text)
        append(normal)
        
        return self
    }
}
