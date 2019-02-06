class ClientToServerTransferable {
    var prefix = -1
    var size = -1
    var optionalArgument1 = ""
    var fileBytes = [UInt8]()

    public func getTransferableBytes() -> [UInt8] {
        var prefixString = String(prefix) + ClientToServerTransferable.delimiter + String(size)
        prefixString += ClientToServerTransferable.delimiter + optionalArgument1
        var prefixUsefulBytes = Array(prefixString.utf8)
        var prefixBytes = [UInt8]()
        prefixBytes.reserveCapacity(ClientToServerTransferable.prefixSize)
        for i in 0..<prefixUsefulBytes.count {
            prefixBytes[i] = prefixUsefulBytes[i]
        }
        return prefixBytes + fileBytes
    }

    private static let delimiter = "/"
    private static let prefixSize = 80
}