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
    
    func takePhoto(success: @escaping (String)->(),failed:  @escaping  (Error)->()) async {
        printLog("real takePhoto --- ")
        do {
            VRProgressHUD.show(shortText: "拍摄中")
            self.initStartCaptureTimer()
            self.previewing = false
            try await theta.takePicture { [self]photoUrl in
                self.startCaptureTimer?.invalidate()
                self.isTakingPic = false
                success(photoUrl)
            }
        } catch {
            isTakingPic = false
            previewing = true
            startCaptureTimer?.invalidate()
            failed(error)
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
    
    
}
