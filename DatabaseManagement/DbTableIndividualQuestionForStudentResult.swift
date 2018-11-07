//
//  DbTableIndividualQuestionForStudentResult.swift
//  Learning_Tracker_IOS
//
//  Created by Maxime Richard on 27.02.18.
//  Copyright © 2018 Maxime Richard. All rights reserved.
//

import Foundation
import GRDB

class DbTableIndividualQuestionForResult {
    static let TABLE_NAME = "individual_question_for_result"
    static let KEY_ID = "id"
    static let KEY_ID_GLOBAL = "ID_GLOBAL"
    static let KEY_DATE = "DATE"
    static let KEY_ANSWERS = "ANSWERS"
    static let KEY_TIME_FOR_SOLVING = "TIME_FOR_SOLVING"
    static let KEY_QUESTION_WEIGHT = "QUESTION_WEIGHT"
    static let KEY_EVAL_TYPE = "EVAL_TYPE"
    static let KEY_QUANTITATIVE_EVAL = "QUANTITATIVE_EVAL"
    static let KEY_QUALITATIVE_EVAL = "QUALITATIVE_EVAL"
    static let KEY_TEST_BELONGING = "TEST_BELONGING"
    static let KEY_WEIGHTS_OF_ANSWERS = "WEIGHTS_OF_ANSWERS"
    static let KEY_TYPE = "TYPE"        //0: Question Multiple Choice; 1: Question Short Answer; 2: Objective, 3: Test
    static var DBPath = "NoName"
    
    static func createTable(DatabaseName: String) throws {
        DBPath = DatabaseName
        let dbQueue = try DatabaseQueue(path: DatabaseName)
        try dbQueue.write { db in
            try db.create(table: TABLE_NAME, ifNotExists: true) { t in
                t.column(KEY_ID, .integer).primaryKey()
                t.column(KEY_ID_GLOBAL, .integer).notNull()
                t.column(KEY_DATE, .text).notNull()
                t.column(KEY_ANSWERS, .text).notNull()
                t.column(KEY_TIME_FOR_SOLVING, .text).notNull()
                t.column(KEY_QUESTION_WEIGHT, .double).notNull()
                t.column(KEY_EVAL_TYPE, .text).notNull()
                t.column(KEY_QUANTITATIVE_EVAL, .text).notNull()
                t.column(KEY_QUALITATIVE_EVAL, .text).notNull()
                t.column(KEY_TEST_BELONGING, .text).notNull()
                t.column(KEY_WEIGHTS_OF_ANSWERS, .text).notNull()
                t.column(KEY_TYPE, .integer)
            }
        }
    }
    
    static func insertIndividualQuestionForResult(questionID: Int64, date: String, answers: String, timeForSolving: String, questionWeight: Double, evalType: String, quantitativeEval: String, qualitativeEval: String, testBelonging: String, weightsOfAnswers: String) throws {
        let dbQueue = try DatabaseQueue(path: DBPath)
        try dbQueue.write { db in
            let individualQuestionForResult = IndividualQuestionForResultRecord(idGlobal: questionID, date: date, answers: answers, timeForSolving: timeForSolving, questionWeight: questionWeight, evalType: evalType, quantitativeEval: quantitativeEval, qualitativeEval: qualitativeEval, testBelonging: testBelonging, weightsOfAnswers: weightsOfAnswers)
            try individualQuestionForResult.insert(db)
        }
    }
    static func insertIndividualQuestionForResult(questionID: Int64, quantitativeEval: String, testBelonging: String = "none", type: Int = 2) throws {
        let dbQueue = try DatabaseQueue(path: DBPath)
        let date = Date()
        let formatter = DateFormatter()
        formatter.dateFormat = "dd/MM/yyyy"
        let dateNow = formatter.string(from: date)
        print(dateNow)
        try dbQueue.write { db in
            let individualQuestionForResult = IndividualQuestionForResultRecord(idGlobal: questionID, date: dateNow, answers: "none", timeForSolving: "none", questionWeight: -1, evalType: "none", quantitativeEval: quantitativeEval, qualitativeEval: "none", testBelonging: testBelonging, weightsOfAnswers: "none", type: type)
            try individualQuestionForResult.insert(db)
        }
    }
    
    static func insertIndividualQuestionForResult(questionID: Int64, quantitativeEval: String, qualitativeEval: String, testBelonging: String = "none", type: Int = 2, timeForSolving: String) throws {
        let dbQueue = try DatabaseQueue(path: DBPath)
        let date = Date()
        let formatter = DateFormatter()
        formatter.dateFormat = "dd/MM/yyyy"
        let dateNow = formatter.string(from: date)
        print(dateNow)
        try dbQueue.write { db in
            let individualQuestionForResult = IndividualQuestionForResultRecord(idGlobal: questionID, date: dateNow, answers: "none", timeForSolving: timeForSolving, questionWeight: -1, evalType: "none", quantitativeEval: quantitativeEval, qualitativeEval: qualitativeEval, testBelonging: testBelonging, weightsOfAnswers: "none", type: type)
            try individualQuestionForResult.insert(db)
        }
    }
    
