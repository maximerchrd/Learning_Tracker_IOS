//
//  DbTableAnswerOptions.swift
//  Learning_Tracker_IOS
//
//  Created by Maxime Richard on 27.02.18.
//  Copyright © 2018 Maxime Richard. All rights reserved.
//

import Foundation
import GRDB

class DbTableAnswerOptions {
    static let TABLE_NAME = "answer_options"
    static let KEY_ID = "id"
    static let KEY_ID_GLOBAL = "ID_ANSWEROPTION_GLOBAL"
    static let KEY_OPTION = "OPTION"
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
    
    static func insertAnswerOption(questionID: Int, option: String) throws {
        let dbQueue = try DatabaseQueue(path: DBPath)
        try dbQueue.inDatabase { db in
            let answerOption = AnswerOptionRecord(idGlobal: questionID, option: option)
            try answerOption.insert(db)
        }
    }
}

class AnswerOptionRecord : Record {
    var id: Int64?
    var idGlobal: Int
    var option: String
    
    init(idGlobal: Int, option: String) {
        self.idGlobal = idGlobal
        self.option = option
        super.init()
    }
    
    required init(row: Row) {
        id = row[DbTableAnswerOptions.KEY_ID]
        idGlobal = row[DbTableAnswerOptions.KEY_ID_GLOBAL]
        option = row[DbTableAnswerOptions.KEY_OPTION]
        super.init()
    }
    
    override class var databaseTableName: String {
        return DbTableAnswerOptions.DBPath
    }
    
    override func encode(to container: inout PersistenceContainer) {
        container[DbTableAnswerOptions.KEY_ID] = id
        container[DbTableAnswerOptions.KEY_ID_GLOBAL] = idGlobal
        container[DbTableAnswerOptions.KEY_OPTION] = option
    }
    
    override func didInsert(with rowID: Int64, for column: String?) {
        id = rowID
    }
}
