//
//  DisplayWebContentController.swift
//  Learning_Tracker_IOS
//
//  Created by Maxime Richard on 23.10.18.
//  Copyright © 2018 Maxime Richard. All rights reserved.
//

import UIKit
import WebKit

class DisplayWebContentController: UIViewController, WKUIDelegate {
    
    var webView: WKWebView!
    var url = URL(string: "")
    
    override func loadView() {
        super.loadView()
        let webConfiguration = WKWebViewConfiguration()
        webView = WKWebView(frame: .zero, configuration: webConfiguration)
        webView.uiDelegate = self
        view = webView
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        webView.loadFileURL(url!, allowingReadAccessTo: url!)
    }
    
}
