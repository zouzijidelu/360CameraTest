//
//  VRCommonWebVC.swift
//  VRCapture_iOS
//
//  Created by wzb on 2023/5/25.
//

import UIKit
import WebKit
import SnapKit

class VRCommonWebVC: UIViewController, WKNavigationDelegate {

    var webview = WKWebView()
    var urlString: String?
    override func viewDidLoad() {
      super.viewDidLoad()
        let webview = WKWebView(frame: CGRectMake(0, 0, self.view.frame.width, self.view.frame.height))
        guard let urlStr = self.urlString, let url = URL(string: urlStr) else {return}
        let request = URLRequest(url: url)
        webview.load(request)
        self.view.addSubview(webview)
        self.view.backgroundColor = .black
        webview.scrollView.backgroundColor = .black
        webview.backgroundColor = .black
        webview.navigationDelegate = self
        
        let backBtnWH: CGFloat = 20
//        let backBtn = UIButton(frame: CGRect(x: backBtnWH, y: 56, width: backBtnWH, height: backBtnWH))
        let backBtn = UIButton(type: .custom)
        backBtn.setBackgroundImage(UIImage(named: "icon-navbar-return"), for: .normal)
        backBtn.addTarget(self, action: #selector(backAction), for: .touchUpInside)
        self.view.addSubview(backBtn)
        backBtn.backgroundColor = .clear
        backBtn.imageView?.backgroundColor = .clear
        backBtn.snp.makeConstraints { make in
            make.top.equalTo(self.view).offset(56)
            make.left.equalTo(self.view).offset(backBtnWH)
            make.width.height.equalTo(backBtnWH)
        }
        
    }
    
    func webView(_ webView: WKWebView, didStartProvisionalNavigation navigation: WKNavigation!) {
//        VRProgressHUD.show(shortText: "")
    }
    
    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
//        webview.evaluateJavaScript("document.body.style.backgroundColor=\"#000000\"")
//        self.perform(#selector(showWebView), with: nil, afterDelay: 0.2)
    }
    
    func webView(_ webView: WKWebView, didFail navigation: WKNavigation!, withError error: Error) {
//        showWebView()
    }
    
    @objc func showWebView() {
        VRProgressHUD.dismiss()
    }
    
    @objc func backAction(_ sender: Any) {
        for w in UIApplication.shared.windows {
            if w.tag == flutterTag {
                w.makeKeyAndVisible()
            }
            if w.tag == flutterToNativeTag {
                w.isHidden = true
                w.rootViewController = nil
            }
        }
    }
}

