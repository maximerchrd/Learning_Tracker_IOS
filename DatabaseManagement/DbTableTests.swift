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
    static var DBPath = "NoName"
    
    static func createTable(DatabaseName: String) throws {
        DBPath = DatabaseName
        let dbQueue = try DatabaseQueue(path: DatabaseName)
        try dbQueue.inDatabase { db in
            try db.create(table: TABLE_NAME, ifNotExists: true) { t in
                t.column(KEY_ID, .integer).primaryKey()
                t.column(KEY_ID_GLOBAL, .integer).notNull().unique(onConflict: .ignore)
                t.column(KEY_TEST_NAME, .text).notNull()
            }
        }
    }
    
    static func insertTest(testID: Int, test: String, objectiveIDs: [Int], objectives: [String]) throws {
        let dbQueue = try DatabaseQueue(path: DBPath)
        try dbQueue.inDatabase { db in
            //insert the test
            let testRecord = TestRecord(idGlobal: testID, test: test)
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
    
    static func getObjectivesFromTestID(testID: Int) -> [String] {
        var objectives = [String]()
        var objectiveRecords = [LearningObjectiveRecord]()
        
        do {
            let dbQueue = try DatabaseQueue(path: DBPath)
            try dbQueue.inDatabase { db in
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
    
    static func getAllTests() throws -> [[String]] {
        let dbQueue = try DatabaseQueue(path: DBPath)
        var testsRecords = [TestRecord]()
        try dbQueue.inDatabase { db in
            testsRecords = try TestRecord.fetchAll(db)
        }
        
        //fill array with tests and corresponding ids
        var tests = [String]()
        var ids = [Int]()
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
    var idGlobal: Int
    var test: String
    
    init(idGlobal: Int, test: String) {
        self.idGlobal = idGlobal
        self.test = test
        super.init()
    }
    
    required init(row: Row) {
        id = row[DbTableTests.KEY_ID]
        self.idGlobal = row[DbTableTests.KEY_ID_GLOBAL]
        self.test = row[DbTableTests.KEY_TEST_NAME]
        super.init()
    }
    
    override class var databaseTableName: String {
        return DbTableTests.TABLE_NAME
    }
    
    override func encode(to container: inout PersistenceContainer) {
        container[DbTableTests.KEY_ID] = id
        container[DbTableTests.KEY_ID_GLOBAL] = idGlobal
        container[DbTableTests.KEY_TEST_NAME] = test
    }
    
    override func didInsert(with rowID: Int64, for column: String?) {
        id = rowID
    }
}
