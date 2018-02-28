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
            var learningObjectiveToUpdate = try LearningObjectiveRecord.fetchOne(db, key: [KEY_ID_GLOBAL: 2000000])
            learningObjectiveToUpdate?.idGlobal = 2000000 + Int((learningObjectiveToUpdate?.id)!)
            try learningObjectiveToUpdate?.update(db)
        }
    }
    
    static func getResultsPerObjective(objective: String) -> [[String]] {
        //to implement after relations are implemented
        
        return [[String]]()
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
        return DbTableLearningObjective.DBPath
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
