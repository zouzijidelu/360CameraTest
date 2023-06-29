//
//  VRProgressHUD.swift
//  VRCapture_iOS
//
//  Created by wzb on 2023/5/19.
//

import UIKit

class VRProgressHUD {
    static func show(shortText: String) {
        DispatchQueue.main.async {
            ProgressHUD.animationType = .circleStrokeSpin
            ProgressHUD.colorStatus = .white
            ProgressHUD.colorHUD = UIColor(red: 0, green: 0, blue: 0, alpha: 0.8)
            ProgressHUD.colorAnimation = .white
            ProgressHUD.show(shortText,interaction: false)
        }
    }
    
    static func dismiss() {
        DispatchQueue.main.async {
            ProgressHUD.dismiss()
            ProgressHUD.remove()
        }
    }
    
    static func showFailed(shortText: String) {
        DispatchQueue.main.async {
            ProgressHUD.animationType = .circleStrokeSpin
            ProgressHUD.colorStatus = .white
            ProgressHUD.colorHUD = UIColor(red: 0, green: 0, blue: 0, alpha: 0.8)
            ProgressHUD.colorAnimation = .white
            ProgressHUD.showFailed(shortText)
        }
    }
    
    static func showSuccess(shortText: String) {
        DispatchQueue.main.async {
            ProgressHUD.animationType = .circleStrokeSpin
            ProgressHUD.colorStatus = .white
            ProgressHUD.colorHUD = UIColor(red: 0, green: 0, blue: 0, alpha: 0.8)
            ProgressHUD.colorAnimation = .white
            ProgressHUD.showSucceed(shortText)
        }
    }
}
