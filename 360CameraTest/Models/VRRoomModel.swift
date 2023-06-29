//
//  VRRoomModel.swift
//  VRCapture_iOS
//
//  Created by wzb on 2023/5/17.
//

import UIKit
//{"doorFace":1,"needMosaic":2,"panoInfoList":[{"fileName":"1684316298406.jpg","floor":1,"needMosaic":2,"roomTitle":"房间A"},{"fileName":"1684316394841.jpg","floor":1,"needMosaic":2,"roomTitle":"房间A"}]}])
class VRRoomModel: VRMappable {
    var doorFace: Int?
    var needMosaic: Int?
    var panoInfoList: [VRPanoInfoList]?
}

class VRPanoInfoList: VRMappable {
    var fileName: String?
    var floor: String?
    var needMosaic: String?
    var roomTitle: String?
}
