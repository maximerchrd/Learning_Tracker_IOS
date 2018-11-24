//
//  DbTableQuestionMultipleChoice.swift
//  Learning_Tracker_IOS
//
//  Created by Maxime Richard on 25.02.18.
//  Copyright © 2018 Maxime Richard. All rights reserved.
//

import Foundation
import GRDB

class DbTableQuestionMultipleChoice {
    static let TABLE_QUESTIONMULTIPLECHOICE_NAME = "multiple_choice_questions"
    static let KEY_IDquestionMultipleChoice = "ID_QUESTION"
    static let KEY_Level = "LEVEL"
    static let KEY_Question = "QUESTION"
    static let KEY_OPTION0 = "OPTION0"
    static let KEY_OPTION1 = "OPTION1"
    static let KEY_OPTION2 = "OPTION2"
    static let KEY_OPTION3 = "OPTION3"
    static let KEY_OPTION4 = "OPTION4"
    static let KEY_OPTION5 = "OPTION5"
    static let KEY_OPTION6 = "OPTION6"
    static let KEY_OPTION7 = "OPTION7"
    static let KEY_OPTION8 = "OPTION8"
    static let KEY_OPTION9 = "OPTION9"
    static let KEY_NB_CORRECT_ANS = "NB_CORRECT_ANS"
    static let KEY_IMAGE_PATH = "IMAGE_PATH"
    static let KEY_ID_GLOBAL = "ID_GLOBAL"
    static let KEY_TIMER_SECONDS = "TIMER_SECONDS"
    

    static var DBPath = "NoPATH"
    
    static func createTable(DatabasePath: String) throws {
        DBPath = DatabasePath
        let dbQueue = try DatabaseQueue(path: DatabasePath)
        try dbQueue.write { db in
            try db.create(table: TABLE_QUESTIONMULTIPLECHOICE_NAME, ifNotExists: true) { t in
                t.column(KEY_IDquestionMultipleChoice, .integer).primaryKey()
                t.column(KEY_Level, .text).notNull()
                t.column(KEY_Question, .text).notNull()
                t.column(KEY_OPTION0, .text).notNull()
                t.column(KEY_OPTION1, .text).notNull()
                t.column(KEY_OPTION2, .text).notNull()
                t.column(KEY_OPTION3, .text).notNull()
                t.column(KEY_OPTION4, .text).notNull()
                t.column(KEY_OPTION5, .text).notNull()
                t.column(KEY_OPTION6, .text).notNull()
                t.column(KEY_OPTION7, .text).notNull()
                t.column(KEY_OPTION8, .text).notNull()
                t.column(KEY_OPTION9, .text).notNull()
                t.column(KEY_NB_CORRECT_ANS, .text).notNull()
                t.column(KEY_IMAGE_PATH, .text).notNull()
                t.column(KEY_ID_GLOBAL, .integer).notNull().unique(onConflict: .replace)
                t.column(KEY_TIMER_SECONDS, .integer)
            }
        }
    }
    
    static func insertQuestionMultipleChoice(Question: QuestionMultipleChoice) throws {
        let dbQueue = try DatabaseQueue(path: DBPath)
        try dbQueue.write { db in
            let questionMultChoice = QuestionMultipleChoiceRecord(questionMultipleChoiceArg: Question)
            try questionMultChoice.insert(db)
            
            //if id attributed to a short answer question, delete this one
            let questionShortAnswer = try QuestionShortAnswerRecord.fetchOne(db, "SELECT * FROM \(DbTableQuestionShortAnswer.TABLE_QUESTIONSHORTANSWER_NAME) WHERE \(DbTableQuestionShortAnswer.KEY_ID_GLOBAL) = \(Question.id)")
            if try questionShortAnswer?.exists(db) ?? false {
                try questionShortAnswer?.delete(db)
            }
        }
    }
    
    static func retrieveQuestionMultipleChoiceWithID (globalID: Int64) throws -> QuestionMultipleChoice {
        var questionMultipleChoiceToReturn = QuestionMultipleChoice()
        var questionMultipleChoice = QuestionMultipleChoiceRecord(questionMultipleChoiceArg: questionMultipleChoiceToReturn)
        do {
            let dbQueue = try DatabaseQueue(path: DBPath)
            try dbQueue.read { db in
                questionMultipleChoice = (try QuestionMultipleChoiceRecord.fetchOne(db, key: [KEY_ID_GLOBAL: globalID])) ?? QuestionMultipleChoiceRecord(questionMultipleChoiceArg: QuestionMultipleChoice())
            }
        } catch let error {
            print(error)
            print(error.localizedDescription)
        }
        questionMultipleChoiceToReturn = questionMultipleChoice.questionMultipleChoice
        return questionMultipleChoiceToReturn
    }
    
    static func getAllQuestionsMultipleChoiceIDs () throws -> String {
        var questionMultipleChoice = [QuestionMultipleChoiceRecord(questionMultipleChoiceArg: QuestionMultipleChoice())]
        do {
            let dbQueue = try DatabaseQueue(path: DBPath)
            try dbQueue.read { db in
                questionMultipleChoice = try QuestionMultipleChoiceRecord.fetchAll(db)
            }
        } catch let error {
            print(error)
            print(error.localizedDescription)
        }
        var questionIDs = ""
        for singleRecord in questionMultipleChoice {
            questionIDs = questionIDs + String(singleRecord.questionMultipleChoice.id) + "|"
        }
        return questionIDs
    }
    
