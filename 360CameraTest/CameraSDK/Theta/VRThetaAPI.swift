//
//  VRThetaAPI.swift
//  360CameraTest_Beta
//
//  Created by wzb on 2023/6/13.
//

import UIKit

class VRThetaAPI {
    
    var previewing = true
    
    var isTakingPic = false
    var startCaptureTimer: Timer?
    
    init() {
        print("VRThetaAPI init")
    }
    func livePreview(previewView: UIImageView) {
        
        Task.init {
            do {
                try await theta.livePreview(
                    frameHandler: {frame in
                        let image = UIImage(data: frame)
                        DispatchQueue.main.async {
                            previewView.image = image
                        }
                        return self.previewing
                    }
                )
            } catch {
                self.previewing = false
            }
        }
    }
    
    func takePhoto(_ isTimelapse: Bool = false,success: @escaping (String)->(),failed:  @escaping  (Error)->()) async {
        printLog("real takePhoto --- ")
        do {
            VRProgressHUD.show(shortText: "拍摄中")
            self.initStartCaptureTimer()
            self.previewing = false
            stopCaptureVideo(isTimelapse, completion: nil)
            sleep(20)
            try await theta.takePicture { [self]photoUrl in
                self.startCaptureTimer?.invalidate()
                self.isTakingPic = false
                success(photoUrl)
                Task {
                    do {
                        try await capture(success: success, failed: failed)
                    }catch{
                        sleep(1)
                        Task {
                            try await capture(success: success, failed: failed)
                        }
                    }
                }
            }
        } catch {
            isTakingPic = false
            previewing = true
            startCaptureTimer?.invalidate()
            failed(error)
            await takePhoto(success: success, failed: failed)
        }
    }
    
    func capture(success: @escaping (String)->(),failed:  @escaping  (Error)->()) async throws {
        try await theta.captrueVideo { url in
            printLog("captrueVideo --- \(url)")
            DispatchQueue.global().async {
                let savePath = VRFileHelper.getPanoVideoPathUrl()?.path
                VRRequestCameraDataHelper.shared.requestDataFromCamera(urlStr:theta.caputureUrl,savePath: savePath) { _, _ in
//                    Task {
//                        await self.takePhoto(success: success, failed: failed)
//                    }
                    
                } failed: { err in
                    failed(err!)
                }
            }
        }
    }
        
        
    
    func initStartCaptureTimer() {
        self.startCaptureTimer = Timer.scheduledTimer(withTimeInterval: 10, repeats: false, block: {[weak self] (timer) in
            self?.startCaptureTimer?.invalidate()
            self?.previewing = true
            self?.isTakingPic = false
            VRProgressHUD.showFailed(shortText: "拍摄失败，请重试！")
        });
    }
    
    func stopCaptureVideo(_ isTimelapse: Bool = false,completion: (()->())? = nil) {
        theta.stopCapture()
    }
}
