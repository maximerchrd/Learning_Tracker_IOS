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
    static let KEY_TRIAL0 = "TRIAL0"
    static let KEY_TRIAL1 = "TRIAL0"
    static let KEY_TRIAL2 = "TRIAL0"
    static let KEY_TRIAL3 = "TRIAL0"
    static let KEY_TRIAL4 = "TRIAL0"
    static let KEY_TRIAL5 = "TRIAL0"
    static let KEY_TRIAL6 = "TRIAL0"
    static let KEY_TRIAL7 = "TRIAL0"
    static let KEY_TRIAL8 = "TRIAL0"
    static let KEY_TRIAL9 = "TRIAL0"
    static let KEY_NB_CORRECT_ANS = "NB_CORRECT_ANS"
    static let KEY_IMAGE_PATH = "IMAGE_PATH"
    static let KEY_ID_GLOBAL = "ID_GLOBAL"
    

    static var DBPath = "NoPATH"
    
    static func createTable(DatabasePath: String) throws {
        DBPath = DatabasePath
        let dbQueue = try DatabaseQueue(path: DatabasePath)
        try dbQueue.inDatabase { db in
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
            }
        }
    }
    
    static func insertQuestionMultipleChoice(Question: QuestionMultipleChoice) throws {
        let dbQueue = try DatabaseQueue(path: DBPath)
        try dbQueue.inDatabase { db in
            let questionMultChoice = QuestionMultipleChoiceRecord(questionMultipleChoiceArg: Question)
            try questionMultChoice.insert(db)
            
            //if id attributed to a short answer question, delete this one
            let questionShortAnswer = try QuestionShortAnswerRecord.fetchOne(db, "SELECT * FROM \(DbTableQuestionShortAnswer.TABLE_QUESTIONSHORTANSWER_NAME) WHERE \(DbTableQuestionShortAnswer.KEY_ID_GLOBAL) = \(Question.ID)")
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
            try dbQueue.inDatabase { db in
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
            try dbQueue.inDatabase { db in
                questionMultipleChoice = try QuestionMultipleChoiceRecord.fetchAll(db)
            }
        } catch let error {
            print(error)
            print(error.localizedDescription)
        }
        var questionIDs = ""
        for singleRecord in questionMultipleChoice {
            questionIDs = questionIDs + String(singleRecord.questionMultipleChoice.ID) + "|"
        }
        return questionIDs
    }
    
    static func getArrayOfAllQuestionsMultipleChoiceIDs () throws -> [String] {
        var questionMultipleChoice = [QuestionMultipleChoiceRecord(questionMultipleChoiceArg: QuestionMultipleChoice())]
        do {
            let dbQueue = try DatabaseQueue(path: DBPath)
            try dbQueue.inDatabase { db in
                questionMultipleChoice = try QuestionMultipleChoiceRecord.fetchAll(db)
            }
        } catch let error {
            print(error)
            print(error.localizedDescription)
        }
        var questionIDs = [String]()
        for singleRecord in questionMultipleChoice {
            questionIDs.append(String(singleRecord.questionMultipleChoice.ID))
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
        questionMultipleChoice.Level = row[DbTableQuestionMultipleChoice.KEY_Level]
        questionMultipleChoice.Question = row[DbTableQuestionMultipleChoice.KEY_Question]
        questionMultipleChoice.Options.append(row[DbTableQuestionMultipleChoice.KEY_OPTION0])
        questionMultipleChoice.Options.append(row[DbTableQuestionMultipleChoice.KEY_OPTION1])
        questionMultipleChoice.Options.append(row[DbTableQuestionMultipleChoice.KEY_OPTION2])
        questionMultipleChoice.Options.append(row[DbTableQuestionMultipleChoice.KEY_OPTION3])
        questionMultipleChoice.Options.append(row[DbTableQuestionMultipleChoice.KEY_OPTION4])
        questionMultipleChoice.Options.append(row[DbTableQuestionMultipleChoice.KEY_OPTION5])
        questionMultipleChoice.Options.append(row[DbTableQuestionMultipleChoice.KEY_OPTION6])
        questionMultipleChoice.Options.append(row[DbTableQuestionMultipleChoice.KEY_OPTION7])
        questionMultipleChoice.Options.append(row[DbTableQuestionMultipleChoice.KEY_OPTION8])
        questionMultipleChoice.Options.append(row[DbTableQuestionMultipleChoice.KEY_OPTION9])
        questionMultipleChoice.NbCorrectAnswers = row[DbTableQuestionMultipleChoice.KEY_NB_CORRECT_ANS]
        questionMultipleChoice.Image = row[DbTableQuestionMultipleChoice.KEY_IMAGE_PATH]
        questionMultipleChoice.ID = row[DbTableQuestionMultipleChoice.KEY_ID_GLOBAL]
        super.init()
    }
    
    override class var databaseTableName: String {
        return DbTableQuestionMultipleChoice.TABLE_QUESTIONMULTIPLECHOICE_NAME
    }
    
    override func encode(to container: inout PersistenceContainer) {
        container[DbTableQuestionMultipleChoice.KEY_IDquestionMultipleChoice] = id
        container[DbTableQuestionMultipleChoice.KEY_Level] = questionMultipleChoice.Level
        container[DbTableQuestionMultipleChoice.KEY_Question] = questionMultipleChoice.Question
        container[DbTableQuestionMultipleChoice.KEY_OPTION0] = questionMultipleChoice.Options[0]
        container[DbTableQuestionMultipleChoice.KEY_OPTION1] = questionMultipleChoice.Options[1]
        container[DbTableQuestionMultipleChoice.KEY_OPTION2] = questionMultipleChoice.Options[2]
        container[DbTableQuestionMultipleChoice.KEY_OPTION3] = questionMultipleChoice.Options[3]
        container[DbTableQuestionMultipleChoice.KEY_OPTION4] = questionMultipleChoice.Options[4]
        container[DbTableQuestionMultipleChoice.KEY_OPTION5] = questionMultipleChoice.Options[5]
        container[DbTableQuestionMultipleChoice.KEY_OPTION6] = questionMultipleChoice.Options[6]
        container[DbTableQuestionMultipleChoice.KEY_OPTION7] = questionMultipleChoice.Options[7]
        container[DbTableQuestionMultipleChoice.KEY_OPTION8] = questionMultipleChoice.Options[8]
        container[DbTableQuestionMultipleChoice.KEY_OPTION9] = questionMultipleChoice.Options[9]
        container[DbTableQuestionMultipleChoice.KEY_NB_CORRECT_ANS] = questionMultipleChoice.NbCorrectAnswers
        container[DbTableQuestionMultipleChoice.KEY_IMAGE_PATH] = questionMultipleChoice.Image
        container[DbTableQuestionMultipleChoice.KEY_ID_GLOBAL] = questionMultipleChoice.ID
    }
    
    override func didInsert(with rowID: Int64, for column: String?) {
        id = rowID
    }
}
