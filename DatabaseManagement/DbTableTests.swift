//
//  DbTableTests.swift
//  Learning_Tracker_IOS
//
//  Created by Maxime Richard on 06.04.18.
//  Copyright © 2018 Maxime Richard. All rights reserved.
//

import Foundation
import GRDB

class DbTableTests {
    static let TABLE_NAME = "tests"
    static let KEY_ID = "id"
    static let KEY_ID_GLOBAL = "ID_TEST_GLOBAL"
    static let KEY_TEST_NAME = "TEST_NAME"
    static let KEY_QUESTION_IDS = "QUESTION_IDS"
    static let KEY_TEST_TYPE = "TEST_TYPE"
    static let KEY_MEDALS_INSTRUCTIONS = "MEDALS_INSTRUCTIONS"
    static let KEY_MEDIA_FILE = "MEDIA_FILE"
    static var DBPath = "NoName"
    
    static func createTable(DatabaseName: String) throws {
        DBPath = DatabaseName
        let dbQueue = try DatabaseQueue(path: DatabaseName)
        try dbQueue.write { db in
            try db.create(table: DbTableTests.TABLE_NAME, ifNotExists: true) { t in
                t.column(DbTableTests.KEY_ID, .integer).primaryKey()
                t.column(DbTableTests.KEY_ID_GLOBAL, .integer).notNull().unique(onConflict: .ignore)
                t.column(DbTableTests.KEY_TEST_NAME, .text).notNull()
                t.column(DbTableTests.KEY_QUESTION_IDS, .text)
                t.column(DbTableTests.KEY_TEST_TYPE, .text)
                t.column(DbTableTests.KEY_MEDALS_INSTRUCTIONS, .text)
                t.column(DbTableTests.KEY_MEDIA_FILE, .text)
            }
        }
    }
    
    static func insertTest(testID: Int64, test: String, questionIDs: String = "", objectiveIDs: [Int64] = [Int64](),
                           objectives: [String] = [String](), testType: String = "FORMATIVE", medalsInstructions: String = "",
                           mediaFileName: String = "") throws {
        let dbQueue = try DatabaseQueue(path: DBPath)
        try dbQueue.write { db in
            //insert the test
            let testRecord = TestRecord(idGlobal: testID, test: test, questionIDs: questionIDs, testType: testType,
                    medalsInstructions: medalsInstructions, mediaFileName: mediaFileName)
            try testRecord.insert(db)
            
            //insert the corresponding learning objectives
            if objectiveIDs.count == objectives.count {
                for i in 0..<objectiveIDs.count {
                    do {
                        try DbTableLearningObjective.insertLearningObjective(objectiveID: objectiveIDs[i], objective: objectives[i], levelCognitiveAbility: -1)
                        try DbTableRelationTestObjective.insertRelationTestObjective(idTest: testID, idObjective: objectiveIDs[i])
                    } catch let error {
                        print(error)
                    }
                }
            } else {
                let error = "Problem inserting test: the objectives array is not the same size as the corresponding IDs"
                print(error)
                DbTableLogs.insertLog(log: error)
            }
            //try DbTableRelationQuestionTest.insertRelationQuestionTest(questionID: testID, test: test)
        }
    }
    
    static func getNameFromTestID(testID: Int64) -> String {
        do {
            var testName = "no test found"
            let dbQueue = try DatabaseQueue(path: DBPath)
            var testsRecords = [TestRecord]()
            var sql = "SELECT * FROM " + TABLE_NAME
            sql += " WHERE " + KEY_ID_GLOBAL + " = " + String(testID)
            try dbQueue.read { db in
                testsRecords = try TestRecord.fetchAll(db, sql)
                for singleRecord in testsRecords {
                    testName = singleRecord.test
                }
            }
            
            return testName
        } catch let error {
            print(error)
        }
        
        return ""
    }
    
    static func getTypeFromTestID(testID: Int64) -> String {
        do {
            var testType = "no test found"
            let dbQueue = try DatabaseQueue(path: DBPath)
            var testsRecords = [TestRecord]()
            var sql = "SELECT * FROM " + TABLE_NAME
            sql += " WHERE " + KEY_ID_GLOBAL + " = " + String(testID)
            try dbQueue.read { db in
                testsRecords = try TestRecord.fetchAll(db, sql)
                for singleRecord in testsRecords {
                    testType = singleRecord.testType
                }
            }
            
            return testType
        } catch let error {
            print(error)
        }
        
        return ""
    }
    
    static func getMedalsInstructionsFromTestID(testID: Int64) -> String {
        do {
            var medalsInstructions = "no test found"
            let dbQueue = try DatabaseQueue(path: DBPath)
            var testsRecords = [TestRecord]()
            var sql = "SELECT * FROM " + TABLE_NAME
            sql += " WHERE " + KEY_ID_GLOBAL + " = " + String(testID)
            try dbQueue.read { db in
                testsRecords = try TestRecord.fetchAll(db, sql)
                for singleRecord in testsRecords {
                    medalsInstructions = singleRecord.medalsInstructions
                }
            }
            return medalsInstructions
        } catch let error {
            print(error)
        }
        
        return ""
    }

    static func getMediaFileNameFromTestID(testID: Int64) -> String {
        do {
            var mediaFileName = "no media file found"
            let dbQueue = try DatabaseQueue(path: DBPath)
            var testsRecords = [TestRecord]()
            var sql = "SELECT * FROM " + TABLE_NAME
            sql += " WHERE " + KEY_ID_GLOBAL + " = " + String(testID)
            try dbQueue.read { db in
                testsRecords = try TestRecord.fetchAll(db, sql)
                for singleRecord in testsRecords {
                    mediaFileName = singleRecord.mediaFileName
                }
            }

            return mediaFileName
        } catch let error {
            print(error)
        }

        return ""
    }
    
