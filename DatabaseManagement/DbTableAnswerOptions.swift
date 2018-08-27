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
    static let KEY_ID_GLOBAL = "ID_GLOBAL"
    static let KEY_OPTION = "OPTION"
    static var DBPath = "NoName"
    
    static func createTable(DatabaseName: String) throws {
        DBPath = DatabaseName
        let dbQueue = try DatabaseQueue(path: DatabaseName)
        try dbQueue.write { db in
            try db.create(table: TABLE_NAME, ifNotExists: true) { t in
                t.column(KEY_ID, .integer).primaryKey()
                t.column(KEY_ID_GLOBAL, .integer).notNull()
                t.column(KEY_OPTION, .text).notNull()
            }
        }
    }
    
    static func dropTable(DatabaseName: String) throws {
        DBPath = DatabaseName
        let dbQueue = try DatabaseQueue(path: DatabaseName)
        try dbQueue.write { db in
            try db.drop(table: TABLE_NAME)
        }
    }
    
    static func insertAnswerOption(questionID: Int64, option: String) throws {
        let dbQueue = try DatabaseQueue(path: DBPath)
        try dbQueue.write { db in
            let answerOption = AnswerOptionRecord(idGlobal: questionID, option: option)
            try answerOption.insert(db)
        }
    }
    
    static func retrieveAnswerOptions(questionID: Int64) throws -> [String]{
        var answerOptions = [String]()
        var answerOptionRecord = [AnswerOptionRecord]()
        do {
            let dbQueue = try DatabaseQueue(path: DBPath)
            let query = "SELECT * FROM " + TABLE_NAME + " WHERE " + KEY_ID_GLOBAL + "='" + String(questionID) + "';"
            try dbQueue.read { db in
                answerOptionRecord = try AnswerOptionRecord.fetchAll(db, query)
            }
        } catch let error {
            print(error)
            print(error.localizedDescription)
        }
        for optionRecord in answerOptionRecord {
            answerOptions.append(optionRecord.option)
        }
        return answerOptions
    }
    
    static func deleteAnswerOptions(questionID: Int64) throws -> [String]{
        var answerOptions = [String]()
        var answerOptionRecord = [AnswerOptionRecord]()
        do {
            let dbQueue = try DatabaseQueue(path: DBPath)
            let query = "DELETE FROM " + TABLE_NAME + " WHERE " + KEY_ID_GLOBAL + "='" + String(questionID) + "';"
            try dbQueue.write { db in
                answerOptionRecord = try AnswerOptionRecord.fetchAll(db, query)
            }
        } catch let error {
            print(error)
            print(error.localizedDescription)
        }
        for optionRecord in answerOptionRecord {
            answerOptions.append(optionRecord.option)
        }
        return answerOptions
    }
}

class AnswerOptionRecord : Record {
    var id: Int64?
    var idGlobal: Int64
    var option: String
    
    init(idGlobal: Int64, option: String) {
        self.idGlobal = idGlobal
        self.option = option
        super.init()
    }
    
    required init(row: Row) {
        self.id = row[DbTableAnswerOptions.KEY_ID]
        self.idGlobal = row[DbTableAnswerOptions.KEY_ID_GLOBAL]
        self.option = row[DbTableAnswerOptions.KEY_OPTION]
        super.init()
    }
    
    override class var databaseTableName: String {
        return DbTableAnswerOptions.TABLE_NAME
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
