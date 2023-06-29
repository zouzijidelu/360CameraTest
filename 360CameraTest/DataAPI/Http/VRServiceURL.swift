//
//  VRServiceURL.swift
//  VRCapture_iOS
//
//  Created by wzb on 2023/5/9.
//

import UIKit
struct VRServiceURL {
//#if BETAVERSION // 判断是否在测试环境下
//    static let baseUrl = "https://uat-i-app-vr.5i5j.com/"
//#elseif DEVVERSION
    static let baseUrl = "https://sit-app-vr.5i5j.com/"
//#else
//    static let baseUrl = "https://app-vr.5i5j.com/"
//#endif
}

//EPG
extension VRServiceURL {
    static let getobsinfo = baseUrl + "vr/v1/appapi/getobsinfo"
    static let addtask = baseUrl + "vr/v1/appapi/addtask"
    static let uploadtask = baseUrl + "vr/v1/appapi/uploadtask"
}
