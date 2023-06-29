//
//  FileManager.swift
//  VRCapture_iOS
//
//  Created by wzb on 2023/5/5.
//

import UIKit
import CoreMedia

class VRFileHelper {
    static let manager = FileManager.default
    static private var totoalFolderPathUrl: URL?
    static private var totoalFolderName: String?
    static let cachePathUrl = manager.urls(for: .cachesDirectory, in: .userDomainMask).first!
    
    static func setTotalFolderPath(name: String) {
        totoalFolderName = name
        totoalFolderPathUrl = cachePathUrl.appendingPathComponent(name)
    }
    
    static func getTotoalFolderName () -> String? {
        return totoalFolderName
    }
    // 创建文件夹
    static func createFolder(path: String) -> Bool {
        if !isFileExists(path: path) {
            try? manager.createDirectory(atPath: path, withIntermediateDirectories: true)
            return true
        }
        return false
    }
    
    // 创建文件
    static func createFile(path: String) -> Bool {
        if !isFileExists(path: path) {
            return manager.createFile(atPath: path, contents: nil)
        }
        return true
    }
    
    static func resetTotoalPth() {
        printLog("resetTotoalPth")
        totoalFolderPathUrl = nil
    }
    
    
    static func getTotalFolderPathUrlOuter() -> URL? {
        return totoalFolderPathUrl
    }
    
    // 只允许用户进入拍摄编辑页面时设置一次
    private static func getTotalFolderPathUrl() -> URL {
        let dateformatter = DateFormatter()
        dateformatter.dateFormat = "YYYYMMdd_HH_mm_ss_SSS"// 自定义时间格式
        var time = dateformatter.string(from: Date())
        //time = "20230510_16_58_04_430"
        totoalFolderName = "\(time)_iphone"
        let pathURL = cachePathUrl.appendingPathComponent(totoalFolderName!, isDirectory: true)
        return pathURL
    }
    
    static func getPanoOriginalPathUrl() -> URL? {
        guard let url = totoalFolderPathUrl else {
            return nil
        }
        let pathUrl = url.appendingPathComponent("pano_original",isDirectory: true)
        return pathUrl
    }
    
    static func getPanoVideoPathUrl() -> URL? {
        guard let url = totoalFolderPathUrl else {
            return nil
        }
        let pathUrl = url.appendingPathComponent("pano_video",isDirectory: true)
        return pathUrl
    }
    
    static func getFramesPathUrl() -> URL? {
        guard let url = totoalFolderPathUrl else {
            return nil
        }
        let pathUrl = url.appendingPathComponent("frames",isDirectory: true)
        return pathUrl
    }
    
    static func getCyberRecordInfosPathUrl() -> URL? {
        guard let url = totoalFolderPathUrl else {
            printLog("getCyberRecordInfosPathUrl is nil")
            return nil
        }
        let pathUrl = url.appendingPathComponent("cyber_record_infos.txt",isDirectory: false)
        return pathUrl
    }
    
    static func getPreprocessInfosPathUrl() -> URL? {
        guard let url = totoalFolderPathUrl else {
            printLog("getPreprocessInfosPathUrl is nil")
            return nil
        }
        let pathUrl = url.appendingPathComponent("preprocess_infos.txt",isDirectory: false)
        return pathUrl
    }
    
    static func getConfigPathUrl() -> URL? {
        guard let url = totoalFolderPathUrl else {
            printLog("getPreprocessInfosPathUrl is nil")
            return nil
        }
        let pathUrl = url.appendingPathComponent("config.json",isDirectory: false)
        return pathUrl
    }
    
    static func getIntrinsicParameterPathUrl() -> URL? {
        guard let url = totoalFolderPathUrl else {
            printLog("getIntrinsicParameterPathUrl is nil")
            return nil
        }
        let pathUrl = url.appendingPathComponent("intrinsic_parameter.txt",isDirectory: false)
        return pathUrl
    }
    
    static func getRoomPathUrl() -> URL? {
        guard let url = totoalFolderPathUrl else {
            printLog("getRoomPathUrl is nil")
            return nil
        }
        let pathUrl = url.appendingPathComponent("room.txt",isDirectory: false)
        return pathUrl
    }
    
    //最外层文件夹20220509_10_39_42_879_iphone
    static func createTotalFolderInCache() -> Bool {
        if totoalFolderPathUrl == nil {
            totoalFolderPathUrl = getTotalFolderPathUrl()
            let re = createFolder(path: totoalFolderPathUrl!.path)
            writeConfigJson()
            return re
        }
        return true
    }
    
