//
//  WifiCommunication.swift
//  Learning_Tracker_IOS
//
//  Created by Maxime Richard on 24.02.18.
//  Copyright © 2018 Maxime Richard. All rights reserved.
//

import Foundation
import SwiftSocket

class WifiCommunication {
    let PORT_NUMBER = 9090
    var host = "xxx.xxx.x.xxx"
    var client: TCPClient?
    
    public func connectToServer() -> Bool {
        do { try host = DbTableSettings.retrieveMaster() } catch {}
        client = TCPClient(address: host, port: Int32(PORT_NUMBER))
        let dataConverter = DataConverstion()
        
        switch client!.connect(timeout: 10) {
        case .success:
            switch client!.send(data: dataConverter.connection()) {
            case .success:
                return true
            case .failure(let error):
                print(error)
                return false
            }
        case .failure(let error):
            print(error)
            return false
        }
    }
}
