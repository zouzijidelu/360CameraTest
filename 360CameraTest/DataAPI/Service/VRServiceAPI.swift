//
//  VRRequestManager.swift
//  VRCapture_iOS
//
//  Created by wzb on 2023/5/9.
//

import Foundation


class VRServiceAPI {
    static func getOBSInfo<T>(success: @escaping (T?) -> Void,
                               failure: @escaping(VRDataError) -> ()) where T : VRMappable {
        checkNetWork {
            failure(VRDataError.noNetwork)
        } reachable: {
            let request = VRRequest(url: VRServiceURL.getobsinfo,
                                    method: .get,
                                    success: { (data) in
                
                success(VRDataSerialization.convertToNullableModel(responseResult: data))
            },failure: failure)
            VRRequestManager.request(request: request)
        }
    }
    
    static func addTask<T>(params: [String:Any],
                           success: @escaping (T?) -> Void,
                               failure: @escaping(VRDataError) -> ()) where T : VRMappable {
//        let params: [String : Any] = ["accompanyUserName":"-","ak":"A5MPPBVER7UA9A2Q68N8","communityName":"九龙花园","doorFace":4,"houseId":"FY00254546676","houseType":4,"mainPicUrl":"/data/user/0/com.aiji.vrcapture/files/20230509_17_13_50_591_android/pano_original/1683623649077.jpg","needMosaic":2,"picPointNum":1,"remark":""]
//        let params: [String : Any] = ["userId":userId,"cityId":cityId,"houseType":houseType,"houseId":houseId,"houseTitle":houseTitle,"estateId":estateId,"houseTypeId":houseTypeId,"doorFace":doorFace,"remark":remark,"needMosaic":needMosaic,"picPointNum":picPointNum,"communityName":communityName,"accompanyUserName":accompanyUserName,"mainPicUrl":mainPicUrl,"roomInfo":roomInfo,"floor":floor,"buildArea":buildArea,"saveTime":saveTime,"uploadTime":uploadTime,"ak":ak]

        checkNetWork {
            failure(VRDataError.noNetwork)
        } reachable: {
            let request = VRRequest(url: VRServiceURL.addtask,
                                    method: .post,
                                    parameters: params,
                                    success: { (data) in
                
                success(VRDataSerialization.convertToNullableModel(responseResult: data))
            },failure: failure)
            VRRequestManager.request(request: request)
        }
        
    }
    static func upLoadTask<T>(taskId: Int, success: @escaping (T?) -> Void,
                               failure: @escaping(VRDataError) -> ()) where T : VRMappable {
        checkNetWork {
            failure(VRDataError.noNetwork)
        } reachable: {
            let params: [String : Any] = ["taskId":taskId];
            let request = VRRequest(url: VRServiceURL.uploadtask,
                                    method: .post,
                                    parameters: params,
                                    success: { (data) in
                
                success(VRDataSerialization.convertToNullableModel(responseResult: data))
            },failure: failure)
            VRRequestManager.request(request: request)
        }
        
    }
}
