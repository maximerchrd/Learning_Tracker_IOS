//
// Created by Maxime Richard on 05.11.18.
// Copyright (c) 2018 Maxime Richard. All rights reserved.
//

class DataPrefix {
    static let multq = "MULTQ"
    static let shrta = "SHRTA"
    static let subObj = "SUBOBJ"

    var dataType = ""
    var dataLength = 0
    var directCorrection = ""
    var dataName = ""

    func stringToPrefix(stringPrefix: String) {
        let length = stringPrefix.components(separatedBy: "///").count
        dataType = stringPrefix.components(separatedBy: "///")[0]
        switch (dataType) {
        case DataPrefix.multq :
            dataLength = Int(stringPrefix.components(separatedBy: "///")[1]) ?? 0
        case DataPrefix.shrta :
            dataLength = Int(stringPrefix.components(separatedBy: "///")[1]) ?? 0
        case DataPrefix.subObj :
            dataLength = Int(stringPrefix.components(separatedBy: "///")[1]) ?? 0
        default :
            dataType = "UNKNOWN"
        }
    }
}