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
    static var DBPath = "NoName"
    
    static func createTable(DatabaseName: String) throws {
        DBPath = DatabaseName
        let dbQueue = try DatabaseQueue(path: DatabaseName)
        try dbQueue.inDatabase { db in
            try db.create(table: TABLE_NAME, ifNotExists: true) { t in
                t.column(KEY_ID, .integer).primaryKey()
                t.column(KEY_ID_GLOBAL, .integer).notNull()
                t.column(KEY_SUBJECT, .text).notNull()
            }
        }
    }
    
    static func insertRelationQuestionSubject(questionID: Int, subject: String) throws {
        let dbQueue = try DatabaseQueue(path: DBPath)
        try dbQueue.inDatabase { db in
            let relationQuestionSubject = RelationQuestionSubjectRecord(idGlobal: questionID, subject: subject)
            try relationQuestionSubject.insert(db)
        }
    }
}

class RelationQuestionSubjectRecord : Record {
    var id: Int64?
    var idGlobal: Int
    var subject: String
    
    init(idGlobal: Int, subject: String) {
        self.idGlobal = idGlobal
        self.subject = subject
        super.init()
    }
    
    required init(row: Row) {
        id = row[DbTableRelationQuestionSubject.KEY_ID]
        idGlobal = row[DbTableRelationQuestionSubject.KEY_ID_GLOBAL]
        subject = row[DbTableRelationQuestionSubject.KEY_SUBJECT]
        super.init()
    }
    
    override class var databaseTableName: String {
        return DbTableRelationQuestionSubject.DBPath
    }
    
    override func encode(to container: inout PersistenceContainer) {
        container[DbTableRelationQuestionSubject.KEY_ID] = id
        container[DbTableRelationQuestionSubject.KEY_ID_GLOBAL] = idGlobal
        container[DbTableRelationQuestionSubject.KEY_SUBJECT] = subject
    }
    
    override func didInsert(with rowID: Int64, for column: String?) {
        id = rowID
    }
}
