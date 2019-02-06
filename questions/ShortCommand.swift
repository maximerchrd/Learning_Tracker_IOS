import Foundation

class ShortCommand: Decodable {
    var command = -1
    var optionalArgument1 = ""
    var optionalArgument2 = ""
    var optionalArgument3 = ""

    static let correction = 0
    static let connected = 4
    static let disconnected = 5
    static let gameScore = 7
}