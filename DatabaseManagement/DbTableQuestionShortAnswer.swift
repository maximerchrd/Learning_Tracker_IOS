//
//  DbTableQuestionShortAnswer.swift
//  Learning_Tracker_IOS
//
//  Created by Maxime Richard on 27.02.18.
//  Copyright © 2018 Maxime Richard. All rights reserved.
//

import Foundation
import GRDB

class DbTableQuestionShortAnswer {
    static let TABLE_QUESTIONSHORTANSWER_NAME = "short_answer_questions"
    static let KEY_ID = "ID_QUESTION"
    static let KEY_Level = "LEVEL"
    static let KEY_Question = "QUESTION"
    static let KEY_IMAGE_PATH = "IMAGE_PATH"
    static let KEY_ID_GLOBAL = "ID_GLOBAL"
    
    
    static var DBPath = "NoPATH"
    
    static func createTable(DatabasePath: String) throws {
        DBPath = DatabasePath
        let dbQueue = try DatabaseQueue(path: DatabasePath)
        try dbQueue.inDatabase { db in
            try db.create(table: TABLE_QUESTIONSHORTANSWER_NAME, ifNotExists: true) { t in
                t.column(KEY_ID, .integer).primaryKey()
                t.column(KEY_Level, .text).notNull()
                t.column(KEY_Question, .text).notNull()
                t.column(KEY_IMAGE_PATH, .text).notNull()
                t.column(KEY_ID_GLOBAL, .integer).notNull().unique(onConflict: .replace)
            }
        }
    }
    
    static func insertQuestionShortAnswer(Question: QuestionShortAnswer) throws {
        let dbQueue = try DatabaseQueue(path: DBPath)
        try dbQueue.inDatabase { db in
            let questionShortAnswer = QuestionShortAnswerRecord(questionShortAnswerArg: Question)
            try questionShortAnswer.insert(db)
            
            //insert options for question Short Answer
            //first remove answer options if we are overriding a question
            try DbTableAnswerOptions.deleteAnswerOptions(questionID: Question.ID)
            for option in Question.Options {
                try DbTableAnswerOptions.insertAnswerOption(questionID: Question.ID, option: option)
            }
            
            //if id attributed to a multiple choice question, delete this one
            let questionMultipleChoice = try QuestionMultipleChoiceRecord.fetchOne(db, "SELECT * FROM \(DbTableQuestionMultipleChoice.TABLE_QUESTIONMULTIPLECHOICE_NAME) WHERE \(DbTableQuestionMultipleChoice.KEY_ID_GLOBAL) = \(Question.ID)")
            if try questionMultipleChoice?.exists(db) ?? false {
                try questionMultipleChoice?.delete(db)
            }
        }
    }
    
    static func retrieveQuestionShortAnswerWithID (globalID: Int) throws -> QuestionShortAnswer {
        var questionShortAnswerToReturn = QuestionShortAnswer()
        var optionsArray = [String]()
        var questionShortAnswerRec = QuestionShortAnswerRecord(questionShortAnswerArg: questionShortAnswerToReturn)
        var answerOptionRecord = [AnswerOptionRecord]()
        do {
            let dbQueue = try DatabaseQueue(path: DBPath)
            try dbQueue.inDatabase { db in
                questionShortAnswerRec = (try QuestionShortAnswerRecord.fetchOne(db, key: [KEY_ID_GLOBAL: globalID])) ?? QuestionShortAnswerRecord(questionShortAnswerArg: QuestionShortAnswer())
                optionsArray = try DbTableAnswerOptions.retrieveAnswerOptions(questionID: questionShortAnswerRec.questionShortAnswer.ID)
            }
        } catch let error {
            print(error)
            print(error.localizedDescription)
        }
        questionShortAnswerToReturn = questionShortAnswerRec.questionShortAnswer
        questionShortAnswerToReturn.Options = optionsArray
        return questionShortAnswerToReturn
    }
    
    static func getAllQuestionsShortAnswersIDs () throws -> String {
        var questionShortAnswers = [QuestionShortAnswerRecord(questionShortAnswerArg: QuestionShortAnswer())]
        do {
            let dbQueue = try DatabaseQueue(path: DBPath)
            try dbQueue.inDatabase { db in
                questionShortAnswers = try QuestionShortAnswerRecord.fetchAll(db)
            }
        } catch let error {
            print(error)
            print(error.localizedDescription)
        }
        var questionIDs = ""
        for singleRecord in questionShortAnswers {
            questionIDs = questionIDs + String(singleRecord.questionShortAnswer.ID) + "|"
        }
        return questionIDs
    }
    
    static func getArrayOfAllQuestionsShortAnswersIDs () throws -> [String] {
        var questionShortAnswers = [QuestionShortAnswerRecord(questionShortAnswerArg: QuestionShortAnswer())]
        do {
            let dbQueue = try DatabaseQueue(path: DBPath)
            try dbQueue.inDatabase { db in
                questionShortAnswers = try QuestionShortAnswerRecord.fetchAll(db)
            }
        } catch let error {
            print(error)
            print(error.localizedDescription)
        }
        var questionIDs = [String]()
        for singleRecord in questionShortAnswers {
            questionIDs.append(String(singleRecord.questionShortAnswer.ID))
        }
        return questionIDs
    }
}

class QuestionShortAnswerRecord : Record {
    var questionShortAnswer: QuestionShortAnswer
    var id: Int64?
    
    init(questionShortAnswerArg: QuestionShortAnswer) {
        questionShortAnswer = questionShortAnswerArg
        super.init()
    }
    
    required init(row: Row) {
        questionShortAnswer = QuestionShortAnswer()
        id = row[DbTableQuestionShortAnswer.KEY_ID]
        questionShortAnswer.Level = row[DbTableQuestionShortAnswer.KEY_Level]
        questionShortAnswer.Question = row[DbTableQuestionShortAnswer.KEY_Question]
        questionShortAnswer.Image = row[DbTableQuestionShortAnswer.KEY_IMAGE_PATH]
        questionShortAnswer.ID = row[DbTableQuestionShortAnswer.KEY_ID_GLOBAL]
        super.init()
    }
    
    override class var databaseTableName: String {
        return DbTableQuestionShortAnswer.TABLE_QUESTIONSHORTANSWER_NAME
    }
    
    override func encode(to container: inout PersistenceContainer) {
        container[DbTableQuestionShortAnswer.KEY_ID] = id
        container[DbTableQuestionShortAnswer.KEY_Level] = questionShortAnswer.Level
        container[DbTableQuestionShortAnswer.KEY_Question] = questionShortAnswer.Question
        container[DbTableQuestionShortAnswer.KEY_IMAGE_PATH] = questionShortAnswer.Image
        container[DbTableQuestionShortAnswer.KEY_ID_GLOBAL] = questionShortAnswer.ID
    }
    
    override func didInsert(with rowID: Int64, for column: String?) {
        id = rowID
    }
}
