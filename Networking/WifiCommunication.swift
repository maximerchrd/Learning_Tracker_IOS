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
import CocoaAsyncSocket

class WifiCommunication: NSObject, GCDAsyncUdpSocketDelegate {
    let PORT_NUMBER = 9090
    var host = "xxx.xxx.x.xxx"
    var client: TCPClient?
    var classroomActivityViewController: ClassroomActivityViewController?
    var pendingAnswer = "none"
    var peeridUidDictionary = [String:MCPeerID]()
    var socket:GCDAsyncUdpSocket!
    
    init(classroomActivityViewControllerArg: ClassroomActivityViewController) {
        classroomActivityViewController = classroomActivityViewControllerArg
    }
    
    public func connectToServer() {
        var threadProperty = DispatchQoS.QoSClass.utility
        if AppDelegate.locked {
            threadProperty = DispatchQoS.QoSClass.userInteractive
        }
        DispatchQueue.global(qos: threadProperty).async {
            //reinitialize ip address to check if we get it from automatic connection
            self.host = "xxx.xxx.x.xxx"
            
            //first check if we are connected to a wifi network
            if self.currentSSIDs().count == 0 {
                self.displayInstructions(instructionIndex: 0)
            } else {
                //try to connect automatically
                var automaticConnection = 1
                var automaticConnectionSuccess = true
                do {
                    automaticConnection = try DbTableSettings.retrieveAutomaticConnection()
                } catch let error {
                    print(error)
                }
                
                if automaticConnection == 1 && !AppDelegate.locked {
                    self.listenForIPThroughUDP()
                    for _ in 0..<10 {
                        Thread.sleep(forTimeInterval: 0.5)
                        if self.host != "xxx.xxx.x.xxx" {
                            break
                        }
                    }
                    if self.host == "xxx.xxx.x.xxx" {
                        do { try self.host = DbTableSettings.retrieveMaster() } catch {}
                        self.displayInstructions(instructionIndex: 3)
                        automaticConnectionSuccess = false
                        self.socket.close()
                    }
                } else {
                    do { try self.host = DbTableSettings.retrieveMaster() } catch {}
                }
                AppDelegate.locked = false
                
                self.client = TCPClient(address: self.host, port: Int32(self.PORT_NUMBER))
                let dataConverter = DataConversion()
                
                switch self.client!.connect(timeout: 4) {
                case .success:
                    if AppDelegate.disconnectionSignalWithoutConnectionYet != "" {
                        self.client!.send(data: AppDelegate.disconnectionSignalWithoutConnectionYet.data(using: .utf8)!)
                    }
                    switch self.client!.send(data: dataConverter.connection()) {
                    case .success:
                        if automaticConnectionSuccess {
                            self.displayInstructions(instructionIndex: 1)
                        }
                        DispatchQueue.global(qos: .utility).async {
                            self.listenToServer()
                        }
                    case .failure(let error):
                        if automaticConnectionSuccess {
                            self.displayInstructions(instructionIndex: 2)
                        }
                        DbTableLogs.insertLog(log: error.localizedDescription)
                        print(error)
                    }
                case .failure(let error):
                    if automaticConnectionSuccess {
                        self.displayInstructions(instructionIndex: 2)
                    }
                    if error.localizedDescription.contains("3") {
                        DbTableLogs.insertLog(log: error.localizedDescription + "(could connect to ip but server not running?)")
                    } else {
                        DbTableLogs.insertLog(log: error.localizedDescription + "(ip not valid?)")
                    }
                    print(error)
                }
            }
        }
    }
    
