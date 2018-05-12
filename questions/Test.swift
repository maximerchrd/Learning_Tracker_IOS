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
    var IDresults = [String: Float32]()
    
    func buildIDsArrayFromMap() {
        for relation in testMap {
            if !questionIDs.contains(relation[0]) {
                questionIDs.append(relation[0])
                IDactive[relation[0]] = true
            }
            if !questionIDs.contains(relation[1]) {
                questionIDs.append(relation[1])
                IDactive[relation[1]] = true
            }
            if !(relation[2] == "") {
                IDactive[relation[1]] = false
            }
        }
        for id in questionIDs {
            IDresults[id] = -1.0
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
