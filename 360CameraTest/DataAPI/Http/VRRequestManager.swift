//
//  VRRequestManager.swift
//  VRCapture_iOS
//
//  Created by wzb on 2023/5/9.
//

import UIKit

import Alamofire
//import HandyJSON

internal class VRRequestManager {
    
    // MARK: Private variables
    private static var sessionManager: VRSessionManager {
        get {
            let sessionManager = SessionManagerWrapper.sessionManager
            sessionManager.headers["Content-Type"] = "application/json"
            sessionManager.headers["token"] = Preference[.token]
            return sessionManager
        }
    }
        
    private struct SessionManagerWrapper {
        static var sessionManager = VRSessionManager()
        
    }
    
    private struct DataError: Error {
        var code: Int
        var message: String
        var localizedDescription: String {
            return message
        }
    }
    
    static func request(request: VRRequest) {
        
        sessionManager.request(request: request) { (response) in
            

            switch response.result {
            case .success(let data):
                parseResponseData(request: request, valueData: data)
            case .failure(let error):
                if let data = response.data, let json = VRDataSerialization.dataToJSON(data: data) {
                    let error: VRDataError? = VRDataSerialization.convertToNullableModel(responseResult: json)
                    if let e = error {
                        request.failure?(e)
                    } else {
                        request.failure?(VRDataError.unknown)
                    }
                    
                } else {
                    let errT = VRDataError(code: response.response?.statusCode ?? VRDataError.unknown.code,
                                           message: error.localizedDescription)
                    printLog("\(String(describing: response.request?.url)) --- request failure response: \(response)")
                    request.failure?(errT)
                }
            }
        }
    }
    
    private static func parseResponseData(
        request: VRRequest,
        valueData: Any?) {
        request.success?(valueData)
    }
    
    private static func parseErrorData(request: VRRequest,
                                       valueData: Any?,
                                       response: HTTPURLResponse?) {
        
        if let valueData = valueData { // 有服务器返回错误码
            let model = VRDataSerialization.toModelObject(valueData, to: VRDataError.self)
//            if model?.code == VRDataError.internalTokenInvalidCode {// token过期
//            } else if model?.code == VRDataError.internalMoreDeviceLoginTokenInvalidCode {// 多设备登陆 直接退出
//
//            } else {
//
//            }
        } else { // 超时或服务器错误
            var error = VRDataError(code: response?.statusCode ?? VRDataError.unknown.code,
                                    message: VRDataError.unknown.message)
            
            request.failure?(error)
        }
    }
}

extension VRRequestManager {
    
}

