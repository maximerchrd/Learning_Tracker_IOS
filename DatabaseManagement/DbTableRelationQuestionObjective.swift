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
    static let KEY_IDGLOBALOBJECTIVE = "IDGLOBALOBJECTIVE"
    static var DBPath = "NoName"
    
    static func createTable(DatabaseName: String) throws {
        DBPath = DatabaseName
        let dbQueue = try DatabaseQueue(path: DatabaseName)
        try dbQueue.write { db in
            try db.create(table: TABLE_NAME, ifNotExists: true) { t in
                t.column(KEY_ID, .integer).primaryKey()
                t.column(KEY_ID_GLOBAL, .integer).notNull()
                t.column(KEY_OBJECTIVE, .text).notNull()
                t.column(KEY_IDGLOBALOBJECTIVE, .text).notNull().unique(onConflict: .replace)
            }
        }
    }
    
    static func insertRelationQuestionObjective(questionID: Int64, objective: String) throws {
        let dbQueue = try DatabaseQueue(path: DBPath)
        try dbQueue.write { db in
            let idglobalobjective = String(questionID) + objective
            let relationQuestionObjective = RelationQuestionObjectiveRecord(idGlobal: questionID, objective: objective, idGlobalObjective: idglobalobjective)
            try relationQuestionObjective.insert(db)
        }
    }
}

class RelationQuestionObjectiveRecord : Record {
    var id: Int64?
    var idGlobal: Int64
    var objective: String
    var idGlobalObjective: String
    
    init(idGlobal: Int64, objective: String, idGlobalObjective:String) {
        self.idGlobal = idGlobal
        self.objective = objective
        self.idGlobalObjective = idGlobalObjective
        super.init()
    }
    
    required init(row: Row) {
        id = row[DbTableRelationQuestionObjective.KEY_ID]
        idGlobal = row[DbTableRelationQuestionObjective.KEY_ID_GLOBAL]
        objective = row[DbTableRelationQuestionObjective.KEY_OBJECTIVE]
        idGlobalObjective = row[DbTableRelationQuestionObjective.KEY_IDGLOBALOBJECTIVE]
        super.init()
    }
    
    override class var databaseTableName: String {
        return DbTableRelationQuestionObjective.TABLE_NAME
    }
    
    override func encode(to container: inout PersistenceContainer) {
        container[DbTableRelationQuestionObjective.KEY_ID] = id
        container[DbTableRelationQuestionObjective.KEY_ID_GLOBAL] = idGlobal
        container[DbTableRelationQuestionObjective.KEY_OBJECTIVE] = objective
        container[DbTableRelationQuestionObjective.KEY_IDGLOBALOBJECTIVE] = idGlobalObjective

    }
    
    override func didInsert(with rowID: Int64, for column: String?) {
        id = rowID
    }
}