    static func getArrayOfAllQuestionsMultipleChoiceIDs () throws -> [String] {
        var questionMultipleChoice = [QuestionMultipleChoiceRecord(questionMultipleChoiceArg: QuestionMultipleChoice())]
        do {
            let dbQueue = try DatabaseQueue(path: DBPath)
            try dbQueue.read { db in
                questionMultipleChoice = try QuestionMultipleChoiceRecord.fetchAll(db)
            }
        } catch let error {
            print(error)
            print(error.localizedDescription)
        }
        var questionIDs = [String]()
        for singleRecord in questionMultipleChoice {
            questionIDs.append(String(singleRecord.questionMultipleChoice.id))
        }
        return questionIDs
    }
}

class QuestionMultipleChoiceRecord : Record {
    var questionMultipleChoice: QuestionMultipleChoice
    var id: Int64?
    
    init(questionMultipleChoiceArg: QuestionMultipleChoice) {
        questionMultipleChoice = questionMultipleChoiceArg
        super.init()
    }
    
    required init(row: Row) {
        questionMultipleChoice = QuestionMultipleChoice()
        id = row[DbTableQuestionMultipleChoice.KEY_IDquestionMultipleChoice]
        questionMultipleChoice.level = row[DbTableQuestionMultipleChoice.KEY_Level]
        questionMultipleChoice.question = row[DbTableQuestionMultipleChoice.KEY_Question]
        questionMultipleChoice.options.append(row[DbTableQuestionMultipleChoice.KEY_OPTION0])
        questionMultipleChoice.options.append(row[DbTableQuestionMultipleChoice.KEY_OPTION1])
        questionMultipleChoice.options.append(row[DbTableQuestionMultipleChoice.KEY_OPTION2])
        questionMultipleChoice.options.append(row[DbTableQuestionMultipleChoice.KEY_OPTION3])
        questionMultipleChoice.options.append(row[DbTableQuestionMultipleChoice.KEY_OPTION4])
        questionMultipleChoice.options.append(row[DbTableQuestionMultipleChoice.KEY_OPTION5])
        questionMultipleChoice.options.append(row[DbTableQuestionMultipleChoice.KEY_OPTION6])
        questionMultipleChoice.options.append(row[DbTableQuestionMultipleChoice.KEY_OPTION7])
        questionMultipleChoice.options.append(row[DbTableQuestionMultipleChoice.KEY_OPTION8])
        questionMultipleChoice.options.append(row[DbTableQuestionMultipleChoice.KEY_OPTION9])
        questionMultipleChoice.NbCorrectAnswers = row[DbTableQuestionMultipleChoice.KEY_NB_CORRECT_ANS]
        questionMultipleChoice.image = row[DbTableQuestionMultipleChoice.KEY_IMAGE_PATH]
        questionMultipleChoice.id = row[DbTableQuestionMultipleChoice.KEY_ID_GLOBAL]
        questionMultipleChoice.timerSeconds = row[DbTableQuestionShortAnswer.KEY_TIMER_SECONDS]
        super.init()
    }
    
    override class var databaseTableName: String {
        return DbTableQuestionMultipleChoice.TABLE_QUESTIONMULTIPLECHOICE_NAME
    }
    
    override func encode(to container: inout PersistenceContainer) {
        container[DbTableQuestionMultipleChoice.KEY_IDquestionMultipleChoice] = id
        container[DbTableQuestionMultipleChoice.KEY_Level] = questionMultipleChoice.level
        container[DbTableQuestionMultipleChoice.KEY_Question] = questionMultipleChoice.question
        container[DbTableQuestionMultipleChoice.KEY_OPTION0] = questionMultipleChoice.options[0]
        container[DbTableQuestionMultipleChoice.KEY_OPTION1] = questionMultipleChoice.options[1]
        container[DbTableQuestionMultipleChoice.KEY_OPTION2] = questionMultipleChoice.options[2]
        container[DbTableQuestionMultipleChoice.KEY_OPTION3] = questionMultipleChoice.options[3]
        container[DbTableQuestionMultipleChoice.KEY_OPTION4] = questionMultipleChoice.options[4]
        container[DbTableQuestionMultipleChoice.KEY_OPTION5] = questionMultipleChoice.options[5]
        container[DbTableQuestionMultipleChoice.KEY_OPTION6] = questionMultipleChoice.options[6]
        container[DbTableQuestionMultipleChoice.KEY_OPTION7] = questionMultipleChoice.options[7]
        container[DbTableQuestionMultipleChoice.KEY_OPTION8] = questionMultipleChoice.options[8]
        container[DbTableQuestionMultipleChoice.KEY_OPTION9] = questionMultipleChoice.options[9]
        container[DbTableQuestionMultipleChoice.KEY_NB_CORRECT_ANS] = questionMultipleChoice.NbCorrectAnswers
        container[DbTableQuestionMultipleChoice.KEY_IMAGE_PATH] = questionMultipleChoice.image
        container[DbTableQuestionMultipleChoice.KEY_ID_GLOBAL] = questionMultipleChoice.id
        container[DbTableQuestionShortAnswer.KEY_TIMER_SECONDS] = questionMultipleChoice.timerSeconds
    }
    
    override func didInsert(with rowID: Int64, for column: String?) {
        id = rowID
    }
}
