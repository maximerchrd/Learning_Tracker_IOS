import Foundation

class ClientToServerTransferable {
    var prefix = -1
    var size = -1
    var optionalArgument1 = ""
    var optionalArgument2 = ""
    var fileBytes = [UInt8]()
    
    init(prefix: Int, size:Int = 0, optionalArgument: String = "") {
        self.prefix = prefix
        self.size = size
        self.optionalArgument1 = optionalArgument
    }
    
    static public let answerPrefix = 0
    static public let connectionPrefix = 1
    static public let resourceIdsPrefix = 2
    static public let disconnectionPrefix = 3
    static public let okPrefix = 4
    static public let accuserReceptionPrefix = 5
    static public let activeIdPrefix = 6
    static public let endTransmissionPrefix = 7
    static public let hotspotIpPrefix = 8
    static public let successPrefix = 9
    static public let failPrefix = 10
    static public let readyPrefix = 11
    static public let gamesetPrefix = 12
    static public let gameTeamPrefix = 13
    static public let reconnectedPrefix = 14
    static public let requestPrefix = 15
    static public let resultPrefix = 16

    public func getTransferableBytes() -> [UInt8] {
        size = fileBytes.count
        var prefixString = String(prefix) + TransferPrefix.delimiter + String(size)
        prefixString += TransferPrefix.delimiter + optionalArgument1 + TransferPrefix.delimiter
        prefixString += optionalArgument2 + TransferPrefix.delimiter
        var prefixUsefulBytes = Array(prefixString.utf8)
        var prefixBytes = [UInt8](repeating: 0, count: TransferPrefix.prefixSize)
        for i in 0..<prefixUsefulBytes.count {
            prefixBytes[i] = prefixUsefulBytes[i]
        }
        return prefixBytes + fileBytes
    }

    public func getTransferableData() -> Data {
        return Data(getTransferableBytes())
    }
}
