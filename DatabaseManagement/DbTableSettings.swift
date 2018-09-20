//
//  DbTableSettings.swift
//  Learning_Tracker_IOS
//
//  Created by Maxime Richard on 23.02.18.
//  Copyright © 2018 Maxime Richard. All rights reserved.
//

import Foundation
import GRDB

class DbTableSettings {
    static let TABLE_NAME = "settings"
    static let KEY_IDsettings = "id"
    static let KEY_NAME = "name"
    static let KEY_MASTER = "master"
    static let KEY_AUTOMATIC_CONNECTION = "automatic_connection"
    static var DBName = "NoName"
    
    static func createTable(DatabaseName: String) throws {
        DBName = DatabaseName
        let dbQueue = try DatabaseQueue(path: DatabaseName)
        try dbQueue.write { db in
            try db.create(table: TABLE_NAME, ifNotExists: true) { t in
                t.column(KEY_IDsettings, .integer).primaryKey()
                t.column(KEY_NAME, .text).notNull()
                t.column(KEY_MASTER, .text).notNull()
                t.column(KEY_AUTOMATIC_CONNECTION, .text).notNull()
            }
        }
    }
    
    static func initializeSettings() throws {
        do {
            let dbQueue = try DatabaseQueue(path: DBName)
            try dbQueue.write { db in
                let settings = try Setting.fetchAll(db)
                if (settings.count == 0) {
                    let setting = Setting(name:NSLocalizedString("No name", comment: "Place holder for the name"), master:"192.168.1.100")
                    try setting.insert(db)
                }
            }
        } catch let error {
            print(error)
            print(error.localizedDescription)
        }
        
    }
    
    static func retrieveName () throws -> String {
        var name = "error fetching name"
        do {
            let dbQueue = try DatabaseQueue(path: DBName)
            try dbQueue.read { db in
               let setting = try Setting.fetchOne(db)
                name = setting!.name
            }
        } catch let error {
            print(error)
            print(error.localizedDescription)
        }
        return name
    }
    
    static func retrieveMaster () throws -> String {
        var master = "error fetching master"
        do {
            let dbQueue = try DatabaseQueue(path: DBName)
            try dbQueue.read { db in
                let setting = try Setting.fetchOne(db)
                master = setting!.master
            }
        } catch let error {
            print(error)
            print(error.localizedDescription)
        }
        return master
    }
    
    static func retrieveAutomaticConnection () throws -> Int {
        var automaticConnection = 1
        do {
            let dbQueue = try DatabaseQueue(path: DBName)
            try dbQueue.write { db in
                let setting = try Setting.fetchOne(db)
                automaticConnection = setting!.automaticConnection
            }
        } catch let error {
            print(error)
            print(error.localizedDescription)
        }
        return automaticConnection
    }
    
    static func setNameAndMaster(name: String, master: String) {
        do {
            let dbQueue = try DatabaseQueue(path: DBName)
            try dbQueue.write { db in
                let setting = try Setting.fetchOne(db)
                let old_name = setting!.name
                let old_master = setting!.master
                try db.execute(
                    "UPDATE " + TABLE_NAME + " SET name = ?, master = ? WHERE name = ? AND master = ?",
                    arguments: [name, master, old_name, old_master])
            }
        } catch let error {
            print(error)
            print(error.localizedDescription)
        }
    }
    
    static func setMaster(master: String) {
        do {
            let dbQueue = try DatabaseQueue(path: DBName)
            try dbQueue.write { db in
                let setting = try Setting.fetchOne(db)
                let name = setting!.name
                try db.execute(
                    "UPDATE " + TABLE_NAME + " SET master = ? WHERE name = ?",
                    arguments: [master, name])
            }
        } catch let error {
            print(error)
            print(error.localizedDescription)
        }
    }
    
    static func setAutomaticConnection(automaticConnection: Int) {
        do {
            let dbQueue = try DatabaseQueue(path: DBName)
            try dbQueue.write { db in
                let setting = try Setting.fetchOne(db)
                let name = setting!.name

                try db.execute(
                    "UPDATE " + TABLE_NAME + " SET " + KEY_AUTOMATIC_CONNECTION + " = ? WHERE name = ?",
                    arguments: [automaticConnection, name])
            }
        } catch let error {
            print(error)
            print(error.localizedDescription)
        }
    }
}

class Setting : Record {
    var id: Int64?
    var name: String
    var master: String
    var automaticConnection: Int
    
    init(name: String, master: String) {
        self.name = name
        self.master = master
        self.automaticConnection = 1
        super.init()
    }
    
    required init(row: Row) {
        id = row["id"]
        name = row[DbTableSettings.KEY_NAME]
        master = row[DbTableSettings.KEY_MASTER]
        automaticConnection = row[DbTableSettings.KEY_AUTOMATIC_CONNECTION]
        super.init()
    }
    
    override class var databaseTableName: String {
        return "settings"
    }
    
    override func encode(to container: inout PersistenceContainer) {
        container["id"] = id
        container[DbTableSettings.KEY_NAME] = name
        container[DbTableSettings.KEY_MASTER] = master
        container[DbTableSettings.KEY_AUTOMATIC_CONNECTION] = automaticConnection
    }
    
    override func didInsert(with rowID: Int64, for column: String?) {
        id = rowID
    }
}