    public func listenToServer() {
        var prefix = "not initialized"
        var ableToRead = true
        
        while (self.client != nil && self.client?.fd != nil && ableToRead) {
            let data = self.client!.read(80, timeout: 40000)
            if data != nil {
                prefix = String(bytes: data!, encoding: .utf8) ?? "oops, problem in listenToServer(): prefix is nil"
                if prefix.contains("oops, problem in listenToServer(): prefix is nil") {
                    DbTableLogs.insertLog(log: prefix)
                    print(prefix)
                    sendDisconnectionSignal(additionalInformation: "close-connection")
                    DispatchQueue.main.async {
                        AppDelegate.wifiCommunicationSingleton?.classroomActivityViewController?.stopConnectionAlerting()
                    }
                    break
                }
                print(prefix)
                let typeID = prefix.components(separatedBy: "///")[0].components(separatedBy: ":")[0]
                
                if typeID.range(of:"MULTQ") != nil {
                    self.readAndStoreQuestion(prefix: prefix, typeOfQuest: typeID, prefixData: data!)
                } else if typeID.range(of:"SHRTA") != nil {
                    self.readAndStoreQuestion(prefix: prefix, typeOfQuest: typeID, prefixData: data!)
                } else if typeID.range(of:"QID") != nil {
                    ReceptionProtocol.receivedQID(prefix: prefix)
                } else if typeID.elementsEqual("EVAL") {
                    ReceptionProtocol.receivedEVAL(prefix: prefix)
                } else if typeID.range(of:"UPDEV") != nil {
                    ReceptionProtocol.receivedUPDEV(prefix: prefix)
                } else if typeID.range(of:"CORR") != nil {
                    ReceptionProtocol.receivedCORR(prefix: prefix)
                } else if typeID.range(of:"TEST") != nil {
                    ReceptionProtocol.receivedTESTFromServer(prefix: prefix)
                } else if typeID.range(of:"TESYN") != nil {
                    //ReceptionProtocol.receivedTESYNFromServer(prefix: prefix)
                } else if typeID.elementsEqual("OEVAL") {
                    ReceptionProtocol.receivedOEVALFromServer(prefix: prefix)
                } else {
                    DbTableLogs.insertLog(log: "message received but prefix not supported: " + prefix)
                    print("message received but prefix not supported")
                }
            } else {
                ableToRead = false
            }
        }
        
    }
    
    public func sendAnswerToServer(answer: String, globalID: Int64, questionType: String, timeSpent: String) {
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
            message += (answer + "///" + question + "///" + String(globalID)) + "///" + timeSpent;
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
        if client != nil {
            client!.send(data: data)
        }
    }
    
    public func sendDisconnectionSignal(additionalInformation: String = "") {
        print("student is leaving the task")
        do {
            let message = try "DISC///" + UIDevice.current.identifierForVendor!.uuidString + "///" + DbTableSettings.retrieveName() + "///" +
            additionalInformation + "///"
            AppDelegate.disconnectionSignalWithoutConnectionYet = message
            if client != nil {
                client!.send(string: message)
                Thread.sleep(forTimeInterval: 0.7)
                AppDelegate.disconnectionSignalWithoutConnectionYet = ""
            }
        } catch let error {
            print(error)
        }
    }
    
    fileprivate func readAndStoreQuestion(prefix: String, typeOfQuest: String, prefixData: [UInt8]) {
        if prefix.components(separatedBy: ":").count > 1 {
            let imageSize = Int(prefix.components(separatedBy: ":")[1]) ?? 0
            var textSizeString = prefix.components(separatedBy: ":")[2]
            textSizeString = String(textSizeString.filter { "01234567890.".contains($0) })
            let textSize = Int(textSizeString) ?? 0
            
            let dataText = self.readDataIntoArray(expectedSize: textSize )

            print(imageSize)
            let dataImage = self.readDataIntoArray(expectedSize: imageSize)

            print("Image size actually read:" + String(dataImage.count))
            let dataTextString = String(bytes: dataText, encoding: .utf8) ?? "oops, problem in readAndStoreQuestion: dataText to string yields nil"
            if dataTextString.contains("oops") {
                DbTableLogs.insertLog(log: dataTextString)
            }
            print(dataTextString)
            var questionID:Int64 = -1
            do {
                if typeOfQuest.range(of: "MULTQ") != nil {
                    let questionMult = DataConversion.bytesToMultq(textData: dataText, imageData: dataImage)
                    questionID = questionMult.ID
                    if questionMult.Question != "error" {
                        try DbTableQuestionMultipleChoice.insertQuestionMultipleChoice(Question: questionMult)
                    }
                } else if typeOfQuest.range(of: "SHRTA") != nil {
                    let questionShrt = DataConversion.bytesToShrtaq(textData: dataText, imageData: dataImage)
                    questionID = questionShrt.ID
                    if questionShrt.Question != "error" {
                        try DbTableQuestionShortAnswer.insertQuestionShortAnswer(Question: questionShrt)
                    }
                }
            } catch let error {
                print(error)
            }
        } else {
            DbTableLogs.insertLog(log: "error reading questions: prefix not in correct format or buffer truncated")
            print("error reading questions: prefix not in correct format or buffer truncated")
        }
    }
    
