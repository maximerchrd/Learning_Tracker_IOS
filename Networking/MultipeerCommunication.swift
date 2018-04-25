//
//  MultipeerCommunication.swift
//  Learning_Tracker_IOS
//
//  Created by Maxime Richard on 25.04.18.
//  Copyright © 2018 Maxime Richard. All rights reserved.
//

import Foundation
import MultipeerConnectivity

protocol MultipeerCommunicationDelegate {
    
    func connectedDevicesChanged(manager : MultipeerCommunication, connectedDevices: [String])
    func colorChanged(manager : MultipeerCommunication, colorString: String)
    
}


class MultipeerCommunication : NSObject{
    // Service type must be a unique string, at most 15 characters long
    // and can contain only ASCII lowercase letters, numbers and hyphens.
    private let MPComServiceType = "koeko-app"
    
    private let MPComPeerId = MCPeerID(displayName: UIDevice.current.name)
    private let serviceAdvertiser : MCNearbyServiceAdvertiser
    private let serviceBrowser : MCNearbyServiceBrowser
    
    var delegate : MultipeerCommunicationDelegate?
    
    func send(data : Data) {
        NSLog("%@", "send message to \(session.connectedPeers.count) peers")
        
        if session.connectedPeers.count > 0 {
            do {
                try self.session.send(data, toPeers: session.connectedPeers, with: .reliable)
            }
            catch let error {
                NSLog("%@", "Error for sending: \(error)")
            }
        }
        
    }

    
    override init() {
        self.serviceAdvertiser = MCNearbyServiceAdvertiser(peer: MPComPeerId, discoveryInfo: nil, serviceType: MPComServiceType)
        self.serviceBrowser = MCNearbyServiceBrowser(peer: MPComPeerId, serviceType: MPComServiceType)
        
        super.init()
    }
    
    func connectToPeers() {
        self.serviceAdvertiser.delegate = self
        self.serviceAdvertiser.startAdvertisingPeer()
        
        self.serviceBrowser.delegate = self
        self.serviceBrowser.startBrowsingForPeers()
    }
    
    lazy var session : MCSession = {
        let session = MCSession(peer: self.MPComPeerId, securityIdentity: nil, encryptionPreference: .required)
        session.delegate = self
        return session
    }()
    
    deinit {
        self.serviceAdvertiser.stopAdvertisingPeer()
        self.serviceBrowser.stopBrowsingForPeers()
    }
}

extension MultipeerCommunication : MCNearbyServiceAdvertiserDelegate {
    
    func advertiser(_ advertiser: MCNearbyServiceAdvertiser, didNotStartAdvertisingPeer error: Error) {
        NSLog("%@", "didNotStartAdvertisingPeer: \(error)")
    }
    
    func advertiser(_ advertiser: MCNearbyServiceAdvertiser, didReceiveInvitationFromPeer peerID: MCPeerID, withContext context: Data?, invitationHandler: @escaping (Bool, MCSession?) -> Void) {
        NSLog("%@", "didReceiveInvitationFromPeer \(peerID)")
        invitationHandler(true, self.session)
    }
    
}

extension MultipeerCommunication : MCNearbyServiceBrowserDelegate {
    
    func browser(_ browser: MCNearbyServiceBrowser, didNotStartBrowsingForPeers error: Error) {
        NSLog("%@", "didNotStartBrowsingForPeers: \(error)")
    }
    
    func browser(_ browser: MCNearbyServiceBrowser, foundPeer peerID: MCPeerID, withDiscoveryInfo info: [String : String]?) {
        NSLog("%@", "foundPeer: \(peerID)")
        NSLog("%@", "invitePeer: \(peerID)")
        browser.invitePeer(peerID, to: self.session, withContext: nil, timeout: 10)
    }
    
    func browser(_ browser: MCNearbyServiceBrowser, lostPeer peerID: MCPeerID) {
        NSLog("%@", "lostPeer: \(peerID)")
    }
    
}

extension MultipeerCommunication : MCSessionDelegate {
    
    func session(_ session: MCSession, peer peerID: MCPeerID, didChange state: MCSessionState) {
        NSLog("%@", "peer \(peerID) didChangeState: \(state)")
        self.delegate?.connectedDevicesChanged(manager: self, connectedDevices:
            session.connectedPeers.map{$0.displayName})
    }
    
    func session(_ session: MCSession, didReceive data: Data, fromPeer peerID: MCPeerID) {
        NSLog("%@", "didReceiveData: \(data)")
        var prefix = ""
        if data.count < 40 {
            prefix = String(data: data.subdata(in: 0..<data.count), encoding: .utf8)!
        } else {
            prefix = String(data: data.subdata(in: 0..<40), encoding: .utf8)!
        }
        print(prefix)
        let typeID = prefix.components(separatedBy: ":")[0]
        
        if typeID.range(of:"MULTQ") != nil {
            DataConverstion.storeQuestionFromData(typeOfQuest: typeID, questionData: data, prefix: prefix)
        } else if typeID.range(of:"SHRTA") != nil {
            DataConverstion.storeQuestionFromData(typeOfQuest: typeID, questionData: data, prefix: prefix)
        } else if typeID.range(of:"QID") != nil {
            DispatchQueue.main.async {
                var questionMultipleChoice = QuestionMultipleChoice()
                var questionShortAnswer = QuestionShortAnswer()
                if (prefix.components(separatedBy: ":")[1].contains("MLT")) {
                    let id_global = Int(prefix.components(separatedBy: "///")[1])
                    let directCorrection = Int(prefix.components(separatedBy: "///")[2]) ?? 0
                    do {
                        questionMultipleChoice = try DbTableQuestionMultipleChoice.retrieveQuestionMultipleChoiceWithID(globalID: id_global!)
                        
                        if questionMultipleChoice.Question.count > 0 && questionMultipleChoice.Question != "none" {
                            AppDelegate.wifiCommunicationSingleton?.classroomActivityViewController?.showMultipleChoiceQuestion(question:  questionMultipleChoice, isCorr: false, directCorrection: directCorrection)
                        } else {
                            questionShortAnswer = try DbTableQuestionShortAnswer.retrieveQuestionShortAnswerWithID(globalID: id_global!)
                            AppDelegate.wifiCommunicationSingleton?.classroomActivityViewController?.showShortAnswerQuestion(question: questionShortAnswer, isCorr: false, directCorrection: directCorrection)
                        }
                    } catch let error {
                        print(error)
                    }
                }
            }
        }
    }
    
    func session(_ session: MCSession, didReceive stream: InputStream, withName streamName: String, fromPeer peerID: MCPeerID) {
        NSLog("%@", "didReceiveStream")
    }
    
    func session(_ session: MCSession, didStartReceivingResourceWithName resourceName: String, fromPeer peerID: MCPeerID, with progress: Progress) {
        NSLog("%@", "didStartReceivingResourceWithName")
    }
    
    func session(_ session: MCSession, didFinishReceivingResourceWithName resourceName: String, fromPeer peerID: MCPeerID, at localURL: URL?, withError error: Error?) {
        NSLog("%@", "didFinishReceivingResourceWithName")
    }
    
}
