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
    static let KEY_SETTING_NAME = "setting_name"
    static let KEY_SETTING_VALUE = "setting_value"
    static let key_name = "name"
    static let key_master = "master"
    static let key_automatic_connection = "automatic_connection"
    static var DBName = "NoName"
    
    static func createTable(DatabaseName: String) throws {
        DBName = DatabaseName
        let dbQueue = try DatabaseQueue(path: DatabaseName)
        try dbQueue.write { db in
            try db.create(table: TABLE_NAME, ifNotExists: true) { t in
                t.column(KEY_IDsettings, .integer).primaryKey()
                t.column(KEY_SETTING_NAME, .text).notNull()
                t.column(KEY_SETTING_VALUE, .text).notNull()
            }
        }
    }
    
    static func initializeSettings() throws {
        do {
            let dbQueue = try DatabaseQueue(path: DBName)
            try dbQueue.write { db in
                let settings = try Setting.fetchAll(db)
                if (settings.count == 0) {
                    var setting = Setting(setting_name:DbTableSettings.key_name, setting_value:NSLocalizedString("No name", comment: "Place holder for the name"))
                    try setting.insert(db)
                    setting = Setting(setting_name:DbTableSettings.key_master, setting_value:"192.168.1.100")
                    try setting.insert(db)
                    setting = Setting(setting_name:DbTableSettings.key_automatic_connection, setting_value:"1")
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
               let setting = try Setting.fetchOne(db, "SELECT * FROM " + DbTableSettings.TABLE_NAME + " WHERE " + DbTableSettings.KEY_SETTING_NAME + " = ?", arguments: [DbTableSettings.key_name])
                name = setting!.setting_value
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
                let setting = try Setting.fetchOne(db, "SELECT * FROM " + DbTableSettings.TABLE_NAME + " WHERE " + DbTableSettings.KEY_SETTING_NAME + " = ?", arguments: [DbTableSettings.key_master])
                master = setting!.setting_value
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
                let setting = try Setting.fetchOne(db, "SELECT * FROM " + DbTableSettings.TABLE_NAME + " WHERE " + DbTableSettings.KEY_SETTING_NAME + " = ?", arguments: [DbTableSettings.key_automatic_connection])
                automaticConnection = Int(setting!.setting_value) ?? 0
            }
        } catch let error {
            print(error)
            print(error.localizedDescription)
        }
        return automaticConnection
    }
    
    static func setNameAndMaster(name: String, master: String) {
        setSetting(name: key_master, value: master)
        setSetting(name: key_name, value: name)
    }
    
    static func setMaster(master: String) {
        setSetting(name: DbTableSettings.key_master, value: master)
    }
    
    static func setAutomaticConnection(automaticConnection: Int) {
        setSetting(name: DbTableSettings.key_automatic_connection, value: String(automaticConnection))
    }
    
    static func setSetting(name: String, value: String) {
        do {
            let dbQueue = try DatabaseQueue(path: DBName)
            try dbQueue.write { db in
                try db.execute(
                    "UPDATE " + TABLE_NAME + " SET " + KEY_SETTING_VALUE + " = ? WHERE " + KEY_SETTING_NAME + " = ?",
                    arguments: [value, name])
            }
        } catch let error {
            print(error)
            print(error.localizedDescription)
        }
    }
}

class Setting : Record {
    var id: Int64?
    var setting_name: String
    var setting_value: String
    
    init(setting_name: String, setting_value: String) {
        self.setting_name = setting_name
        self.setting_value = setting_value
        super.init()
    }
    
    required init(row: Row) {
        id = row["id"]
        setting_name = row[DbTableSettings.KEY_SETTING_NAME]
        setting_value = row[DbTableSettings.KEY_SETTING_VALUE]
        super.init()
    }
    
    override class var databaseTableName: String {
        return "settings"
    }
    
    override func encode(to container: inout PersistenceContainer) {
        container["id"] = id
        container[DbTableSettings.KEY_SETTING_NAME] = setting_name
        container[DbTableSettings.KEY_SETTING_VALUE] = setting_value
    }
    
    override func didInsert(with rowID: Int64, for column: String?) {
        id = rowID
    }
}
