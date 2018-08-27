//
//  DbTableRelationTestObjective.swift
//  Learning_Tracker_IOS
//
//  Created by Maxime Richard on 06.04.18.
//  Copyright © 2018 Maxime Richard. All rights reserved.
//

import Foundation
import GRDB

class DbTableRelationTestObjective {
    static let TABLE_NAME = "test_objective_relation"
    static let KEY_ID = "id"
    static let KEY_ID_TEST = "ID_TEST"
    static let KEY_ID_OBJECTIVE = "ID_OBJECTIVE"
    static var DBPath = "NoName"
    
    static func createTable(DatabaseName: String) throws {
        DBPath = DatabaseName
        let dbQueue = try DatabaseQueue(path: DatabaseName)
        try dbQueue.write { db in
            try db.create(table: TABLE_NAME, ifNotExists: true) { t in
                t.column(KEY_ID, .integer).primaryKey()
                t.column(KEY_ID_TEST, .integer).notNull()
                t.column(KEY_ID_OBJECTIVE, .integer).notNull()
                t.uniqueKey([KEY_ID_TEST, KEY_ID_OBJECTIVE], onConflict: .ignore)
            }
        }
    }
    
    static func insertRelationTestObjective(idTest: Int64, idObjective: Int64) throws {
        let dbQueue = try DatabaseQueue(path: DBPath)
        try dbQueue.write { db in
            let relationTestObjective = RelationTestObjectiveRecord(idTest: idTest, idObjective: idObjective)
            try relationTestObjective.insert(db)
        }
    }
}

class RelationTestObjectiveRecord : Record {
    var id: Int64?
    var idTest: Int64
    var idObjective: Int64
    
    init(idTest: Int64, idObjective:Int64) {
        self.idTest = idTest
        self.idObjective = idObjective
        super.init()
    }
    
    required init(row: Row) {
        id = row[DbTableRelationTestObjective.KEY_ID]
        idTest = row[DbTableRelationTestObjective.KEY_ID_TEST]
        idObjective = row[DbTableRelationTestObjective.KEY_ID_OBJECTIVE]
        super.init()
    }
    
    override class var databaseTableName: String {
        return DbTableRelationTestObjective.TABLE_NAME
    }
    
    override func encode(to container: inout PersistenceContainer) {
        container[DbTableRelationTestObjective.KEY_ID] = id
        container[DbTableRelationTestObjective.KEY_ID_TEST] = idTest
        container[DbTableRelationTestObjective.KEY_ID_OBJECTIVE] = idObjective
    }
    
    override func didInsert(with rowID: Int64, for column: String?) {
        id = rowID
    }
}
