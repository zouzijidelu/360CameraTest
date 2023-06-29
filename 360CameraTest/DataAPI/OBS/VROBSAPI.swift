//
//  VROBSAPI.swift
//  VRCapture_iOS
//
//  Created by wzb on 2023/5/9.
//

import UIKit
import OBS
// obs 日志分析 https://support.huaweicloud.com/sdk-ios-devg-obs/obs_27_1603.html
typealias ResultBlock = (Bool)->()
class VROBSAPI {
    let semaphore = DispatchSemaphore(value: 5)
    lazy var client: OBSClient? = {
        let credentialProvider = OBSStaticCredentialProvider(accessKey: Preference[.accessKey], secretKey: Preference[.secretKey])
        let conf = OBSServiceConfiguration(urlString: "https://\(Preference[.endpoint]!)", credentialProvider: credentialProvider)
        client = OBSClient(configuration: conf)
//        // *****日志设置*******
//        client?.add(OBSDDASLLogger.sharedInstance)
//        client?.add(OBSDDTTYLogger.sharedInstance)
//        let fileLogger = OBSDDFileLogger()
//        fileLogger?.rollingFrequency = 60 * 60 * 24; // 24 hour rolling
//        fileLogger?.logFileManager.maximumNumberOfLogFiles = 7;
//        client?.add(fileLogger)
//        let ts = fileLogger?.currentLogFileInfo
//        printLog(ts);
//        client?.setLogLevel(.debug)
//        client?.setASLogOn()
        return client
    }()
    
    func putOBSObject(filePath: String,objectName: String, result: ((Bool,String)->())?,_ pregerss: ((Int, Int, Int)->())? = nil) {
        if objectName.isEmpty || filePath.isEmpty {return}
        let request = OBSPutObjectWithFileRequest(bucketName: Preference[.bucketName], objectKey: objectName, uploadFilePath: filePath)
        request?.uploadProgressBlock = {(bytesSent, totalBytesSent, totalBytesExpectedToSend) in
            _ = Double(bytesSent) }
        self.client?.putObject(request, completionHandler: { response, error in
            if error != nil {
                printLog("❌ putObject \(String(describing: error))")
                result?(false,"\(String(describing: error))")
            } else {
                var et = "nil"
                if let etag = response?.etag {
                    et = etag
                }
                result?(true,et)
            }
            self.semaphore.signal()
        })
        self.semaphore.wait()
    }
}
