//
//  VRRequest.swift
//  VRCapture_iOS
//
//  Created by wzb on 2023/5/9.
//

import UIKit

enum VRHTTPMethod: String {
    case get     = "GET"
    case post    = "POST"
    case put     = "PUT"
    case delete  = "DELETE"
}

struct VRRequest: Hashable {
    public var url: String
    public var method: VRHTTPMethod = .get
    public var parameters: [String : Any]?
    public var header: [String:String] = [:]
    public var success: ((Any?)->())?
    public var failure: ((VRDataError)->())?
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(url)
        hasher.combine(method)
        hasher.combine(header)
    }
    
    static func == (lhs: VRRequest, rhs: VRRequest) -> Bool {
        return (lhs.url == rhs.url && lhs.method == rhs.method)
    }
}
