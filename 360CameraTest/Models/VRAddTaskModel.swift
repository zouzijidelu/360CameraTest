//
//  VRAddTaskModel.swift
//  VRCapture_iOS
//
//  Created by wzb on 2023/5/9.
//

import UIKit
let VRAddTaskInvalidCode = 60053 //房源已被上传
class VRAddTask: VRMappable {
    var status: String?
    var data: VRAddTaskData?
    var code: Int?
    var message: String?
}

class VRAddTaskData: VRMappable {
    var taskId: Int?
    var inputPath: String?
}
