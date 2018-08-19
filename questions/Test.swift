//
//  Test.swift
//  Learning_Tracker_IOS
//
//  Created by Maxime Richard on 09.05.18.
//  Copyright © 2018 Maxime Richard. All rights reserved.
//

import Foundation

class Test {
    var testName = ""
    var testMap = [[String]]()
    var questionIDs = [String]()
    var IDactive = [String: Bool]()
    var answeredIds = [String]()
    var IDresults = [String: Float32]()
    
    func buildIDsArraysFromMap() {
        for id in questionIDs {
            IDactive[id] = true
            IDresults[id] = -1.0
        }
        for relation in testMap {
            if !(relation[2] == "") {
                IDactive[relation[1]] = false
            }
        }
    }
    
    func refreshActiveIds() {
        for relation in testMap {
            let singlerelations = relation[2].components(separatedBy: ";")
            for singlerelation in singlerelations {
                if singlerelation.contains("EVALUATION<") {
                    let threshold = Float32(singlerelation.replacingOccurrences(of: "EVALUATION<", with: "")) ?? -1.0
                    let result = IDresults[relation[0]] ?? -1.0
                    if result >= 0.0 && result < threshold {
                        IDactive[relation[1]] = true
                    }
                }
            }
        }
    }
}
