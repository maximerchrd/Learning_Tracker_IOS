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
    static let KEY_MULTIPEER = "multipeer"
    static var DBName = "NoName"
    
    static func createTable(DatabaseName: String) throws {
        DBName = DatabaseName
        let dbQueue = try DatabaseQueue(path: DatabaseName)
        try dbQueue.inDatabase { db in
            try db.create(table: TABLE_NAME, ifNotExists: true) { t in
                t.column(KEY_IDsettings, .integer).primaryKey()
                t.column(KEY_NAME, .text).notNull()
                t.column(KEY_MASTER, .text).notNull()
                t.column(KEY_MULTIPEER, .boolean).notNull()
            }
        }
    }
    
    static func initializeSettings() throws {
        do {
            let dbQueue = try DatabaseQueue(path: DBName)
            try dbQueue.inDatabase { db in
                let settings = try Setting.fetchAll(db)
                if (settings.count == 0) {
                    let setting = Setting(name:"Anonymous", master:"192.168.1.100", MultipeerConnectivity:false)
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
            try dbQueue.inDatabase { db in
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
            try dbQueue.inDatabase { db in
                let setting = try Setting.fetchOne(db)
                master = setting!.master
            }
        } catch let error {
            print(error)
            print(error.localizedDescription)
        }
        return master
    }
    static func retrieveMultipeer () throws -> Bool {
        var multipeer = false
        do {
            let dbQueue = try DatabaseQueue(path: DBName)
            try dbQueue.inDatabase { db in
                let setting = try Setting.fetchOne(db)
                multipeer = setting!.MultipeerConnectivity
            }
        } catch let error {
            print(error)
            print(error.localizedDescription)
        }
        return multipeer
    }
    
    static func setNameAndMaster(name: String, master: String) {
        do {
            let dbQueue = try DatabaseQueue(path: DBName)
            try dbQueue.inDatabase { db in
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
    
    static func setMultipeer(multipeer: Bool) {
        do {
            let dbQueue = try DatabaseQueue(path: DBName)
            try dbQueue.inDatabase { db in
                let setting = try Setting.fetchOne(db)
                let old_name = setting!.name
                let old_master = setting!.master
                try db.execute(
                    "UPDATE " + TABLE_NAME + " SET " + KEY_MULTIPEER + " = ? WHERE name = ? AND master = ?",
                    arguments: [multipeer, old_name, old_master])
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
    var MultipeerConnectivity: Bool
    
    init(name: String, master: String, MultipeerConnectivity:Bool) {
        self.name = name
        self.master = master
        self.MultipeerConnectivity = MultipeerConnectivity
        super.init()
    }
    
    required init(row: Row) {
        id = row["id"]
        name = row[DbTableSettings.KEY_NAME]
        master = row[DbTableSettings.KEY_MASTER]
        MultipeerConnectivity = row[DbTableSettings.KEY_MULTIPEER]
        super.init()
    }
    
    override class var databaseTableName: String {
        return "settings"
    }
    
    override func encode(to container: inout PersistenceContainer) {
        container["id"] = id
        container[DbTableSettings.KEY_NAME] = name
        container[DbTableSettings.KEY_MASTER] = master
        container[DbTableSettings.KEY_MULTIPEER] = MultipeerConnectivity
    }
    
    override func didInsert(with rowID: Int64, for column: String?) {
        id = rowID
    }
}
