//
// Created by Maxime Richard on 05.11.18.
// Copyright (c) 2018 Maxime Richard. All rights reserved.
//

class QuestionMultipleChoice {
    var id:Int64 = 0
    var subject = ""
    var level = ""
    var question = "none"
    var OptionsNumer = 0
    var NbCorrectAnswers = 0
    var image = ""
    var options = [String]()
    var Subjects = [String]()
    var Objectives = [String]()
    var timerSeconds = 0

    func initFromQuestionView (questionView: QuestionView) {
        self.id = Int64(questionView.id) ?? 0
        self.subject = questionView.subject
        self.level = questionView.level
        self.question = questionView.question
        self.OptionsNumer = questionView.optionsnumber
        self.NbCorrectAnswers = questionView.nb_CORRECT_ANS
        self.image = questionView.image
        self.options = [questionView.opt0, questionView.opt1, questionView.opt2, questionView.opt3, questionView.opt4,
                questionView.opt5, questionView.opt6, questionView.opt7, questionView.opt8, questionView.opt9]
        self.timerSeconds = questionView.timerSeconds
    }
}