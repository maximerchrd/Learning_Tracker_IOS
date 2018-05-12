//
//  DbTableRelationQuestionQuestion.swift
//  Learning_Tracker_IOS
//
//  Created by Maxime Richard on 08.05.18.
//  Copyright © 2018 Maxime Richard. All rights reserved.
//

import Foundation
import GRDB

class DbTableRelationQuestionQuestion {
    static let TABLE_NAME = "question_question_relation"
    static let KEY_ID = "id"
    static let KEY_ID_GLOBAL_1 = "ID_GLOBAL_1"
    static let KEY_ID_GLOBAL_2 = "ID_GLOBAL_2"
    static let KEY_TEST = "TEST"
    static let KEY_CONDITION = "CONDITION"
    static var DBPath = "NoName"
    
    static func createTable(DatabaseName: String) throws {
        DBPath = DatabaseName
        let dbQueue = try DatabaseQueue(path: DatabaseName)
        try dbQueue.inDatabase { db in
            try db.create(table: TABLE_NAME, ifNotExists: true) { t in
                t.column(KEY_ID, .integer).primaryKey()
                t.column(KEY_ID_GLOBAL_1, .integer).notNull()
                t.column(KEY_ID_GLOBAL_2, .text).notNull()
                t.column(KEY_TEST, .text).notNull()
                t.column(KEY_CONDITION, .text).notNull()
            }
        }
    }
    
    static func insertRelationQuestionQuestion(idGlobal1: String, idGlobal2: String, test: String, condition: String) {
        do {
            let dbQueue = try DatabaseQueue(path: DBPath)
            try dbQueue.inDatabase { db in
                let relationQuestionQuestion = RelationQuestionQuestionRecord(idGlobal1: idGlobal1, idGlobal2: idGlobal2, test: test, condition: condition)
                try relationQuestionQuestion.insert(db)
            }
        }catch let error {
                print(error)
            }
    }
    
    static func getTestMapForTest(test: String) -> [[String]] {
        do {
            let dbQueue = try DatabaseQueue(path: DBPath)
            var testMap = [[String]]()
            let request = "SELECT * FROM " + DbTableRelationQuestionQuestion.TABLE_NAME + " WHERE " + DbTableRelationQuestionQuestion.KEY_TEST + " = '" + test + "';"
            var relationQuestionQuestionRecords = [RelationQuestionQuestionRecord]()
            try dbQueue.inDatabase { db in
                relationQuestionQuestionRecords = try RelationQuestionQuestionRecord.fetchAll(db, request)
            }
            for singleRecord in relationQuestionQuestionRecords {
                var relation = [String]()
                relation.append(singleRecord.idGlobal1)
                relation.append(singleRecord.idGlobal2)
                relation.append(singleRecord.condition)
                testMap.append(relation)
            }

            return testMap
        } catch let error {
            print(error)
            return [[String]]()
        }
    }
}

class RelationQuestionQuestionRecord : Record {
    var id: Int64?
    var idGlobal1: String
    var idGlobal2: String
    var test: String
    var condition: String
    
    init(idGlobal1: String, idGlobal2: String, test: String, condition: String) {
        self.idGlobal1 = idGlobal1
        self.idGlobal2 = idGlobal2
        self.test = test
        self.condition = condition
        super.init()
    }
    
    required init(row: Row) {
        id = row[DbTableRelationQuestionQuestion.KEY_ID]
        idGlobal1 = row[DbTableRelationQuestionQuestion.KEY_ID_GLOBAL_1]
        idGlobal2 = row[DbTableRelationQuestionQuestion.KEY_ID_GLOBAL_2]
        test = row[DbTableRelationQuestionQuestion.KEY_TEST]
        condition = row[DbTableRelationQuestionQuestion.KEY_CONDITION]
        super.init()
    }
    
    override class var databaseTableName: String {
        return DbTableRelationQuestionQuestion.TABLE_NAME
    }
    
    override func encode(to container: inout PersistenceContainer) {
        container[DbTableRelationQuestionQuestion.KEY_ID] = id
        container[DbTableRelationQuestionQuestion.KEY_ID_GLOBAL_1] = idGlobal1
        container[DbTableRelationQuestionQuestion.KEY_ID_GLOBAL_2] = idGlobal2
        container[DbTableRelationQuestionQuestion.KEY_TEST] = test
        container[DbTableRelationQuestionQuestion.KEY_CONDITION] = condition
        
    }
    
    override func didInsert(with rowID: Int64, for column: String?) {
        id = rowID
    }
}
