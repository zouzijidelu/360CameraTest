//
//  VRRequestManager.swift
//  VRCapture_iOS
//
//  Created by wzb on 2023/5/9.
//
import UIKit
import Alamofire


class VRSessionManager {
    
    /// http headers
    var headers: HTTPHeaders = SessionManager.defaultHTTPHeaders
    
    /// All internal session managerss, key: host, value: an instance of Alamofire.SessionManager.
    private static let manager: SessionManager = getSessionManager()
    
    func cancelRequest() {
        VRSessionManager.manager.session.getTasksWithCompletionHandler { (sessionDataTask, uploadData, downloadData) in
                sessionDataTask.forEach { $0.cancel() }
                uploadData.forEach { $0.cancel() }
                downloadData.forEach { $0.cancel() }
        }
    }
    
    func cancelRequest(url: String?) {
        if let url = url {
            VRSessionManager.manager.session.getTasksWithCompletionHandler { (sessionDataTask, uploadData, downloadData) in
                sessionDataTask.forEach { dataTask in
                    if dataTask.originalRequest?.url?.absoluteString == url {
                        dataTask.cancel()
                    }
                }
            }
        }
    }
    
    func  request(request: VRRequest,
                  completionHandler: @escaping (DataResponse<Any>) -> Void) {
        for (key,value) in request.header {
            self.headers[key] = value
        }
        let sessionManager = VRSessionManager.manager
        let dataRequest: DataRequest?
        let method = methodType(type: request.method)
        
        
        if request.method == .get {
            dataRequest = sessionManager.request(
                request.url,
                method: method,
                parameters: request.parameters ?? [:],
                headers: headers)
        } else {
            dataRequest = sessionManager.request(
                request.url,
                method: method,
                parameters: request.parameters ?? [:],
                encoding: JSONEncoding(),
                headers: headers)
        }

        dataRequest?
            .validate(statusCode: 199...300)
            .responseJSON(completionHandler: { response in
                completionHandler(response)
            })
    }
    
    func uploadRequest(
        request: VRRequest,
        multipartFormData: @escaping (MultipartFormData) -> Void,
        headers: HTTPHeaders? = nil,
        encodingCompletion: ((SessionManager.MultipartFormDataEncodingResult) -> Void)?) {
            VRSessionManager.manager
            .upload(multipartFormData: multipartFormData, to: request.url, method: methodType(type: request.method), headers: headers ?? self.headers, encodingCompletion: encodingCompletion)
    }
    
    private func methodType(type: VRHTTPMethod) -> Alamofire.HTTPMethod {
        switch type {
        case .get:
            return .get
        case .post:
            return .post
        case .delete:
            return .delete
        case .put:
            return .put
        }
    }
    
}

// MARK: - Private methods
private extension VRSessionManager {
    
    /// This function will create a single session manager for each host.
    ///
    /// - Parameter url: RequestUrl
    /// - Returns: An instance of Alamofire.SessionManager used to manage requests.
   static func getSessionManager() -> SessionManager {
            let configuration = URLSessionConfiguration.default
            configuration.timeoutIntervalForRequest = 60.0
//       configuration.requestCachePolicy = 1
            return Alamofire.SessionManager(configuration: configuration)
    }
}

