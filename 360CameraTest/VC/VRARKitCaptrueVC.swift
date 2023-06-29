//
//  VRARKitCaptrueVC.swift
//  VRCapture_iOS
//
//  Created by wzb on 2023/5/8.
//

import UIKit
import SpriteKit
import ARKit
import Toast_Swift
import CoreMotion
import flutter_boost

enum VRLocalTrackingState: String {
    case notAvailable
    case limited
    case normal
}

typealias VRTrackingStateChangeBlock = (String)->()
class VRARKitCaptrueVC: UIViewController, ARSessionDelegate {
    private static var lock = NSLock()
    var lastFrame: ARFrame?
    var curFrame: ARFrame?
    var picIndex = 1
    var curCamera: ARCamera?
    var configuration: ARWorldTrackingConfiguration?
    var width: Int?
    var height: Int?
    let motionManager = CMMotionManager()
    var thread: Thread?
    var trackingStateChangeBlock: VRTrackingStateChangeBlock?
    var isARKitFirstConnectNormal = true
    var localTrackingState =  VRLocalTrackingState.notAvailable {
        willSet {
            if localTrackingState != .limited,newValue == .limited, !isARKitFirstConnectNormal {
                self.trackingStateChangeLimited(state: newValue.rawValue)
            }
        }
    }
    
    var sceneView: ARSKView!
    
    func safeSetPicIndex(index: Int) {
        VRARKitCaptrueVC.lock.lock()
        self.picIndex = index
        VRARKitCaptrueVC.lock.unlock()
    }
}

// life cycle
extension VRARKitCaptrueVC {
    override func viewDidLoad() {
        super.viewDidLoad()
        sceneView = ARSKView()
        sceneView.frame = self.view.bounds
        self.view.addSubview(sceneView!)
        if (self.motionManager.isDeviceMotionAvailable) {
            //开始更新设备的动作信息
            self.motionManager.startDeviceMotionUpdates()
        } else {
            printLog("该设备的deviceMotion不可用")
        }
        if let scene = SKScene(fileNamed: "Scene") {
            sceneView.presentScene(scene)
            sceneView.isHidden = true
        }
        setConfig()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        setConfig()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
    }
}
// api
extension VRARKitCaptrueVC {
    
    func openARKit() {
        self.startLiveThread()
        setConfig()
        guard let c = configuration else { return }
        sceneView.session.run(c)
    }
    
    func setConfig() {
        guard configuration == nil else {
            return
        }
        configuration = ARWorldTrackingConfiguration()
        let fs = ARWorldTrackingConfiguration.supportedVideoFormats
        if let vf = fs.last {
            configuration!.videoFormat = vf
            print("default imageResolution: \(vf.imageResolution)")
        }
        sceneView.session.delegate = self
        self.view.isHidden = true
    }
    
    func pauseAndSaveData() {
        printLog("pauseAndSaveData")
        createFinalData()
        sceneView.session.pause()
        guard let t = self.thread else {return}
        perform(#selector(self.resetData), on: t, with: nil, waitUntilDone: false)
    }
    
    func set(trackingStateChangeBlock: VRTrackingStateChangeBlock?) {
        self.trackingStateChangeBlock = trackingStateChangeBlock
    }
}
//private
extension VRARKitCaptrueVC {
    func safeToastOnMainQueue(str: String) {
        DispatchQueue.main.async {
            self.view.superview?.makeToast(str,duration: 1.0,position: .center)
        }
    }
    
    @objc func resetData() {
        safeSetPicIndex(index: 1)
        self.isARKitFirstConnectNormal = true
        self.lastFrame = nil
        self.curFrame = nil
        self.curCamera = nil
        self.width = nil
        self.height = nil
        self.thread = nil
    }
    
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
}
/// ARSessionDelegate
extension VRARKitCaptrueVC {
    func session(_ session: ARSession, didUpdate frame: ARFrame) {
        switch frame.camera.trackingState {
        case .notAvailable:
            self.localTrackingState = .notAvailable
            print("camera trackingState notAvailable")
            self.safeToastOnMainQueue(str: "camera trackingState notAvailable")
        case .limited(let reason):
            self.localTrackingState = .limited
            trackingStateLimited(reason: reason)
        case .normal:
            self.localTrackingState = .normal
            trackingStateNormal(frame: frame)
        }
    }
    
    func trackingStateChangeLimited(state: String) {
        self.trackingStateChangeBlock?(state)
    }
    
    func trackingStateLimited(reason: ARCamera.TrackingState.Reason) {
        switch reason {
        case .initializing:/** Tracking is limited due to initialization in progress. */
            //printLog("camera trackingState limited: initializing")
            self.safeToastOnMainQueue(str: "camera trackingState limited: initializing")
        case .excessiveMotion:/** Tracking is limited due to a excessive motion of the camera. */
            //printLog("camera trackingState limited: excessiveMotion")
            self.safeToastOnMainQueue(str: "camera trackingState limited: excessiveMotion")
        case .insufficientFeatures:/** Tracking is limited due to a lack of features visible to the camera. */
            //printLog("camera trackingState limited: insufficientFeatures")
            self.safeToastOnMainQueue(str: "camera trackingState limited: insufficientFeatures")
        case .relocalizing:/** Tracking is limited due to a relocalization in progress. */
            //printLog("camera trackingState limited: relocalizing")
            self.safeToastOnMainQueue(str: "camera trackingState limited: relocalizing")
        @unknown default:
            break
        }
    }
    
