//
//  VRPreView.swift
//  SdkSample
//
//  Copyright 2023 Ricoh Co, Ltd.
//

import Foundation
import WebKit

class VRPreView: WKWebView, WKNavigationDelegate {
    var imageUrl: String?
    var isInitialized = false
    
    
    override init(frame: CGRect, configuration: WKWebViewConfiguration) {
        super.init(frame: frame, configuration: configuration)
        loadViewer()
    }

    init(frame: CGRect) {
        let config = WKWebViewConfiguration()
        config.allowsInlineMediaPlayback = true
        config.setValue(true, forKey: "_allowUniversalAccessFromFileURLs")
        super.init(frame: frame, configuration: config)
        loadViewer()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        loadViewer()
    }
    
    func loadViewer() {
        navigationDelegate = self
        let path: String = Bundle.main.path(forResource: "index", ofType: "html")!
        let localHtmlUrl: URL = URL(fileURLWithPath: path, isDirectory: false)
        loadFileURL(localHtmlUrl, allowingReadAccessTo: localHtmlUrl)
        configuration.userContentController = WKUserContentController()
        self.isOpaque = false
        self.backgroundColor = .black
    }
    
    func updateImage(imageUrl: String) {
        self.imageUrl = imageUrl
        
        callUpdate()
    }
    
    func callUpdate() {
        if isInitialized && imageUrl != nil {
            evaluateJavaScript("update('\(imageUrl!)');")
        }
    }
    
    // MARK: - WKNavigationDelegate
    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        isInitialized = true
        callUpdate();
    }
}
