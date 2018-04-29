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
import SystemConfiguration.CaptiveNetwork
import MultipeerConnectivity

class WifiCommunication {
    let PORT_NUMBER = 9090
    var host = "xxx.xxx.x.xxx"
    var client: TCPClient?
    var classroomActivityViewController: ClassroomActivityViewController?
    var pendingAnswer = "none"
    let multipeerCommunication = MultipeerCommunication()
    var peeridUidDictionary = [String:MCPeerID]()
    
    init(classroomActivityViewControllerArg: ClassroomActivityViewController) {
        classroomActivityViewController = classroomActivityViewControllerArg
    }
    
    public func connectToServer() -> Bool {
        //first stop advertising and browsing if we are trying to reinitialize connection
        multipeerCommunication.stopAdvertisingAndBrowsing()
        if currentSSIDs().count == 0 {
            //first connect to peers if Multipeer enabled
            if (DbTableSettings.retrieveMultipeer()) {
                AppDelegate.isFirstLayer = false
                multipeerCommunication.connectToPeers()
            }
            return true
        } else {
            do { try host = DbTableSettings.retrieveMaster() } catch {}
            client = TCPClient(address: host, port: Int32(PORT_NUMBER))
            let dataConverter = DataConversion()
            
            switch client!.connect(timeout: 4) {
            case .success:
                switch client!.send(data: dataConverter.connection()) {
                case .success:
                    AppDelegate.isFirstLayer = true
                    DispatchQueue.global(qos: .utility).async {
                        self.listenToServer()
                    }
                    if (DbTableSettings.retrieveMultipeer()) {
                        multipeerCommunication.connectToPeers()
                    }
                    return true
                case .failure(let error):
                    AppDelegate.isFirstLayer = false
                    DbTableLogs.insertLog(log: error.localizedDescription)
                    print(error)
                    return false
                }
            case .failure(let error):
                AppDelegate.isFirstLayer = false
                if error.localizedDescription.contains("3") {
                    DbTableLogs.insertLog(log: error.localizedDescription + "(could connect to ip but server not running?)")
                } else {
                    DbTableLogs.insertLog(log: error.localizedDescription + "(ip not valid?)")
                }
                print(error)
                return false
            }
        }
    }
    
    public func listenToServer() {
        var prefix = "not initialized"
        var ableToRead = true
        
        while (self.client != nil && ableToRead) {
            let data = self.client!.read(80, timeout: 5400)
            if data != nil {
                prefix = String(bytes: data!, encoding: .utf8) ?? "oops, problem in listenToServer(): prefix is nil"
                if prefix.contains("oops") {
                    DbTableLogs.insertLog(log: prefix)
                    print(prefix)
                    fatalError()
                }
                print(prefix)
                let typeID = prefix.components(separatedBy: "///")[0].components(separatedBy: ":")[0]
                
                if typeID.range(of:"MULTQ") != nil {
                    self.readAndStoreQuestion(prefix: prefix, typeOfQuest: typeID, prefixData: data!)
                } else if typeID.range(of:"SHRTA") != nil {
                    self.readAndStoreQuestion(prefix: prefix, typeOfQuest: typeID, prefixData: data!)
                } else if typeID.range(of:"QID") != nil {
                    let receptionString = "GOTIT///" + prefix.components(separatedBy: "///")[2]
                    self.sendData(data: receptionString.data(using: .utf8)!)
                    ReceptionProtocol.receivedQID(prefix: prefix)
                    //forward if Multipeer activated
                    /*if DbTableSettings.retrieveMultipeer() {
                        let wholeData = Data(bytes: data!)
                        multipeerCommunication.sendToAll(data: wholeData)
                    }*/
                } else if typeID.range(of:"EVAL") != nil {
                    ReceptionProtocol.receivedEVAL(prefix: prefix)
                } else if typeID.range(of:"UPDEV") != nil {
                    ReceptionProtocol.receivedUPDEV(prefix: prefix)
                } else if typeID.range(of:"CORR") != nil {
                    ReceptionProtocol.receivedCORR(prefix: prefix)
                } else if typeID.range(of:"TEST") != nil {
                    ReceptionProtocol.receivedTESTFromServer(prefix: prefix)
                } else if typeID.range(of:"TESYN") != nil {
                    ReceptionProtocol.receivedTESYNFromServer(prefix: prefix)
                } else if typeID.range(of:"FRWTOPEER") != nil {
                    let receptionString = "GOTIT///" + prefix.components(separatedBy: "///")[4]
                    self.sendData(data: receptionString.data(using: .utf8)!)
                    ReceptionProtocol.receivedFRWTOPEERFromServer(prefix: prefix)
                } else {
                    DbTableLogs.insertLog(log: "message received but prefix not supported: " + prefix)
                    print("message received but prefix not supported")
                }
            } else {
                ableToRead = false
            }
        }
        
    }
    
