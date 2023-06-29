//
//  VRInstaAPI.swift
//  360CameraTest_Beta
//
//  Created by wzb on 2023/6/13.
//

import UIKit
import INSCameraSDK

class VRInstaAPI: NSObject {

    var previewing = true
    var isTakingPic = false
    var startCaptureTimer: Timer?
    var queue: DispatchQueue?
    var timer: Timer?
    var previewPlayer: INSCameraPreviewPlayer?
    var mediaSession: INSCameraMediaSession?
    var storageState: INSCameraStorageStatus?
    var videoEncode: INSVideoEncode?
    init(previewFrame: CGRect) {
        printLog("VRInstaAPI init")
        super.init()
        INSCameraManager.socket().addObserver(self, forKeyPath: "cameraState", options: [.new],context: nil)
        INSCameraManagerSocketSetup()
        mediaSession = INSCameraMediaSession()
        previewPlayer = INSCameraPreviewPlayer(frame: previewFrame, renderType: .multiviewFlat)
        setupRenderView()
    }
    func livePreview(previewView: UIImageView) {
        
        previewView.addSubview(previewPlayer!.renderView)
        //runMediaSession()
    }
    
    func takePhoto(_ isTimelapse: Bool = false,success: @escaping (String)->(),failed:  @escaping  (Error)->()) async {
        printLog("拍摄流程 real takePhoto --- ")
        stopCaptureVideo(isTimelapse) {
            let metaData = INSExtraMetadata()
            metaData.rawCaptureType = .pureshot
            let extraInfo = INSExtraInfo()
            extraInfo.metadata = metaData
            let options = INSTakePictureOptions(extraInfo: extraInfo)
            INSCameraManager.shared().commandManager.takePicture(with: options) { error, info in
                self.isTakingPic = false
                guard error == nil, let urlStr = info?.uri else {
                    self.INSCameraManagerSocketSetup()
                    failed(error!)
                    return
                }
                self.startCaptureVideo(isTimelapse)
                success("http://192.168.42.1:80\(urlStr)")
            }
        }
        
    }
    
    func stopCaptureVideo(_ isTimelapse: Bool = false,completion: @escaping ()->()) {
        mediaSession?.stopRunning() {_ in
            self.runMediaSession()
        }
        if self.storageState?.cardState == .normal {
            Task {
                let defaultInfo = INSExtraInfo()
                let options = INSStopCaptureTimelapseOptions(extraInfo: defaultInfo, mode: .video)
                if isTimelapse {
                    INSCameraManager.shared().commandManager.stopCaptureTimelapse(with:options, completion:{ (err, stopVideoInfo) in
                        self.stopResult(err: err, stopVideoInfo: stopVideoInfo, completion: completion)
                    })
                } else {
                    INSCameraManager.shared().commandManager.stopCapture(with: nil) { err, stopVideoInfo in
                        self.stopResult(err: err, stopVideoInfo: stopVideoInfo, completion: completion)
                    }
                }
            }
        } else {
            completion()
        }
    }
    
    func stopResult(err: Error?, stopVideoInfo: INSCameraVideoInfo?,completion: @escaping ()->()) {
        if err == nil, let url = stopVideoInfo?.uri {
            print("拍摄流程 success info uri--- \(String(describing: stopVideoInfo?.uri))")
            let savePath = VRFileHelper.getPanoVideoPathUrl()?.path
            DispatchQueue.global().async {
                VRRequestCameraDataHelper.shared.requestDataFromCamera(urlStr: "http://192.168.42.1:80\(url)",savePath: savePath) { _, _ in
                    var secondURl = ""
                    if url.contains("_10_") {
                        secondURl = url.replacingOccurrences(of: "_10_", with: "_00_")
                    } else {
                        secondURl = url.replacingOccurrences(of: "_00_", with: "_10_")
                    }

                    VRRequestCameraDataHelper.shared.requestDataFromCamera(urlStr: "http://192.168.42.1:80\(secondURl)",savePath: savePath) { _, _ in
                        completion()
                    } failed: { err in
                        completion()
                    }
                } failed: { err in
                    completion()
                }
            }
        } else {
            completion()
            printLog("拍摄流程 failed err --- \(err.debugDescription)")
        }
    }
        
