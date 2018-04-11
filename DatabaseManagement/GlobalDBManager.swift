//
//  GlobalDBManager.swift
//  Learning_Tracker_IOS
//
//  Created by Maxime Richard on 23.02.18.
//  Copyright © 2018 Maxime Richard. All rights reserved.
//

import Foundation
import GRDB

class GlobalDBManager {
    static let DATABASE_NAME = "learning_tracker.sqlite"
    
    static func createTables () {
        do {
            let databaseURL = try FileManager.default
                .url(for: .applicationSupportDirectory, in: .userDomainMask, appropriateFor: nil, create: true)
                .appendingPathComponent(DATABASE_NAME)
            try DbTableSettings.createTable(DatabaseName: databaseURL.path)
            try DbTableQuestionMultipleChoice.createTable(DatabasePath: databaseURL.path)
            try DbTableQuestionShortAnswer.createTable(DatabasePath: databaseURL.path)
            try DbTableAnswerOptions.createTable(DatabaseName: databaseURL.path)
            try DbTableIndividualQuestionForResult.createTable(DatabaseName: databaseURL.path)
            try DbTableLearningObjective.createTable(DatabaseName: databaseURL.path)
            try DbTableRelationQuestionAnswerOption.createTable(DatabaseName: databaseURL.path)
            try DbTableRelationQuestionSubject.createTable(DatabaseName: databaseURL.path)
            try DbTableRelationQuestionObjective.createTable(DatabaseName: databaseURL.path)
            try DbTableSubject.createTable(DatabaseName: databaseURL.path)
            try DbTableLogs.createTable(DatabaseName: databaseURL.path)
            try DbTableTests.createTable(DatabaseName: databaseURL.path)
            try DbTableRelationTestObjective.createTable(DatabaseName: databaseURL.path)
            
            //Register migrations
            var migrator = DatabaseMigrator()
            // v1 database
            migrator.registerMigration("v1") { db in
                try db.drop(table: DbTableAnswerOptions.TABLE_NAME)
                try db.create(table: DbTableAnswerOptions.TABLE_NAME, ifNotExists: true) { t in
                    t.column(DbTableAnswerOptions.KEY_ID, .integer).primaryKey()
                    t.column(DbTableAnswerOptions.KEY_ID_GLOBAL, .integer).notNull()
                    t.column(DbTableAnswerOptions.KEY_OPTION, .text).notNull().unique(onConflict: .ignore)
                }
                print("migration to v1")
            }
            
            //Do migrations
            let dbQueue = try DatabaseQueue(path: databaseURL.path)
            try migrator.migrate(dbQueue)
        } catch let error {
            print(error)
            print(error.localizedDescription)
        }
    }
}
