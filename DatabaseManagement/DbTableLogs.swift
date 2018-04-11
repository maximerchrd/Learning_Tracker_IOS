//
//  DbTableLogs.swift
//  Learning_Tracker_IOS
//
//  Created by Maxime Richard on 01.04.18.
//  Copyright © 2018 Maxime Richard. All rights reserved.
//

import Foundation
import GRDB

class DbTableLogs {
    static let TABLE_NAME = "logs"
    static let KEY_ID = "id"
    static let KEY_LOG = "LOG"
    static var DBPath = "NoName"
    
    static func createTable(DatabaseName: String) throws {
        DBPath = DatabaseName
        let dbQueue = try DatabaseQueue(path: DatabaseName)
        try dbQueue.inDatabase { db in
            try db.create(table: TABLE_NAME, ifNotExists: true) { t in
                t.column(KEY_ID, .integer).primaryKey()
                t.column(KEY_LOG, .text).notNull()
            }
        }
    }
    
    static func insertLog(log: String) {
        do {
            let dbQueue = try DatabaseQueue(path: DBPath)
            try dbQueue.inDatabase { db in
                let logRecord = LogRecord(log: Date().description + log)
                try logRecord.insert(db)
            }
        } catch let error {
            print(error)
        }
    }
    
    static func getNotSentLogs() throws -> [String] {
        let dbQueue = try DatabaseQueue(path: DBPath)
        var logsRecords = [LogRecord]()
        try dbQueue.inDatabase { db in
            logsRecords = try LogRecord.fetchAll(db)
        }
        var logs = [String]()
        for singleRecord in logsRecords {
            logs.append(singleRecord.log)
        }
        return logs
    }
    static func deleteLog() throws {
        let dbQueue = try DatabaseQueue(path: DBPath)
        try dbQueue.inDatabase { db in
            //let logRecord = LogRecord()
            try LogRecord.deleteAll(db)
            //try logRecord.delete(db)
        }
    }
}

class LogRecord : Record {
    var id: Int64?
    var log: String
    
    init(log: String) {
        self.log = log
        super.init()
    }
    
    required init(row: Row) {
        id = row[DbTableLogs.KEY_ID]
        self.log = row[DbTableLogs.KEY_LOG]
        super.init()
    }
    
    override class var databaseTableName: String {
        return DbTableLogs.TABLE_NAME
    }
    
    override func encode(to container: inout PersistenceContainer) {
        container[DbTableLogs.KEY_ID] = id
        container[DbTableLogs.KEY_LOG] = log
    }
    
    override func didInsert(with rowID: Int64, for column: String?) {
        id = rowID
    }
}
