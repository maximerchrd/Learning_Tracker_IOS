//
//  DbTableSubject.swift
//  Learning_Tracker_IOS
//
//  Created by Maxime Richard on 27.02.18.
//  Copyright © 2018 Maxime Richard. All rights reserved.
//

import Foundation
import GRDB

class DbTableSubject {
    static let TABLE_NAME = "subjects"
    static let KEY_ID = "id"
    static let KEY_ID_GLOBAL = "ID_SUBJECT_GLOBAL"
    static let KEY_SUBJECT = "SUBJECT"
    static var DBPath = "NoName"
    
    static func createTable(DatabaseName: String) throws {
        DBPath = DatabaseName
        let dbQueue = try DatabaseQueue(path: DatabaseName)
        try dbQueue.inDatabase { db in
            try db.create(table: TABLE_NAME, ifNotExists: true) { t in
                t.column(KEY_ID, .integer).primaryKey()
                t.column(KEY_ID_GLOBAL, .integer).notNull()
                t.column(KEY_SUBJECT, .text).notNull().unique(onConflict: .ignore)
            }
        }
    }
    
    static func insertSubject(questionID: Int, subject: String, levelCognitiveAbility: Int) throws {
        let dbQueue = try DatabaseQueue(path: DBPath)
        try dbQueue.inDatabase { db in
            let subject = SubjectRecord(idGlobal: 2000000, subject: subject, levelCognitiveAbility: levelCognitiveAbility)
            try subject.insert(db)
            let subjectToUpdate = try SubjectRecord.fetchOne(db, key: [KEY_ID_GLOBAL: 2000000])
            subjectToUpdate?.idGlobal = 2000000 + Int((subjectToUpdate?.id)!)
            try subjectToUpdate?.update(db)
        }
    }
    
    static func getSubjectsForQuestionID(questionID: Int) -> [String] {
        //to implement after relations are implemented
        
        return [String]()
    }
    
    static func getAllSubjects() throws -> [String] {
        let dbQueue = try DatabaseQueue(path: DBPath)
        var subjectsRecords = [SubjectRecord]()
        try dbQueue.inDatabase { db in
            subjectsRecords = try SubjectRecord.fetchAll(db)
        }
        var subjects = [String]()
        for singleRecord in subjectsRecords {
            subjects.append(singleRecord.subject)
        }
        return subjects
    }
    
    static func getSubjectsAndQuestionsNeedingPractice() -> [[String]] {
        return [[String]]()
    }
}

class SubjectRecord : Record {
    var id: Int64?
    var idGlobal: Int
    var subject: String
    
    init(idGlobal: Int, subject: String, levelCognitiveAbility: Int) {
        self.idGlobal = idGlobal
        self.subject = subject
        super.init()
    }
    
    required init(row: Row) {
        id = row[DbTableSubject.KEY_ID]
        self.idGlobal = row[DbTableSubject.KEY_ID_GLOBAL]
        self.subject = row[DbTableSubject.KEY_SUBJECT]
        super.init()
    }
    
    override class var databaseTableName: String {
        return DbTableSubject.DBPath
    }
    
    override func encode(to container: inout PersistenceContainer) {
        container[DbTableSubject.KEY_ID] = id
        container[DbTableSubject.KEY_ID_GLOBAL] = idGlobal
        container[DbTableSubject.KEY_SUBJECT] = subject
    }
    
    override func didInsert(with rowID: Int64, for column: String?) {
        id = rowID
    }
}
