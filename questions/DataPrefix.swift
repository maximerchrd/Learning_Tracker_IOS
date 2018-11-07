//
// Created by Maxime Richard on 05.11.18.
// Copyright (c) 2018 Maxime Richard. All rights reserved.
//

class DataPrefix {
    static let multq = "MULTQ"

    var dataType = ""
    var dataLength = ""
    var directCorrection = ""
    var dataName = ""

    func stringToPrefix(stringPrefix: String) {
        let length = stringPrefix.components(separatedBy: "///").count
        dataType = stringPrefix.components(separatedBy: "///")[0]
        switch (dataType) {
        case DataPrefix.multq :
            dataLength = stringPrefix.components(separatedBy: "///")[1]
        default :
            dataType = "UNKNOWN"
        }
    }
}