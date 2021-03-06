//
//  DbTableRelationQuestionSubject.swift
//  Learning_Tracker_IOS
//
//  Created by Maxime Richard on 27.02.18.
//  Copyright © 2018 Maxime Richard. All rights reserved.
//

import Foundation
import GRDB

class DbTableRelationQuestionSubject {
    static let TABLE_NAME = "question_subject_relation"
    static let KEY_ID = "id"
    static let KEY_ID_GLOBAL = "ID_GLOBAL"
    static let KEY_SUBJECT = "SUBJECT"
    static let KEY_IDGLOBALSUBJECT = "IDGLOBALSUBJECT"
    static var DBPath = "NoName"
    
    static func createTable(DatabaseName: String) throws {
        DBPath = DatabaseName
        let dbQueue = try DatabaseQueue(path: DatabaseName)
        try dbQueue.write { db in
            try db.create(table: TABLE_NAME, ifNotExists: true) { t in
                t.column(KEY_ID, .integer).primaryKey()
                t.column(KEY_ID_GLOBAL, .integer).notNull()
                t.column(KEY_SUBJECT, .text).notNull()
                t.column(KEY_IDGLOBALSUBJECT, .text).notNull().unique(onConflict: .replace)
            }
        }
    }
    
    static func insertRelationQuestionSubject(questionID: Int64, subject: String) throws {
        let dbQueue = try DatabaseQueue(path: DBPath)
        try dbQueue.write { db in
            let idGlobalSubject = String(questionID) + subject
            let relationQuestionSubjectRecord = RelationQuestionSubjectRecord(idGlobal: questionID, subject: subject, idGlobalSubject: idGlobalSubject)
            try relationQuestionSubjectRecord.insert(db)
        }
    }
    
    static func getQuestionsForSubject(subject: String) throws -> [Int64] {
        let dbQueue = try DatabaseQueue(path: DBPath)
        var relationQuestionSubjectRecords = [RelationQuestionSubjectRecord]()
        let subjectPurged = subject.replacingOccurrences(of: "'", with: "''")
        var request = ""
        if subject == NSLocalizedString("All subjects", comment: "All subjects in the database") {
            request = "SELECT * FROM " + TABLE_NAME
        } else {
            request = "SELECT * FROM " + TABLE_NAME + " WHERE " + KEY_SUBJECT + "='" + subjectPurged + "'"
        }
        try dbQueue.read { db in
            relationQuestionSubjectRecords = try RelationQuestionSubjectRecord.fetchAll(db, request)
        }
        var questionIDs = [Int64]()
        for singleRecord in relationQuestionSubjectRecords {
            questionIDs.append(singleRecord.idGlobal)
        }
        if subject == NSLocalizedString("All subjects", comment: "All subjects in the database") {
            questionIDs = Array(Set(questionIDs))
        }
        return questionIDs
    }
}

class RelationQuestionSubjectRecord : Record {
    var id: Int64?
    var idGlobal: Int64
    var subject: String
    var idGlobalSubject: String
    
    init(idGlobal: Int64, subject: String, idGlobalSubject: String) {
        self.idGlobal = idGlobal
        self.subject = subject
        self.idGlobalSubject = idGlobalSubject
        super.init()
    }
    
    required init(row: Row) {
        id = row[DbTableRelationQuestionSubject.KEY_ID]
        idGlobal = row[DbTableRelationQuestionSubject.KEY_ID_GLOBAL]
        subject = row[DbTableRelationQuestionSubject.KEY_SUBJECT]
        idGlobalSubject = row[DbTableRelationQuestionSubject.KEY_IDGLOBALSUBJECT]
        super.init()
    }
    
    override class var databaseTableName: String {
        return DbTableRelationQuestionSubject.TABLE_NAME
    }
    
    override func encode(to container: inout PersistenceContainer) {
        container[DbTableRelationQuestionSubject.KEY_ID] = id
        container[DbTableRelationQuestionSubject.KEY_ID_GLOBAL] = idGlobal
        container[DbTableRelationQuestionSubject.KEY_SUBJECT] = subject
        container[DbTableRelationQuestionSubject.KEY_IDGLOBALSUBJECT] = idGlobalSubject
    }
    
    override func didInsert(with rowID: Int64, for column: String?) {
        id = rowID
    }
}
