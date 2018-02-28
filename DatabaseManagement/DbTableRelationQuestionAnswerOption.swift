//
//  DbTableRelationQuestionAnswerOption.swift
//  Learning_Tracker_IOS
//
//  Created by Maxime Richard on 27.02.18.
//  Copyright © 2018 Maxime Richard. All rights reserved.
//

import Foundation
import GRDB

class DbTableRelationQuestionAnswerOption {
    static let TABLE_NAME = "question_answeroption_relation"
    static let KEY_ID = "id"
    static let KEY_ID_GLOBAL = "ID_GLOBAL"
    static let KEY_OPTION = "ID_ANSWEROPTION_GLOBAL"
    static var DBPath = "NoName"
    
    static func createTable(DatabaseName: String) throws {
        DBPath = DatabaseName
        let dbQueue = try DatabaseQueue(path: DatabaseName)
        try dbQueue.inDatabase { db in
            try db.create(table: TABLE_NAME, ifNotExists: true) { t in
                t.column(KEY_ID, .integer).primaryKey()
                t.column(KEY_ID_GLOBAL, .integer).notNull()
                t.column(KEY_OPTION, .text).notNull()
            }
        }
    }
    
    static func insertRelationQuestionAnswerOption(questionID: Int, option: String) throws {
        let dbQueue = try DatabaseQueue(path: DBPath)
        try dbQueue.inDatabase { db in
            let relationQuestionAnswerOption = RelationQuestionAnswerOptionRecord(idGlobal: questionID, option: option)
            try relationQuestionAnswerOption.insert(db)
        }
    }
}

class RelationQuestionAnswerOptionRecord : Record {
    var id: Int64?
    var idGlobal: Int
    var option: String
    
    init(idGlobal: Int, option: String) {
        self.idGlobal = idGlobal
        self.option = option
        super.init()
    }
    
    required init(row: Row) {
        id = row[DbTableRelationQuestionAnswerOption.KEY_ID]
        idGlobal = row[DbTableRelationQuestionAnswerOption.KEY_ID_GLOBAL]
        option = row[DbTableRelationQuestionAnswerOption.KEY_OPTION]
        super.init()
    }
    
    override class var databaseTableName: String {
        return DbTableRelationQuestionAnswerOption.DBPath
    }
    
    override func encode(to container: inout PersistenceContainer) {
        container[DbTableRelationQuestionAnswerOption.KEY_ID] = id
        container[DbTableRelationQuestionAnswerOption.KEY_ID_GLOBAL] = idGlobal
        container[DbTableRelationQuestionAnswerOption.KEY_OPTION] = option
    }
    
    override func didInsert(with rowID: Int64, for column: String?) {
        id = rowID
    }
}