    func startCaptureVideo(_ isTimelapse: Bool = false) {
        mediaSession?.stopRunning() {_ in
            self.runMediaSession()
        }
        if self.storageState?.cardState == .normal {
            Task {
                if isTimelapse {
                    let defaultInfo = INSExtraInfo()
                    let options = INSStartCaptureTimelapseOptions(extraInfo: defaultInfo, mode: .video)
                    options.timelapseOptions?.duration = 3600
                    options.timelapseOptions?.lapseTime = 500
                    INSCameraManager.shared().commandManager.startCaptureTimelapse(with: options, completion:{err in
                        if err == nil {
                            printLog("拍摄流程 startCaptureTimelapse success --- ")
                        } else {
                            printLog("拍摄流程 startCaptureTimelapse failed --- \(err.debugDescription)")
                        }
                    })
                } else {
                    INSCameraManager.shared().commandManager.startCapture(with: nil) {err in
                        if err == nil {
                            printLog("拍摄流程 startHDRVideo success --- ")
                        } else {
                            printLog("拍摄流程 startHDRVideo failed --- \(err.debugDescription)")
                        }
                    }
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
    func INSCameraManagerSocketSetup() {
        INSCameraManager.socket().setup()
    }
    func runMediaSession() {
        if INSCameraManager.shared().cameraState != .connected {
            return
        }
        if let running = mediaSession?.running, running {
            mediaSession?.commitChanges() {err in
                printLog("commitChanges --- \(String(describing: err))")
            }
        } else {
            mediaSession?.startRunning() {err in
                printLog("startRunning --- \(String(describing: err))")
            }
        }
    }
    
    override func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey : Any]?, context: UnsafeMutableRawPointer?) {
        guard object is INSCameraManager else {
            super.observeValue(forKeyPath: keyPath, of: object, change: change, context: context)
            return
        }
        
        DispatchQueue.main.async {
            let  key = change?[NSKeyValueChangeKey.newKey] as? UInt
            let state = INSCameraState(rawValue: key ?? 0)
            switch state {
            case .found:
                print("found")
            case .synchronized:
                print("synchronized")
            case .connected:
                self.startSendingHeartbeats()
                self.connectedInsta()
                print("connected")
            case .connectFailed:
                self.stopSendingHeartbeats()
                print("connectFailed")
            default:
                self.stopSendingHeartbeats()
                print("not found")
            }
        }
    }
    func startSendingHeartbeats() {
        printLog("heartbeat start")
        queue = DispatchQueue(label: "com.insta360.sample.heartbeat")
        timer = Timer.scheduledTimer(withTimeInterval: 0.5, repeats: true) { time in
            INSCameraManager.socket().commandManager.sendHeartbeats(with: nil)
        }
    }
    
    func stopSendingHeartbeats() {
        timer?.invalidate()
    }
    
    func setupRenderView() {
        previewPlayer?.play(withGyroTimestampAdjust: 30)
        previewPlayer?.delegate = self
        mediaSession?.plug(previewPlayer!)
        
        let offset = INSCameraManager.shared().currentCamera?.settings?.mediaOffset
        if offset != nil {
            let rawValue = INSLensType(rawValue: Int(INSLensOffset(offset: offset!).lensType))
            
            if rawValue == .oneR577Wide || rawValue == .oneR283Wide {
                previewPlayer?.renderView.enablePanGesture = true
                previewPlayer?.renderView.enablePinchGesture = false
                
                previewPlayer?.renderView.render.camera?.xFov = 37
                previewPlayer?.renderView.render.camera?.distance = 700
            } else if rawValue == .oneRS283FishEye {
                previewPlayer?.renderView.render.stitchType = .disflow
                previewPlayer?.renderView.render.colorFusion = true
            }
        }
    }
    
    deinit {
        mediaSession?.stopRunning()
        INSCameraManager.socket().removeObserver(self, forKeyPath: "cameraState")
    }
}

private extension VRInstaAPI {
    func connectedInsta() {
        if INSCameraManager.shared().currentCamera != nil {
            self.fetchOptions {
                self.updateConfiguration()
                self.runMediaSession()
            }
        } else {
            printLog("connectedInsta currentCamera is nil")
        }
    }
    
    func fetchOptions(completion: @escaping ()->()) {
        let optionTypes: [NSNumber] = [NSNumber(value: INSCameraOptionsType.storageState.rawValue), NSNumber(value: INSCameraOptionsType.videoEncode.rawValue)]
        INSCameraManager.shared().commandManager.getOptionsWithTypes(optionTypes) {[weak self]  (error, options, successTypes) in
            if options == nil {
                completion()
                return
            }
            self?.storageState = options?.storageStatus
            self?.videoEncode = options?.videoEncode
            completion()
        }
    }
    
    func updateConfiguration() {
        mediaSession?.expectedVideoResolution = INSVideoResolution2880x2880x30
        mediaSession?.expectedVideoResolutionSecondary = INSVideoResolution2880x2880x30
        mediaSession?.previewStreamType = INSPreviewStreamTypeWithValue(1)
        mediaSession?.expectedAudioSampleRate = INSAudioSampleRateWithValue(48000)
        mediaSession?.videoStreamEncode = .H264
        mediaSession?.gyroPlayMode = .none
    }
}

extension VRInstaAPI: INSCameraPreviewPlayerDelegate {
    func offset(toPlay player: INSCameraPreviewPlayer) -> String? {
        let mediaOffset = INSCameraManager.shared().currentCamera?.settings?.mediaOffset
        if let mediaOffset = mediaOffset, let name =  INSCameraManager.shared().currentCamera?.name {
            if name == kInsta360CameraNameOneX {
                return INSOffsetCalculator.convertOffset(mediaOffset, to: .oneX3040_2_2880)
            } else if name == kInsta360CameraNameOneRS, INSLensOffset.isValidOffset(mediaOffset) {
                let value = INSLensOffset(offset: mediaOffset).lensType
                if value == INSLensType.oneRS283FishEye.rawValue {
                    // todo
                }
            }
        }
        
        return mediaOffset
    }
}
