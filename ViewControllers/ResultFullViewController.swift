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
    
    var questionText = ""
    var studentAnswerText = ""
    var allAnswersText = ""
    var date = ""
    var evaluation = ""
    
    override func viewDidLoad() {
        questionTextView.text = questionText
        studentAnswerTextView.text = studentAnswerText
        allAnswersTextView.text = allAnswersText
        dateLabel.text = date
        evaluationLabel.text = evaluation
    }
}
