//
//  DbTableLearningObjective.swift
//  Learning_Tracker_IOS
//
//  Created by Maxime Richard on 27.02.18.
//  Copyright © 2018 Maxime Richard. All rights reserved.
//

import Foundation
import GRDB

class DbTableLearningObjective {
    static let TABLE_NAME = "learning_objectives"
    static let KEY_ID = "id"
    static let KEY_ID_GLOBAL = "ID_OBJECTIVE_GLOBAL"
    static let KEY_OBJECTIVE = "OBJECTIVE"
    static let KEY_LEVEL_COGNITIVE_ABILITY = "LEVEL_COGNITIVE_ABILITY"
    static var DBPath = "NoName"
    
    static func createTable(DatabaseName: String) throws {
        DBPath = DatabaseName
        let dbQueue = try DatabaseQueue(path: DatabaseName)
        try dbQueue.inDatabase { db in
            try db.create(table: TABLE_NAME, ifNotExists: true) { t in
                t.column(KEY_ID, .integer).primaryKey()
                t.column(KEY_ID_GLOBAL, .integer).notNull()
                t.column(KEY_OBJECTIVE, .text).notNull().unique(onConflict: .ignore)
                t.column(KEY_LEVEL_COGNITIVE_ABILITY, .integer).notNull()
            }
        }
    }
    
    static func insertLearningObjective(questionID: Int, objective: String, levelCognitiveAbility: Int) throws {
        let dbQueue = try DatabaseQueue(path: DBPath)
        try dbQueue.inDatabase { db in
            let learningObjective = LearningObjectiveRecord(idGlobal: 2000000, objective: objective, levelCognitiveAbility: levelCognitiveAbility)
            try learningObjective.insert(db)
            let learningObjectiveToUpdate = try LearningObjectiveRecord.fetchOne(db, key: [KEY_OBJECTIVE: objective])
            if learningObjectiveToUpdate?.idGlobal == 2000000 {
                learningObjectiveToUpdate?.idGlobal = 2000000 + Int((learningObjectiveToUpdate?.id)!)
                try learningObjectiveToUpdate?.update(db)
            }
            try DbTableRelationQuestionObjective.insertRelationQuestionObjective(questionID: questionID, objective: objective)
        }
    }
    
    static func insertLearningObjective(objectiveID: Int, objective: String, levelCognitiveAbility: Int) throws {
        let dbQueue = try DatabaseQueue(path: DBPath)
        try dbQueue.inDatabase { db in
            let learningObjective = LearningObjectiveRecord(idGlobal: objectiveID, objective: objective, levelCognitiveAbility: levelCognitiveAbility)
            try learningObjective.insert(db)
        }
    }
    
