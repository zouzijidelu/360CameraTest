//
//  VRUploadTaskModel.swift
//  VRCapture_iOS
//
//  Created by wzb on 2023/5/10.
//

import UIKit

class VRUploadTask: VRMappable {
    var status: String?
    var data: VRUploadTaskData?
    var code: Int?
    var message: String?
    
}

class VRUploadTaskData: VRMappable {}
