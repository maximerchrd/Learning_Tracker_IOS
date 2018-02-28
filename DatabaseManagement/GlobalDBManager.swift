//
//  GlobalDBManager.swift
//  Learning_Tracker_IOS
//
//  Created by Maxime Richard on 23.02.18.
//  Copyright © 2018 Maxime Richard. All rights reserved.
//

import Foundation

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
        } catch let error {
            print(error)
            print(error.localizedDescription)
        }
    }
}
