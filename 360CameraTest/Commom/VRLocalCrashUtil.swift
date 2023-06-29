//
//  VRImageHelper.swift
//  VRCapture_iOS
//
//  Created by wzb on 2023/5/11.
//

import UIKit

struct VRLocalCrashUtil {
    static func exceptionLogWithData() {
        VRLocalCrashUtil.setDefaultHandler()
        let str = VRLocalCrashUtil.getdataPath()
        let data = NSData.init(contentsOfFile: str)
        if let data = data {
            let crushStr = String.init(data: data as Data, encoding: String.Encoding.utf8)
            print(crushStr!)
        }
//        //测试数据
//        let arry:NSArray = ["1"]
//        printLog("%@",arry[5])
    }
    
    public static func getdataPath() -> String{
            let str = NSSearchPathForDirectoriesInDomains(FileManager.SearchPathDirectory.libraryDirectory, FileManager.SearchPathDomainMask.userDomainMask, true).last!
            let urlPath = str.appending("/Caches/Exception.txt")
            return urlPath
        }
    public static func setDefaultHandler() {
            NSSetUncaughtExceptionHandler { (exception) in
                let arr:NSArray = exception.callStackSymbols as NSArray
                let reason:String = exception.reason!
                let name:String = exception.name.rawValue
                let date:NSDate = NSDate()
                let timeFormatter = DateFormatter()
                timeFormatter.dateFormat = "YYYY/MM/dd hh:mm:ss SS"
                let strNowTime = timeFormatter.string(from: date as Date) as String
                let url:String = String.init(format: "========异常错误报告========\ntime:%@\nname:%@\nreason:\n%@\ncallStackSymbols:\n%@",strNowTime,name,reason,arr.componentsJoined(by: "\n"))
  
                let path = VRLocalCrashUtil.getdataPath()
                do{
                try
                url.write(toFile: path, atomically: true, encoding: String.Encoding.utf8)
                }catch{}
            }
      }
}
