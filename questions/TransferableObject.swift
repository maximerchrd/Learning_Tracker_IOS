import Foundation

class TransferableObject: Decodable {
    var objectId: String?
    var prefix: String
    var files: [String]
    var fileBytes: String

    init(groupPrefix: String) {
        objectId = nil
        prefix = groupPrefix
        files = [String]()
        fileBytes = ""
    }
}

struct TransferPrefix {
    static let resource = "RESOURCE"
    static let stateUpdate = "STATEUPD"
    static let file = "FILE"
    static let other = "OTHER"
    static let delimiter = "/"
    static let prefixSize = 80

    public static func getSize(prefix: String) -> Int {
        if (prefix.components(separatedBy: TransferPrefix.delimiter).count >= 3) {
            var size = -1
            size = Int(prefix.components(separatedBy: TransferPrefix.delimiter)[2]) ?? 0
            return size
        } else {
            return -1
        }
    }

    public static func getObjectName(prefix: String) -> String {
        if (prefix.components(separatedBy: TransferPrefix.delimiter).count >= 3) {
            let objectName = prefix.components(separatedBy: TransferPrefix.delimiter)[1]
            let nameArray = objectName.components(separatedBy: ".")
            var nameIndex = nameArray.count - 1
            if nameIndex < 0 {
                nameIndex = 0
            }
            return nameArray[nameIndex]
        } else {
            return ""
        }
    }

    public static func isResource(prefix: String) -> Bool {
        return (prefix.components(separatedBy: TransferPrefix.delimiter)[0] == TransferPrefix.resource)
    }

    public static func isStateUpdate(prefix: String) -> Bool {
        return (prefix.components(separatedBy: TransferPrefix.delimiter)[0] == TransferPrefix.stateUpdate)
    }

    public static func isFile(prefix: String) -> Bool {
        return (prefix.components(separatedBy: TransferPrefix.delimiter)[0] == TransferPrefix.file)
    }
    
    public static func isOther(prefix: String) -> Bool {
        return (prefix.components(separatedBy: TransferPrefix.delimiter)[0] == TransferPrefix.other)
    }
}