    static func insertIndividualQuestionForResult(questionID: Int64, answer: String, quantitativeEval: String) throws {
        let dbQueue = try DatabaseQueue(path: DBPath)
        let date = Date()
        let formatter = DateFormatter()
        formatter.dateFormat = "dd/MM/yyyy"
        let dateNow = formatter.string(from: date)
        print(dateNow)
        try dbQueue.write { db in
            let individualQuestionForResult = IndividualQuestionForResultRecord(idGlobal: questionID, date: dateNow, answers: answer, timeForSolving: "none", questionWeight: -1, evalType: "none", quantitativeEval: quantitativeEval, qualitativeEval: "none", testBelonging: "none", weightsOfAnswers: "none")
            try individualQuestionForResult.insert(db)
        }
    }
    
    static func setEvalForQuestionAndStudentIDs (eval: String, idQuestion: String) throws {
        let dbQueue = try DatabaseQueue(path: DBPath)
        try dbQueue.write { db in
            var individualQuestionForResult = try IndividualQuestionForResultRecord.fetchAll(db, "SELECT * FROM " + TABLE_NAME + " WHERE " + KEY_ID + "=(SELECT MAX (" + KEY_ID + ") FROM (SELECT * FROM '" + TABLE_NAME + "') WHERE ID_GLOBAL='" + idQuestion + "')")
            individualQuestionForResult[0].quantitativeEval = eval
            try individualQuestionForResult[0].update(db)
        }
    }
    
    static func getResultsForSubject (subject: String) throws -> [[String]] {
        var results = [[String]]()
        let relSubj = DbTableRelationQuestionSubject.TABLE_NAME
        let subj = DbTableRelationQuestionSubject.KEY_SUBJECT
        let questid = DbTableRelationQuestionSubject.KEY_ID_GLOBAL
        let dbQueue = try DatabaseQueue(path: DBPath)
        try dbQueue.read { db in
            var request = "SELECT * FROM " + TABLE_NAME
            if subject != "All" {
                request += " INNER JOIN \(relSubj) ON \(TABLE_NAME).\(KEY_ID_GLOBAL) = \(relSubj).\(questid) WHERE \(relSubj).\(subj) = '\(subject)'"
            }
            var resultRecord = try IndividualQuestionForResultRecord.fetchAll(db, request)
            for i in 0..<resultRecord.count {
                results.append([String]())
                if resultRecord[i].type == 3 {
                    results[i].append(resultRecord[i].testBelonging)
                    results[i].append(resultRecord[i].answers)
                    results[i].append(String(resultRecord[i].quantitativeEval))
                    results[i].append(resultRecord[i].date)
                    results[i].append(resultRecord[i].qualitativeEval + ".png")
                    results[i].append(String(resultRecord[i].type))
                } else {
                    let questionMultipleChoice = try DbTableQuestionMultipleChoice.retrieveQuestionMultipleChoiceWithID(globalID: resultRecord[i].idGlobal)
                    var questionShortAnswer: QuestionShortAnswer?
                    questionShortAnswer = nil
                    if questionMultipleChoice.question != "none" {
                        results[i].append(questionMultipleChoice.question)
                    } else {
                        questionShortAnswer = try DbTableQuestionShortAnswer.retrieveQuestionShortAnswerWithID(globalID: resultRecord[i].idGlobal)
                        results[i].append(questionShortAnswer!.Question)
                    }
                    results[i].append(resultRecord[i].answers)
                    results[i].append(String(resultRecord[i].quantitativeEval))
                    results[i].append(resultRecord[i].date)
                    if questionShortAnswer == nil {
                        results[i].append(questionMultipleChoice.image)
                        results[i].append("QMC")
                        results[i].append(String(questionMultipleChoice.NbCorrectAnswers))
                        for option in questionMultipleChoice.options {
                            results[i].append(option)
                        }
                    } else {
                        results[i].append(questionShortAnswer!.Image)
                        results[i].append("SHRTAQ")
                        for option in questionShortAnswer!.Options {
                            results[i].append(option)
                        }
                    }
                }
            }
        }
        return results
    }
    
    static func getResultsPerObjectiveForCertificativeTest (test: String) throws -> [[String]] {
        let dbQueue = try DatabaseQueue(path: DBPath)
        var objectives = [String]()
        var results = [String]()
        var idQuestions = [Int64]()
        var resultsForEachObjective = [[String]]()
        
        try dbQueue.read { db in
            let request = "SELECT * FROM " + TABLE_NAME + " WHERE " + KEY_TYPE + " = ? AND " + KEY_TEST_BELONGING + " = ?"
            
            var resultRecord = try IndividualQuestionForResultRecord.fetchAll(db, request, arguments: [2, test])
            for i in 0..<resultRecord.count {
                idQuestions.append(resultRecord[i].idGlobal)
                results.append(resultRecord[i].quantitativeEval)
            }
            
            for idQuestion in idQuestions {
                objectives.append(DbTableLearningObjective.getObjectiveNameFromID(objectiveID: idQuestion))
            }
        }
        resultsForEachObjective.append(objectives)
        resultsForEachObjective.append(results)
        
        return resultsForEachObjective
    }
    