    func stopConnection() {
        if self.client != nil {
            sendDisconnectionSignal(additionalInformation: "close-connection")
            self.client!.close()            //sets the file descriptor to nil
        }
    }
    
    func startConnection() {
        DispatchQueue.global(qos: .utility).async {
            self.connectToServer()
        }
    }
    
    fileprivate func displayInstructions(instructionIndex: Int) {
        DispatchQueue.main.async {
            switch instructionIndex {
            case 0:
                self.classroomActivityViewController?.InstructionsLabel.text = NSLocalizedString("AND CONNECT TO THE RIGHT WIFI NETWORK", comment: "instruction NO NETWORK after the KEEP CALM")
            case 1:
                self.classroomActivityViewController?.InstructionsLabel.text = NSLocalizedString("AND WAIT FOR NEXT QUESTION", comment: "instruction after the KEEP CALM")
            case 2:
                self.classroomActivityViewController?.InstructionsLabel.text = NSLocalizedString("AND RESTART THE CLASSROOM ACTIVITY (but before, check that you have the right IP address in settings)", comment: "instruction after the KEEP CALM if connection failed")
            case 3:
                self.classroomActivityViewController?.InstructionsLabel.text = "Automatic connection failed. If it keeps failing, set the ip address of the teacher manually in \"Settings\""
            default:
                print("Display instruction not recognized")
            }
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

    public func readDataIntoArray(expectedSize: Int) -> [UInt8] {
        //read data
        var arrayToFill = [UInt8]()
        var ableToRead = true
        while self.client != nil && self.client?.fd != nil && ableToRead && arrayToFill.count < expectedSize {
            let data = self.client!.read(expectedSize - arrayToFill.count, timeout: 3)
            if data != nil {
                arrayToFill += data ?? [UInt8]()
            } else {
                ableToRead = false
            }
        }
        return arrayToFill
    }
    
    //START UDP COMMUNICATION STUFFS
    fileprivate func listenForIPThroughUDP() {
        do {
            if socket == nil {
                socket = GCDAsyncUdpSocket(delegate: self, delegateQueue: DispatchQueue.main)
            }
            try socket.enableBroadcast(true)
            try socket.bind(toPort: 9346)
            try socket.beginReceiving()
            
        } catch let error {
            print(error)
        }
    }
    
    func udpSocket(_ sock: GCDAsyncUdpSocket, didReceive data: Data, fromAddress address: Data, withFilterContext filterContext: Any?) {
        let receivedMessage = String(data: data, encoding: .utf8) ?? "couldn't read message"
        print(receivedMessage)
        
        if receivedMessage.components(separatedBy: "///")[0] == "IPADDRESS" {
            self.host = receivedMessage.components(separatedBy: "///")[1]
            DbTableSettings.setMaster(master: receivedMessage.components(separatedBy: "///")[1])
        }
        socket.close()
    }
    //END UDP COMMUNICATION STUFFS
}
