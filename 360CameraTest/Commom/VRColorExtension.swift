//
//  HXColorUtil.swift
//  huanxin_swift
//
//  Created by z on 06/12/2016.
//  Copyright © 2016 iTalkTV.hk. All rights reserved.
//

import UIKit
//十六进制颜色转换
extension UIColor {
    
    class func transferStringToColor(_ colorStr:String) -> UIColor {
        
        var color = UIColor.red
        var cStr : String = colorStr.trimmingCharacters(in: CharacterSet.whitespacesAndNewlines).uppercased()
        
        if cStr.hasPrefix("#") {
            let index = cStr.index(after: cStr.startIndex)
            // cStr = cStr.substring(from: index)
            cStr = String(cStr[index...])
        }
        if cStr.count != 6 {
            return UIColor.black
        }
        
        let rRange = cStr.startIndex ..< cStr.index(cStr.startIndex, offsetBy: 2)
        // let rStr = cStr.substring(with: rRange)
        let rStr = String(cStr[rRange])
        let gRange = cStr.index(cStr.startIndex, offsetBy: 2) ..< cStr.index(cStr.startIndex, offsetBy: 4)
        // let gStr = cStr.substring(with: gRange)
        let gStr = String(cStr[gRange])
        let bIndex = cStr.index(cStr.endIndex, offsetBy: -2)
        // let bStr = cStr.substring(from: bIndex)
        let bStr = String(cStr[bIndex...])
        var r:CUnsignedInt = 0, g:CUnsignedInt = 0, b:CUnsignedInt = 0;
        Scanner(string: rStr).scanHexInt32(&r)
        Scanner(string: gStr).scanHexInt32(&g)
        Scanner(string: bStr).scanHexInt32(&b)
        
        color = UIColor(red: CGFloat(r) / 255.0, green: CGFloat(g) / 255.0, blue: CGFloat(b) / 255.0, alpha: CGFloat(1))
        
        return color
    }
}
