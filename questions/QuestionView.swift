//
//  MultipleChoiceQuestion.swift
//  Learning_Tracker_IOS
//
//  Created by Maxime Richard on 24.02.18.
//  Copyright © 2018 Maxime Richard. All rights reserved.
//
class QuestionView: Decodable {
    var id = ""
    var subject = ""
    var level = ""
    var question = "none"
    var opt0 = ""
    var opt1 = ""
    var opt2 = ""
    var opt3 = ""
    var opt4 = ""
    var opt5 = ""
    var opt6 = ""
    var opt7 = ""
    var opt8 = ""
    var opt9 = ""
    var nb_CORRECT_ANS = 0
    var image = ""
    var type = 0
    var qcm_MUID: String? = ""
    var qcm_UPD_TMS: Int64? = 0
    var optionsnumber = 0
    var timerSeconds = 0

    static let multipleChoice = 0
    static let shortAnswer = 1
    static let test = 2
}