    func trackingStateNormal(frame: ARFrame) {
        guard let t = self.thread else {return}
        perform(#selector(self.handleFrame), on: t, with: frame, waitUntilDone: false)
    }
    
    @objc func handleFrame(frame: ARFrame) {
        if self.thread == nil { return  }
        if isARKitFirstConnectNormal {
            sendMessageToFlutter(eventName: VRFlutterEventName.openARKit.rawValue, arguments: [VRFlutterEventName.openARKit.rawValue:""])
            self.isARKitFirstConnectNormal = false
        }
        
        if lastFrame == nil {
            lastFrame = frame
        }
        if curCamera == nil {
            self.curCamera = frame.camera
        }
        let camera = frame.camera
        let transform = camera.transform
        let lastTransform = lastFrame!.camera.transform
        
        // 获取距离参数
        let curV3 = SCNVector3(x: transform.columns.3.x, y: transform.columns.3.y, z: transform.columns.3.z)
        let lastV3 = SCNVector3(x: lastTransform.columns.3.x, y: lastTransform.columns.3.y, z: lastTransform.columns.3.z)
        let distance = VRARKitCaptrueHelper.calDistance(from: curV3, lastKeyFramePose: lastV3)
        
        //获取角度参数
        let curQ = simd_quatf(transform)
        let lastQ = simd_quatf(lastTransform)
        let curV4 = SCNVector4(x: curQ.axis.x, y: curQ.axis.y, z: curQ.axis.z, w: curQ.angle)
        let lastV4 = SCNVector4(x: lastQ.axis.x, y: lastQ.axis.y, z: lastQ.axis.z, w: lastQ.angle)
        
        let angle = VRARKitCaptrueHelper.calAngle(from: curV4, lastKeyFramePose: lastV4)
        if distance > 0.08 || angle > 8 {
            captureImageAndData(frame: frame, curV3: curV3, curV4: curV4)
        }
    }
    
    func captureImageAndData(frame: ARFrame, curV3: SCNVector3, curV4: SCNVector4) {
//        lastFrame = frame
//        _=VRFileHelper.createFramesFolderInCache()
//        let imageName = String (format:  "%012d" , self.picIndex).appending(".jpg")
//        self.safeToastOnMainQueue(str: "image id : \(imageName)")
//        //printLog("采集帧 --- \(imageName)")
//        let imagePiexlBuffer = frame.capturedImage
//        let image = VRImageHelper.create(pixelBuffer: imagePiexlBuffer)
//        let imagePath = VRFileHelper.getFramesPathUrl()?.path.appending("/\(imageName)")
//        if VRImageHelper.saveData(data: Data, filePath: <#T##String?#>)(image: image, filePath: imagePath) {
//            //2 cyber_record_infos.txt 图像文件名，时间戳，AREngine输出的位姿平移量t，AREngine输出的位姿旋转量q，方位角，GPS
//            let timeMS = Date().timeIntervalSince1970
//            let milli = CLongLong(round(timeMS*1000))
//            //let eulAngle = frame.camera.eulerAngles
//            guard let yaw = self.motionManager.deviceMotion?.attitude.yaw else {return}
//            guard let pitch = self.motionManager.deviceMotion?.attitude.pitch  else {return}
//            guard let roll = self.motionManager.deviceMotion?.attitude.roll  else {return}
//            let cyber_record_info = "\(imageName),\(milli),\(curV3.x),\(curV3.y),\(curV3.z),\(curV4.x),\(curV4.y),\(curV4.z),\(curV4.w),\(yaw),\(pitch),\(roll),\(0),\(0),\(0)\n"
//            VRFileHelper.writeStringToCyberRecordInfos(dataStr: cyber_record_info)
//            // 帧ID+1 最后帧数会多+1 总帧数要-1
//            safeSetPicIndex(index: self.picIndex + 1)
//            if width == nil || height == nil {
//                width = CVPixelBufferGetWidth(imagePiexlBuffer)
//                height = CVPixelBufferGetHeight(imagePiexlBuffer)
//            }
//        }
    }
    
    func createFinalData() {
        //3 preprocess_infos.txt 1.3 整体数据信息文件
        let videoID = 1// 视频ID，从0开始递增
        guard let videoName = VRFileHelper.getTotoalFolderName() else {
            printLog("videoName is nil")
            return
        }// 视频序列名称
        let dataType = 0//  默认为0
        let startFrameID = 1// 当前序列起始帧号
        let endFrameID = self.picIndex-1 // 当前序列结束帧号
        let frameNum = self.picIndex-1// 当前序列帧数
        let frameRate = 30// 当前序列实际帧率
        let flag = 1// 是否有slam位姿? 1: yes, 0, no
        guard let fx = self.curCamera?.intrinsics.columns.0[0] else {return}// focal length x
        guard let fy = self.curCamera?.intrinsics.columns.1[1] else {return}// focal length y
        guard let cx = self.curCamera?.intrinsics.columns.2[0] else {return}// prior principle point x
        guard let cy = self.curCamera?.intrinsics.columns.2[1] else {return}// prior principle point y
        let distCoef = 0//double distCoef[5];   // distortion coeffiencts
         
        guard let w = width,let h = height else {return}
        printLog("w:\(w) --- h:\(h)")
        let preprocess_info = "\(videoID) \(videoName) \(dataType) \(startFrameID) \(endFrameID) \(frameNum) \(frameRate) \(w) \(h) \(flag) \(fx) \(fy) \(cx) \(cy) 0 0 0 0 0"
        VRFileHelper.writeStringToPreprocessInfos(dataStr: preprocess_info)
        //4 intrinsic_parameter.txt 内参文件
        let intrinsic_parameter = "\(w) \(h) \(fx) \(fy) \(cx) \(cy) 0 0 0 0 0"
        VRFileHelper.wirteStringIntrinsicParameter(dataStr: intrinsic_parameter)
        
        //6 room.txt 2.2 房间属性标签
    }
}