    static func createPanoOriginalInCache() -> Bool {
        guard let url = getPanoOriginalPathUrl() else {
            printLog("getPanoOriginalPathUrl is nil")
            return false
        }
        return createFolder(path: url.path)
    }
    
    static func createPanoVideoInCache() -> Bool {
        guard let url = getPanoVideoPathUrl() else {
            printLog("getPanoVideoPathUrl is nil")
            return false
        }
        return createFolder(path: url.path)
    }
    
    // frames
    static func createFramesFolderInCache() -> Bool {
        guard let url = getFramesPathUrl() else {
            printLog("getFramesPathUrl is nil")
            return false
        }
        return createFolder(path: url.path)
    }
    
    static func wirteStringToFile(str: String, path: String) {
        let fileHandle = FileHandle(forWritingAtPath: path)!
        fileHandle.seekToEndOfFile()
        fileHandle.write(str.data(using: .utf8)!)
        try? fileHandle.close()
    }
    
    static func writeStringToCyberRecordInfos(dataStr: String) {
        guard !dataStr.isEmpty, let path = getCyberRecordInfosPathUrl()?.path else {
            printLog("writeStringToCyberRecordInfos is nil")
            return
        }
        _ = createFile(path: path)
        //printLog("writeStringToCyberRecordInfos -- \(path)")
        //printLog("writeStringToCyberRecordInfos -- \(dataStr)")
        wirteStringToFile(str: dataStr, path: path)
    }
    
    static func writeStringToPreprocessInfos(dataStr: String) {
        guard !dataStr.isEmpty, let path = getPreprocessInfosPathUrl()?.path else {
            printLog("writeStringToPreprocessInfos is nil")
            return
        }
        _ = createFile(path: path)
        wirteStringToFile(str: dataStr, path: path)
    }
    
    static func writeStringToConfig(dataStr: String) {
        guard !dataStr.isEmpty, let path = getConfigPathUrl()?.path else {
            printLog("writeStringToPreprocessInfos is nil")
            return
        }
        _ = createFile(path: path)
        wirteStringToFile(str: dataStr, path: path)
    }
    
    static func wirteStringIntrinsicParameter(dataStr: String) {
        guard !dataStr.isEmpty, let path = getIntrinsicParameterPathUrl()?.path else {
            printLog("wirteStringIntrinsicParameter is nil")
            return
        }
        _ = createFile(path: path)
        wirteStringToFile(str: dataStr, path: path)
    }
    
    static func writeStringToRoom(dataStr: String) {
        guard !dataStr.isEmpty, let path = getRoomPathUrl()?.path else {
            printLog("writeStringToRoom is nil")
            return
        }
        _ = createFile(path: path)
        wirteStringToFile(str: dataStr, path: path)
    }
    
    static func writeConfigJson() {
        let dic: [String : Any] = ["isCheck":false, "cameraHeight": 1470]
        guard let jsonData = try? JSONSerialization.data(withJSONObject: dic, options: []),let str = String(data: jsonData, encoding: .utf8) else {return}
        
        VRFileHelper.writeStringToConfig(dataStr: str)
    }
    
    static func isFileExists(path: String) -> Bool {
        return manager.fileExists(atPath: path)
    }
    
    static func removeFolder(path: String) {
        if isFileExists(path: path) {
            try? manager.removeItem(atPath: path)
        }
    }
    
    static func removeTotoalFoler(path: String) {
        removeFolder(path: path)
        VRFileHelper.resetTotoalPth()
    }
    
    static func getAllFilesInFolder(path: String) -> [Any]? {
        let content = manager.enumerator(atPath: path)?.allObjects
        return content
    }
}

extension VRFileHelper {
    
    static func getCyberInfoPicIndex(path: String) -> Int? {
        guard let cyberRecordInfosPath = VRFileHelper.getCyberRecordInfosPathUrl()?.path else {return nil}
        var lineArr = [String]()
        do {
            lineArr = try String(contentsOfFile: cyberRecordInfosPath).components(separatedBy: "\n")
            
            guard let indexName = lineArr[lineArr.count-2].split(separator: ",").first?.split(separator: ".").first else { return nil }
            print("indexName --- \(Int(indexName))")
            return Int(indexName)
        } catch {
            return nil
        }
    }
}
