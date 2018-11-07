//
// Created by Maxime Richard on 05.11.18.
// Copyright (c) 2018 Maxime Richard. All rights reserved.
//

class QuestionsTools {
    static func removeEmptyOptions(question: QuestionMultipleChoice) -> QuestionMultipleChoice {
        var i = 0
        for singleOption in question.options {
            if singleOption == " " {
                question.options.remove(at: i)
                i = i - 1
            }
            i = i + 1
        }
        return question
    }
}