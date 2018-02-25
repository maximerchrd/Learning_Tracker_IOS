//
//  WifiCommunication.swift
//  Learning_Tracker_IOS
//
//  Created by Maxime Richard on 24.02.18.
//  Copyright © 2018 Maxime Richard. All rights reserved.
//

import Foundation
import UIKit
import SwiftSocket

class WifiCommunication {
    let PORT_NUMBER = 9090
    var host = "xxx.xxx.x.xxx"
    var client: TCPClient?
    var classroomActivityViewController: ClassroomActivityViewController
    
    init(classroomActivityViewControllerArg: ClassroomActivityViewController) {
        classroomActivityViewController = classroomActivityViewControllerArg
    }
    
    public func connectToServer() -> Bool {
        do { try host = DbTableSettings.retrieveMaster() } catch {}
        client = TCPClient(address: host, port: Int32(PORT_NUMBER))
        let dataConverter = DataConverstion()
        
        switch client!.connect(timeout: 10) {
        case .success:
            switch client!.send(data: dataConverter.connection()) {
            case .success:
                listenToServer()
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
    
    private func listenToServer() {
        var prefix = "not initialized"
        DispatchQueue.global(qos: .background).async {
            while (self.client != nil) {
                let data = self.client!.read(40, timeout: 5400)
                if data != nil {
                    prefix = String(bytes: data!, encoding: .utf8) ?? "oops, problem"
                    print(prefix)
                    let typeID = prefix.components(separatedBy: ":")[0]
                    
                    if typeID.range(of:"MULTQ") != nil {
                        let imageSize:Int? = Int(prefix.components(separatedBy: ":")[1])
                        var textSizeString = prefix.components(separatedBy: ":")[2]
                        textSizeString = String(textSizeString.filter { "01234567890.".contains($0) })
                        let textSize:Int? = Int(textSizeString)
                        
                        let dataText = self.client!.read(textSize!)
                        let dataImage = self.client!.read(imageSize!)
                        print(String(bytes: dataText!, encoding: .utf8) ?? "oops, problem")
                        
                        DispatchQueue.main.async {
                            var questionMCToDisplay = DataConverstion.bytesToMultq(textData: dataText, imageData: dataImage)
                            self.classroomActivityViewController.showMultipleChoiceQuestion(strin: questionMCToDisplay.Question)
                        }
                    } else if typeID.range(of:"SHRTA") != nil {
                        
                    } else if typeID.range(of:"QID") != nil {
                        DispatchQueue.main.async {

                        }
                    } else if typeID.range(of:"EVAL") != nil {
                        
                    } else if typeID.range(of:"UPDEV") != nil {
                        
                    }
                }
            }
        }
    }
}