    public func sendAnswerToServer(answer: String, globalID: Int, questionType: String) {
        pendingAnswer = answer
        var message = ""
        do {
            var question = ""
            if questionType == "ANSW0" {
                let questionMultipleChoice = try DbTableQuestionMultipleChoice.retrieveQuestionMultipleChoiceWithID(globalID: globalID)
                question = questionMultipleChoice.Question
            } else if questionType == "ANSW1" {
                let questionShortAnswer = try DbTableQuestionShortAnswer.retrieveQuestionShortAnswerWithID(globalID: globalID)
                question = questionShortAnswer.Question
            }
            let name = try DbTableSettings.retrieveName()
            message = questionType + "///" + UIDevice.current.identifierForVendor!.uuidString + "///" + name + "///"
            message += (answer + "///" + question + "///" + String(globalID));
            if client != nil {
                client!.send(string: message)
            } else {
                print("client is nil when trying to send the answer")
            }
        } catch let error {
            print(error)
        }
    }
    
    public func sendData(data: Data) {
        client!.send(data: data)
    }
    
    public func sendDisconnectionSignal() {
        print("student is leaving the task")
        do {
            let message = try "DISC///" + UIDevice.current.identifierForVendor!.uuidString + "///" + DbTableSettings.retrieveName() + "///"
            client!.send(string: message)
        } catch let error {
            print(error)
        }
    }
    
    public func receivedQuestion(questionID: String) {
        let message = "GOTIT///" + questionID + "///"
        print(message)
        client!.send(string: message)
    }
    
    fileprivate func readAndStoreQuestion(prefix: String, typeOfQuest: String, prefixData: [UInt8]) {
        if prefix.components(separatedBy: ":").count > 1 {
            let imageSize:Int? = Int(prefix.components(separatedBy: ":")[1])
            var textSizeString = prefix.components(separatedBy: ":")[2]
            textSizeString = String(textSizeString.filter { "01234567890.".contains($0) })
            let textSize:Int? = Int(textSizeString)
            
            var dataText = [UInt8]()
            while dataText.count < textSize ?? 0 {
                dataText += self.client!.read(textSize! - dataText.count) ?? [UInt8]()
            }
            print(imageSize!)
            
            var dataImage = [UInt8]()
            while dataImage.count < imageSize ?? 0 {
                dataImage += self.client!.read(imageSize! - dataImage.count) ?? [UInt8]()
            }
            print("Image size actually read:" + String(dataImage.count))
            let dataTextString = String(bytes: dataText, encoding: .utf8) ?? "oops, problem in readAndStoreQuestion: dataText to string yields nil"
            if dataTextString.contains("oops") {
                DbTableLogs.insertLog(log: dataTextString)
            }
            print(dataTextString)
            var questionID = -1
            do {
                if typeOfQuest.range(of: "MULTQ") != nil {
                    let questionMult = DataConversion.bytesToMultq(textData: dataText, imageData: dataImage)
                    questionID = questionMult.ID
                    try DbTableQuestionMultipleChoice.insertQuestionMultipleChoice(Question: questionMult)
                } else if typeOfQuest.range(of: "SHRTA") != nil {
                    let questionShrt = DataConversion.bytesToShrtaq(textData: dataText, imageData: dataImage)
                    questionID = questionShrt.ID
                    try DbTableQuestionShortAnswer.insertQuestionShortAnswer(Question: questionShrt)
                }
            } catch let error {
                print(error)
            }
            receivedQuestion(questionID: String(questionID))
            
            //forward if Multipeer activated
            if DbTableSettings.retrieveMultipeer() {
                let wholeBytesData = prefixData + dataText + dataImage
                let wholeData = Data(bytes: wholeBytesData)
                multipeerCommunication.sendToAll(data: wholeData)
            }
        } else {
            DbTableLogs.insertLog(log: "error reading questions: prefix not in correct format or buffer truncated")
            print("error reading questions: prefix not in correct format or buffer truncated")
        }
    }
    
    fileprivate func currentSSIDs() -> [String] {
        guard let interfaceNames = CNCopySupportedInterfaces() as? [String] else {
            return []
        }
        return interfaceNames.flatMap { name in
            guard let info = CNCopyCurrentNetworkInfo(name as CFString) as? [String:AnyObject] else {
                return nil
            }
            guard let ssid = info[kCNNetworkInfoKeySSID as String] as? String else {
                return nil
            }
            return ssid
        }
    }
}