    static func getObjectivesFromTestID(testID: Int64) -> [String] {
        var objectives = [String]()
        var objectiveRecords = [LearningObjectiveRecord]()
        
        do {
            let dbQueue = try DatabaseQueue(path: DBPath)
            try dbQueue.read { db in
                let rel = DbTableRelationTestObjective.TABLE_NAME
                let obj = DbTableLearningObjective.TABLE_NAME
                let objId = DbTableLearningObjective.KEY_ID_GLOBAL
                let relObjId = DbTableRelationTestObjective.KEY_ID_OBJECTIVE
                let relTeId = DbTableRelationTestObjective.KEY_ID_TEST
                objectiveRecords = try LearningObjectiveRecord.fetchAll(db,"SELECT * FROM \(obj) INNER JOIN \(rel) ON \(obj).\(objId)=\(rel).\(relObjId) WHERE \(rel).\(relTeId)=\(testID);")
                for singleRecord in objectiveRecords {
                    objectives.append(singleRecord.objective)
                }
            }
        } catch let error {
            print(error)
        }
        
        //remove empty objectives
        let index = objectives.index(of: "")
        if index != nil {
            objectives.remove(at: index!)
        }
        let index2 = objectives.index(of: " ")
        if index2 != nil {
            objectives.remove(at: index2!)
        }
        return objectives
    }
    
    static func getQuestionIds(testName: String) -> [String] {
        var questionIds = [String]()
        var testsRecords = [TestRecord]()
        do {
            let dbQueue = try DatabaseQueue(path: DBPath)
            let sql = "SELECT * FROM " + TABLE_NAME + " WHERE " + KEY_TEST_NAME + "=\'" + testName + "\';"
            print(sql)
            try dbQueue.read { db in
                testsRecords = try TestRecord.fetchAll(db, sql)
            }
            
            for singleRecord in testsRecords {
                let notParsedIds = singleRecord.questionIDS
                questionIds = notParsedIds.components(separatedBy: "///")
                while questionIds.contains("") {
                    questionIds.remove(at: questionIds.index(of: "")!)
                }
            }
        } catch let error {
            print(error)
        }
        
        return questionIds
    }
    
    static func getAllTests() throws -> [[String]] {
        let dbQueue = try DatabaseQueue(path: DBPath)
        var testsRecords = [TestRecord]()
        try dbQueue.read { db in
            testsRecords = try TestRecord.fetchAll(db)
        }
        
        //fill array with tests and corresponding ids
        var tests = [String]()
        var ids = [Int64]()
        for singleRecord in testsRecords {
            tests.append(singleRecord.test)
            ids.append(singleRecord.idGlobal)
        }
        
        //remove empty tests
        let index = tests.index(of: "")
        if index != nil {
            tests.remove(at: index!)
            ids.remove(at: index!)
        }
        let index2 = tests.index(of: " ")
        if index2 != nil {
            tests.remove(at: index2!)
            ids.remove(at: index2!)
        }
        
        //put tests and ids in one single array
        var testsAndIds = [[String]]()
        for i in 0..<tests.count {
            testsAndIds.append([String]())
            testsAndIds[i].append(tests[i])
            testsAndIds[i].append(String(ids[i]))
        }
        
        return testsAndIds
    }
}

class TestRecord : Record {
    var id: Int64?
    var idGlobal: Int64
    var test: String
    var questionIDS: String
    var testType: String
    var medalsInstructions: String
    var mediaFileName: String
    
    init(idGlobal: Int64, test: String, questionIDs: String, testType: String, medalsInstructions: String,
         mediaFileName: String) {
        self.idGlobal = idGlobal
        self.test = test
        self.questionIDS = questionIDs
        self.testType = testType
        self.medalsInstructions = medalsInstructions
        self.mediaFileName = mediaFileName
        super.init()
    }
    
    required init(row: Row) {
        self.id = row[DbTableTests.KEY_ID]
        self.idGlobal = row[DbTableTests.KEY_ID_GLOBAL]
        self.test = row[DbTableTests.KEY_TEST_NAME]
        self.questionIDS = row[DbTableTests.KEY_QUESTION_IDS]
        self.testType = row[DbTableTests.KEY_TEST_TYPE]
        self.medalsInstructions = row[DbTableTests.KEY_MEDALS_INSTRUCTIONS]
        self.mediaFileName = row[DbTableTests.KEY_MEDIA_FILE]
        super.init()
    }
    
    override class var databaseTableName: String {
        return DbTableTests.TABLE_NAME
    }
    
    override func encode(to container: inout PersistenceContainer) {
        container[DbTableTests.KEY_ID] = id
        container[DbTableTests.KEY_ID_GLOBAL] = idGlobal
        container[DbTableTests.KEY_TEST_NAME] = test
        container[DbTableTests.KEY_QUESTION_IDS] = questionIDS
        container[DbTableTests.KEY_TEST_TYPE] = testType
        container[DbTableTests.KEY_MEDALS_INSTRUCTIONS] = medalsInstructions
        container[DbTableTests.KEY_MEDIA_FILE] = mediaFileName
    }
    
    override func didInsert(with rowID: Int64, for column: String?) {
        id = rowID
    }
}