    static func getResultsPerObjective(subject: String) throws -> [[String]] {
        let dbQueue = try DatabaseQueue(path: DBPath)
        var objectives = [String]()
        var results = [String]()
        var idQuestions = [Int]()
        var evaluationsForEachQuestion = [String]()
        var objectivesForEachQuestion = [[String]]()
        var resultsForEachObjective = [[String]]()
        
        if subject == "All" || subject == "All Subjects" {
            try dbQueue.inDatabase { db in
                let individualResultsRecord = try IndividualQuestionForResultRecord.fetchAll(db)
                for singleRecord in individualResultsRecord {
                    idQuestions.append(singleRecord.idGlobal)
                    evaluationsForEachQuestion.append(singleRecord.quantitativeEval)
                    var request = "SELECT * FROM " + DbTableRelationQuestionObjective.TABLE_NAME
                    request += " WHERE " + DbTableRelationQuestionObjective.KEY_ID_GLOBAL + "=" + String(singleRecord.idGlobal)
                    let objectivesOfCurrentQuestionRecords = try RelationQuestionObjectiveRecord.fetchAll(db, request)
                    var objectivesOfCurrentQuestion = [String]()
                    for singleObjective in objectivesOfCurrentQuestionRecords {
                        objectivesOfCurrentQuestion.append(singleObjective.objective)
                    }
                    objectivesForEachQuestion.append(objectivesOfCurrentQuestion)
                }
            }
        } else {
            try dbQueue.inDatabase { db in
                let individualResultsRecord = try IndividualQuestionForResultRecord.fetchAll(db)
                let questionsOfSubject = try DbTableRelationQuestionSubject.getQuestionsForSubject(subject: subject)
                for singleRecord in individualResultsRecord {
                    if questionsOfSubject.contains(singleRecord.idGlobal) {
                        idQuestions.append(singleRecord.idGlobal)
                        evaluationsForEachQuestion.append(singleRecord.quantitativeEval)
                        var request = "SELECT * FROM " + DbTableRelationQuestionObjective.TABLE_NAME
                        request += " WHERE " + DbTableRelationQuestionObjective.KEY_ID_GLOBAL + "=" + String(singleRecord.idGlobal)
                        let objectivesOfCurrentQuestionRecords = try RelationQuestionObjectiveRecord.fetchAll(db, request)
                        var objectivesOfCurrentQuestion = [String]()
                        for singleObjective in objectivesOfCurrentQuestionRecords {
                            objectivesOfCurrentQuestion.append(singleObjective.objective)
                        }
                        objectivesForEachQuestion.append(objectivesOfCurrentQuestion)
                    }
                }
            }
        }
        
        for i in 0..<evaluationsForEachQuestion.count {
            for j in 0..<objectivesForEachQuestion[i].count {
                if !objectives.contains(objectivesForEachQuestion[i][j]) {
                    objectives.append(objectivesForEachQuestion[i][j])
                    results.append(evaluationsForEachQuestion[i])
                } else {
                    results[objectives.index(of: objectivesForEachQuestion[i][j])!] += ";" + evaluationsForEachQuestion[i]
                }
                
            }
        }
        for i in 0..<results.count {
            let resultsString = results[i].components(separatedBy: ";")
            var numericResult = 0.0
            for result in resultsString {
                numericResult += Double(result) ?? 0.0
            }
            results[i] = String(numericResult / Double(resultsString.count))
        }
        let indexOfEmpty = objectives.index(of: "")
        if indexOfEmpty != nil {
            results.remove(at: indexOfEmpty!)
            objectives.remove(at: indexOfEmpty!)
        }
        let index = objectives.index(of: " ")
        if index != nil {
            results.remove(at: index!)
            objectives.remove(at: index!)
        }
        resultsForEachObjective.append(objectives)
        resultsForEachObjective.append(results)
        
        return resultsForEachObjective
    }
}

class LearningObjectiveRecord : Record {
    var id: Int64?
    var idGlobal: Int
    var objective: String
    var levelCognitiveAbility: Int
    
    init(idGlobal: Int, objective: String, levelCognitiveAbility: Int) {
        self.idGlobal = idGlobal
        self.objective = objective
        self.levelCognitiveAbility = levelCognitiveAbility
        super.init()
    }
    
    required init(row: Row) {
        id = row[DbTableLearningObjective.KEY_ID]
        self.idGlobal = row[DbTableLearningObjective.KEY_ID_GLOBAL]
        self.objective = row[DbTableLearningObjective.KEY_OBJECTIVE]
        self.levelCognitiveAbility = row[DbTableLearningObjective.KEY_LEVEL_COGNITIVE_ABILITY]
        super.init()
    }
    
    override class var databaseTableName: String {
        return DbTableLearningObjective.TABLE_NAME
    }
    
    override func encode(to container: inout PersistenceContainer) {
        container[DbTableLearningObjective.KEY_ID] = id
        container[DbTableLearningObjective.KEY_ID_GLOBAL] = idGlobal
        container[DbTableLearningObjective.KEY_OBJECTIVE] = objective
        container[DbTableLearningObjective.KEY_LEVEL_COGNITIVE_ABILITY] = levelCognitiveAbility
    }
    
    override func didInsert(with rowID: Int64, for column: String?) {
        id = rowID
    }
}
