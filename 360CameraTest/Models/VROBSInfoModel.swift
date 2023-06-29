//
//  VROBSInfoModel.swift
//  VRCapture_iOS
//
//  Created by wzb on 2023/5/9.
//

import UIKit

class VROBSInfo: VRMappable {
    var status: String?
    var data: VROBSInfoData?
    var code: Int?
    var message: String?
    
}

class VROBSInfoData: VRMappable {
    var ak: String?
    var sk: String?
    var bucketName: String?
    var endPoint: String?
}