    static func getLatestEvaluationForQuestionID (questionID: Int64) throws -> Double {
        var result = 0.0
        let dbQueue = try DatabaseQueue(path: DBPath)
        try dbQueue.read { db in
            var request = "SELECT * FROM " + TABLE_NAME
            request += " WHERE " + KEY_ID + "=(SELECT MAX (" + KEY_ID + ") FROM " + TABLE_NAME + " WHERE ID_GLOBAL='" + String(questionID) + "')"
            var resultRecord = try IndividualQuestionForResultRecord.fetchAll(db, request)
            if resultRecord.count > 0 {
                result = Double(resultRecord[0].quantitativeEval) ?? -1
            }
        }
        return result
    }
}

class IndividualQuestionForResultRecord : Record {
    var id: Int64?
    var idGlobal: Int64
    var date: String
    var answers: String
    var timeForSolving: String
    var questionWeight: Double
    var evalType: String
    var quantitativeEval: String
    var qualitativeEval: String
    var testBelonging: String
    var weightsOfAnswers: String
    var type: Int
    
    init(idGlobal: Int64, date: String, answers: String, timeForSolving: String, questionWeight: Double, evalType: String, quantitativeEval: String, qualitativeEval: String, testBelonging: String, weightsOfAnswers: String, type: Int = -1) {
        self.idGlobal = idGlobal
        self.date = date
        self.answers = answers
        self.timeForSolving = timeForSolving
        self.questionWeight = questionWeight
        self.evalType = evalType
        self.quantitativeEval = quantitativeEval
        self.qualitativeEval = qualitativeEval
        self.testBelonging = testBelonging
        self.weightsOfAnswers = weightsOfAnswers
        self.type = type
        super.init()
    }
    
    required init(row: Row) {
        self.id = row[DbTableIndividualQuestionForResult.KEY_ID]
        self.idGlobal = row[DbTableIndividualQuestionForResult.KEY_ID_GLOBAL]
        self.date = row[DbTableIndividualQuestionForResult.KEY_DATE]
        self.answers = row[DbTableIndividualQuestionForResult.KEY_ANSWERS]
        self.timeForSolving = row[DbTableIndividualQuestionForResult.KEY_TIME_FOR_SOLVING]
        self.questionWeight = row[DbTableIndividualQuestionForResult.KEY_QUESTION_WEIGHT]
        self.evalType = row[DbTableIndividualQuestionForResult.KEY_EVAL_TYPE]
        self.quantitativeEval = row[DbTableIndividualQuestionForResult.KEY_QUANTITATIVE_EVAL]
        self.qualitativeEval = row[DbTableIndividualQuestionForResult.KEY_QUALITATIVE_EVAL]
        self.testBelonging = row[DbTableIndividualQuestionForResult.KEY_TEST_BELONGING]
        self.weightsOfAnswers = row[DbTableIndividualQuestionForResult.KEY_WEIGHTS_OF_ANSWERS]
        self.type = row[DbTableIndividualQuestionForResult.KEY_TYPE]
        super.init()
    }
    
    override class var databaseTableName: String {
        return DbTableIndividualQuestionForResult.TABLE_NAME
    }
    
    override func encode(to container: inout PersistenceContainer) {
        container[DbTableIndividualQuestionForResult.KEY_ID] = id
        container[DbTableIndividualQuestionForResult.KEY_ID_GLOBAL] = idGlobal
        container[DbTableIndividualQuestionForResult.KEY_DATE] = date
        container[DbTableIndividualQuestionForResult.KEY_ANSWERS] = answers
        container[DbTableIndividualQuestionForResult.KEY_TIME_FOR_SOLVING] = timeForSolving
        container[DbTableIndividualQuestionForResult.KEY_QUESTION_WEIGHT] = questionWeight
        container[DbTableIndividualQuestionForResult.KEY_EVAL_TYPE] = evalType
        container[DbTableIndividualQuestionForResult.KEY_QUANTITATIVE_EVAL] = quantitativeEval
        container[DbTableIndividualQuestionForResult.KEY_QUALITATIVE_EVAL] = qualitativeEval
        container[DbTableIndividualQuestionForResult.KEY_TEST_BELONGING] = testBelonging
        container[DbTableIndividualQuestionForResult.KEY_WEIGHTS_OF_ANSWERS] = weightsOfAnswers
        container[DbTableIndividualQuestionForResult.KEY_TYPE] = type
    }
    
    override func didInsert(with rowID: Int64, for column: String?) {
        id = rowID
    }
}
