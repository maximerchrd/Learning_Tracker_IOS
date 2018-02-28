//
//  DbTableRelationQuestionObjective.swift
//  Learning_Tracker_IOS
//
//  Created by Maxime Richard on 27.02.18.
//  Copyright © 2018 Maxime Richard. All rights reserved.
//

import Foundation
import GRDB

class DbTableRelationQuestionObjective {
    static let TABLE_NAME = "question_objective_relation"
    static let KEY_ID = "id"
    static let KEY_ID_GLOBAL = "ID_GLOBAL"
    static let KEY_OBJECTIVE = "OBJECTIVE"
    static var DBPath = "NoName"
    
    static func createTable(DatabaseName: String) throws {
        DBPath = DatabaseName
        let dbQueue = try DatabaseQueue(path: DatabaseName)
        try dbQueue.inDatabase { db in
            try db.create(table: TABLE_NAME, ifNotExists: true) { t in
                t.column(KEY_ID, .integer).primaryKey()
                t.column(KEY_ID_GLOBAL, .integer).notNull()
                t.column(KEY_OBJECTIVE, .text).notNull()
            }
        }
    }
    
    static func insertRelationQuestionObjective(questionID: Int, objective: String) throws {
        let dbQueue = try DatabaseQueue(path: DBPath)
        try dbQueue.inDatabase { db in
            let relationQuestionObjective = RelationQuestionObjectiveRecord(idGlobal: questionID, objective: objective)
            try relationQuestionObjective.insert(db)
        }
    }
}

class RelationQuestionObjectiveRecord : Record {
    var id: Int64?
    var idGlobal: Int
    var objective: String
    
    init(idGlobal: Int, objective: String) {
        self.idGlobal = idGlobal
        self.objective = objective
        super.init()
    }
    
    required init(row: Row) {
        id = row[DbTableRelationQuestionObjective.KEY_ID]
        idGlobal = row[DbTableRelationQuestionObjective.KEY_ID_GLOBAL]
        objective = row[DbTableRelationQuestionObjective.KEY_OBJECTIVE]
        super.init()
    }
    
    override class var databaseTableName: String {
        return DbTableRelationQuestionObjective.DBPath
    }
    
    override func encode(to container: inout PersistenceContainer) {
        container[DbTableRelationQuestionObjective.KEY_ID] = id
        container[DbTableRelationQuestionObjective.KEY_ID_GLOBAL] = idGlobal
        container[DbTableRelationQuestionObjective.KEY_OBJECTIVE] = objective
    }
    
    override func didInsert(with rowID: Int64, for column: String?) {
        id = rowID
    }
}
