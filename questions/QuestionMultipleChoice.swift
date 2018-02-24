//
//  MultipleChoiceQuestion.swift
//  Learning_Tracker_IOS
//
//  Created by Maxime Richard on 24.02.18.
//  Copyright © 2018 Maxime Richard. All rights reserved.
//

import Foundation

class QuestionMultipleChoice {
    var ID = 0
    var Subject = ""
    var Level = ""
    var Question = "none"
    var OptionsNumer = 0
    var NbCorrectAnswers = 0
    var Image = ""
    var Options = [String]()
    var Trials = [Int]()
    var Subjects = [String]()
    var Objectives = [String]()
}
