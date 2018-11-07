//
//  QuestionShortAnswer.swift
//  Learning_Tracker_IOS
//
//  Created by Maxime Richard on 27.02.18.
//  Copyright © 2018 Maxime Richard. All rights reserved.
//

import Foundation

class QuestionShortAnswer {
    var id:Int64 = 0
    var subject = ""
    var level = ""
    var question = "none"
    var image = ""
    var options = [String]()
    var subjects = [String]()
    var objectives = [String]()

    func initFromQuestionView (questionView: QuestionView) {
        self.id = Int64(questionView.id) ?? 0
        self.subject = questionView.subject
        self.level = questionView.level
        self.question = questionView.question
        self.image = questionView.image
        self.options = [questionView.opt0, questionView.opt1, questionView.opt2, questionView.opt3, questionView.opt4,
                        questionView.opt5, questionView.opt6, questionView.opt7, questionView.opt8, questionView.opt9]
    }
}
