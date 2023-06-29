//
//  VRRequestManager.swift
//  VRCapture_iOS
//
//  Created by wzb on 2023/5/9.
//

import Foundation

/// Describes errors in the data request.
struct VRDataError: Error,VRMappable {
//    {
//        "code": 60053,
//        "status": "failed",
//        "data": null,
//        "message": "此房源照片已被他人上传，暂无法上传"
//    }
    /// error code.
    let code: Int?
    /// description message of the error.
    var message: String?
    var data: String?
    var status: String?
    public var description: String? {
        return "{\n"
        + "\t code: \(String(describing: code))\n,"
            + "\t message: \(String(describing: message))\n"
            + "}"
    }
    
    var localizedDescription: String {
        return message ?? "Empty error message"
    }
}
// MARK: - data error constants
extension VRDataError {

    // MARK: - Base
    static let unknown = VRDataError(code: -1, message: "未知错误")
    static let timedout = VRDataError(code: -2, message: "请求超时")
    static let noNetwork = VRDataError(code: -3, message: "网络错误")

    // MARK: - 400
    static let invalidParameters = VRDataError(code: 1040001, message: "请求参数格式错误")
    // MARK: - 401
    // MARK: - 403
    // MARK: - 404
    // MARK: - 410
    // MARK: - 500
    // MARK: - 502
}

// MARK: - Equatable
extension VRDataError: Equatable {
    static func == (lhs: VRDataError, rhs: VRDataError) -> Bool {
        return lhs.code == rhs.code
    }
}

extension VRDataError: Hashable {
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(code)
        hasher.combine(message)
    }
}


