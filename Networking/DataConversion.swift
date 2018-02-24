//
//  DataConversion.swift
//  Learning_Tracker_IOS
//
//  Created by Maxime Richard on 24.02.18.
//  Copyright © 2018 Maxime Richard. All rights reserved.
//

import Foundation
import UIKit

class DataConverstion {
    
    public func connection() -> Data {
        var input = "problem retrieving name from DB"
        do {
        try input = "CONN" + "///"
            + UIDevice.current.identifierForVendor!.uuidString + "///"
            + DbTableSettings.retrieveName()
        } catch {}
        let dataUTF8 = input.data(using: .utf8)!
        return dataUTF8
    }
}
