//
//  VRHttpOBSHelper.swift
//  VRCapture_iOS
//
//  Created by wzb on 2023/5/22.
// 970930

import UIKit

class VRHttpOBSHelper: NSObject {
    var isUploadOBS = false
    var succesFileNum: Int = 0
    var failedFileNum: Int = 0
    let obs = VROBSAPI()
    var taskId: Int?
    var thread: Thread?
    let semaphore = DispatchSemaphore(value: 5)
    private static var lock = NSLock()
    lazy var audioPlayer = { return VRAudioPlayer()}()
    
    func safeSetSuccessFileNum(index: Int) {
        VRHttpOBSHelper.lock.lock()
        self.succesFileNum = index
        VRHttpOBSHelper.lock.unlock()
    }
    
    func safeSetFailedFileNum(index: Int) {
        VRHttpOBSHelper.lock.lock()
        self.failedFileNum = index
        VRHttpOBSHelper.lock.unlock()
    }
}

//obs request
extension VRHttpOBSHelper {
    
    func startLiveThread() {
        if thread != nil {
            return
        }
        thread = Thread(target: self, selector: #selector(lanchRunloop), object: nil)
        thread?.start()
    }
    
    @objc internal func lanchRunloop() {
        autoreleasepool {
            printLog("start live thread")
            let currentThread: Thread = Thread.current
            currentThread.name = "LiveThread"
            let currentRunLoop: RunLoop = RunLoop.current
            currentRunLoop.add(NSMachPort(), forMode: .common)
            currentRunLoop.run()
        }
    }
    
    func uploadOBS(houseId: String,outerTotoalPath: String,inputPath: String) {
        self.startLiveThread()
        //VRFileHelper.totoalFolderPathUrl = URL(string: totoalPath)
        // flutter给的绝对路径 获取相对路径文件名字 自己拼接
        guard let relativeFilePath = outerTotoalPath.components(separatedBy: "/").last else {
            isUploadOBS = false
            VRProgressHUD.dismiss()
            return
        }
        let innerTotoalPath = VRFileHelper.cachePathUrl.path.appending("/\(relativeFilePath)")
        guard !inputPath.isEmpty, let arr = VRFileHelper.getAllFilesInFolder(path: innerTotoalPath) else {
            self.isUploadOBS = false
            VRProgressHUD.dismiss()
            return
        }

        let fileArr = arr.filter { filterFile in
            if let filterF = filterFile as? String {
                return (filterF.contains(".") && !filterF.contains("frames"))
//                return filterF.contains(".")
            }
            return false
        }
        let totoalFileNum = fileArr.count
        let queue = DispatchQueue.global()
        UIApplication.shared.isIdleTimerDisabled = true
        queue.async {
            for (_, file) in fileArr.enumerated() {
                guard let f = file as? String else {return}
                //printLog("filepth --- \(f)")
                let objectName = inputPath.appending("\(f)")
                let finalpath = innerTotoalPath.appending("/\(f)")

                self.obs.putOBSObject(filePath: finalpath, objectName: objectName) { isSuccess,etag  in
                    guard let t = self.thread else {return}
                    let params: [String:Any] = ["finalpath":finalpath,"totoalFileNum":totoalFileNum,"houseId":houseId,"isSuccess":isSuccess,"totoalPath":outerTotoalPath]
                    self.perform(#selector(self.uploadOBSResult), on: t, with: params, waitUntilDone: false)
                    //self.uploadOBSResult(finalpath: finalpath, totoalFileNum: totoalFileNum, houseId: houseId, isSuccess: isSuccess, etag: etag)
                }
            }
        }
    }
    
    func uploadTask(totoalPath: String, houseId: String) {
        guard let taskId = self.taskId else {return}
        VRServiceAPI.upLoadTask(taskId: taskId) { (task: VRUploadTask?) in
            self.uploadTaskSuccess(totoalPath: totoalPath,houseId: houseId, task: task)
        } failure: { error in
            printLog("uploadTask failed --- \(error)")
            VRProgressHUD.showFailed(shortText: "上传失败")
        }
    }
    
    func uploadTaskSuccess(totoalPath: String, houseId: String, task: VRUploadTask?) {
        guard let m = task, m.status == VRResposeStatus.success.rawValue else {
            VRProgressHUD.showFailed(shortText: "上传失败")
            return
        }
        sendMessageToFlutter(eventName: VRFlutterEventName.requestCompletion.rawValue, arguments: [VREventDicKey.status.rawValue : VRResposeStatus.success.rawValue,VREventDicKey.houseId.rawValue:houseId])
        VRProgressHUD.showSuccess(shortText: "上传成功")
        VRFileHelper.removeTotoalFoler(path: totoalPath)
        audioPlayer.playAudio(imageName: "upload_finish")
        printLog("uploadTask success")
    }
    
    @objc func uploadOBSResult(params: [String:Any]) {
        guard let totoalFileNum = params["totoalFileNum"] as? Int,let houseId = params["houseId"] as? String,let finalpath = params["finalpath"] as? String, let isSuccess = params["isSuccess"] as? Bool,let totoalPath = params["totoalPath"] as? String else {
            return
        }
        if isSuccess {
            self.safeSetSuccessFileNum(index: self.succesFileNum+1)
            printLog("upload success one file: \(self.succesFileNum)/\(totoalFileNum) --- path --- \(finalpath)")
            var progress = Int(Float(self.succesFileNum)/Float(totoalFileNum)*100) - 1
            progress =  progress<=0 ? 1 : progress
            VRProgressHUD.show(shortText: "上传成功: \(progress)% \n中途离开将会导致上传失败")
            if (self.succesFileNum+self.failedFileNum) == totoalFileNum {
                DispatchQueue.main.async {
                    UIApplication.shared.isIdleTimerDisabled = false
                }
                if self.succesFileNum == totoalFileNum {
                    self.uploadTask(totoalPath: totoalPath,houseId: houseId)
                    self.safeSetSuccessFileNum(index: 0)
                    self.safeSetFailedFileNum(index: 0)
                    self.isUploadOBS = false
                    printLog("upload success all file success")
                } else {
                    VRProgressHUD.showFailed(shortText: "上传失败")
                }
            }
        } else {
            self.safeSetFailedFileNum(index: self.failedFileNum+1)
            let resutlNum = self.failedFileNum+self.succesFileNum
            printLog("upload failed one file: \(resutlNum)/\(totoalFileNum) --- path --- \(finalpath)")
            //VRProgressHUD.show(shortText: "上传失败: \(resutlNum)/\(totoalFileNum)")
            if self.succesFileNum != totoalFileNum, resutlNum == totoalFileNum  {
                DispatchQueue.main.async {
                    UIApplication.shared.isIdleTimerDisabled = false
                }
                self.safeSetSuccessFileNum(index: 0)
                self.safeSetFailedFileNum(index: 0)
                self.isUploadOBS = false
                printLog("upload failed final")
                VRProgressHUD.showFailed(shortText: "上传失败")
            }
        }
    }
}
// 8376303  Nwc729410
//http request
extension VRHttpOBSHelper {
    func getOBSInfo() {
        VRServiceAPI.getOBSInfo { (m: VROBSInfo?) in
            self.getObsInfoSuccess(m: m)
        } failure: { error in
            printLog(error.description)
        }
    }
    
    func getObsInfoSuccess(m: VROBSInfo?) {
        guard let m = m, m.status == VRResposeStatus.success.rawValue else {
            printLog("getOBSInfo failed --- \(String(describing: m?.message))")
            return
        }
        Preference[.accessKey] = m.data?.ak
        Preference[.secretKey] = m.data?.sk
        Preference[.bucketName] = m.data?.bucketName
        Preference[.endpoint] = m.data?.endPoint
        printLog("getObsInfoSuccess")
    }
    
    func addTask(params: [String:Any]) {
        VRProgressHUD.show(shortText: "数据上传中。。。")
        var params = params
        params["ak"] = Preference[.accessKey]
        guard let outerTotoalPath = params["filePath"] as? String, let houseId = params[VREventDicKey.houseId.rawValue] as? String, !self.isUploadOBS else {
            printLog("addTask is nil")
            VRProgressHUD.dismiss()
            return
        }
        self.isUploadOBS = true

        VRServiceAPI.addTask(params: params) { (m: VRAddTask?) in
            self.addTaskSuccess(houseId: houseId,outerTotoalPath: outerTotoalPath, m: m)
        } failure: { error in
            self.isUploadOBS = false
            VRProgressHUD.showFailed(shortText: "上传失败")
        }
    }
    
    func addTaskSuccess(houseId: String,outerTotoalPath: String, m: VRAddTask?) {
        guard let m = m, let code = m.code, code == 0 else {
            printLog("addTask status failed --- \(m?.message)")
            self.isUploadOBS = false
            sendMessageToFlutter(eventName: VRFlutterEventName.requestCompletion.rawValue, arguments: [VREventDicKey.status.rawValue : VRResposeStatus.failed.rawValue])
            VRProgressHUD.showFailed(shortText: "\(m?.message ?? "上传失败")")
            return
        }
        //printLog("\(String(describing: m.status))")
        if let inputPath = m.data?.inputPath, let taskId = m.data?.taskId {
            printLog("inputPath --- \(inputPath)")
            self.taskId = taskId
            self.uploadOBS(houseId: houseId,outerTotoalPath: outerTotoalPath, inputPath: inputPath)
        }
    }
}

extension VRHttpOBSHelper {
    //localPath --- \(localPath) --- inputPath
    func uploadOBSHouseImage(localPath: String?,inputPath: String?) {
        guard let localPath = localPath, let ipath = inputPath, let name = localPath.split(separator: "/").last else {return}
        let objcName = ipath.appending("/\(name)")
        self.obs.putOBSObject(filePath: localPath, objectName: objcName) { re, etag in
            printLog("re --- \(re)")
            if re {
                
            } else {
                
            }
        }
    }
}
