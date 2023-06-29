//
//  FirstViewController.swift
//  VRCapture_iOS
//
//  Created by wzb on 2023/5/4.
//

import UIKit
import flutter_boost
import Toast_Swift
import ARKit
import CoreMotion

let status = "status"

func sendMessageToFlutter(eventName: String, arguments: [String: Any]) {
    printLog("ios send to flutter event --- \(eventName) --- arguments --- \(String(describing: arguments))")
    FlutterBoost.instance().sendEventToFlutter(with: eventName, arguments: arguments)
}

enum VRFlutterEventName: String {
    case openARKit
    case pauseARKit
    case trackingStateChange
    case requestCompletion
    case panoInfoPath
    case uploadOBS
    case capturePreviewParams
    case unsavedPath
    case get360CameraStatus
    case uploadHouseImage
}

enum VREventDicKey: String {
    case houseId
    case status
    case roomJson
    case uploadOBS
    case unsavedPath
}

class VRHomeVC: FlutterViewController, ARSessionDelegate, CLLocationManagerDelegate {
    var chiledEditorVC: VRARKitCaptrueVC?
    //存删除的函数
    var removeOpenListener:FBVoidCallback?
    var removePauseListener:FBVoidCallback?
    var removeUploadOBSListener:FBVoidCallback?
    var removeGet360CameraStatusListener: FBVoidCallback?
    var removeOBSUploadListener: FBVoidCallback?
    
    var httpOBSHelper = VRHttpOBSHelper()
    var locationManager:CLLocationManager?//定义一个地理管理器
    
    deinit {
        //在退出的时候解除注册(比如 deinit/dealloc 中)
        removeOpenListener?()
        removePauseListener?()
        removeUploadOBSListener?()
        removeGet360CameraStatusListener?()
        removeOBSUploadListener?()
    }
}

//lift cycle
extension VRHomeVC {
    override func viewDidLoad() {
        super.viewDidLoad()
        navigationController?.navigationBar.isHidden = true
        openLocation()
        addFlutterBoostListener()
        httpOBSHelper.getOBSInfo()
        initChildVC()
        goToFlutterVC()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
    }
    
    func initChildVC() {
        chiledEditorVC = VRARKitCaptrueVC()
        chiledEditorVC?.view.frame = self.view.bounds
        chiledEditorVC?.set(trackingStateChangeBlock: {(state: String) in
            sendMessageToFlutter(eventName: VRFlutterEventName.trackingStateChange.rawValue, arguments: [VREventDicKey.status.rawValue:"limited"])
        })
        addChild(self.chiledEditorVC!)
        view.addSubview(self.chiledEditorVC!.view)
    }
}


//private
extension VRHomeVC {
    func safeToastOnMainQueue(str: String) {
        DispatchQueue.main.async {
            self.view.makeToast(str,duration: 1.0,position: .center)
        }
    }
    
    func goToFlutterVC() {
        var pageName = "HomePage"
//        if let token = Preference[.token], !token.isEmpty {
//            pageName = "HomePage"
//        }
        let options = FlutterBoostRouteOptions()
        options.pageName = pageName
        options.arguments = ["isPresent":false,"isAnimated":false, "hosturl": VRServiceURL.baseUrl]
        options.completion = { completion in }
        options.onPageFinished = { dic in }
        let vc = FBFlutterViewContainer()
        vc?.setName(options.pageName, uniqueId: options.uniqueId, params: options.arguments, opaque: options.opaque)
        self.navigationController?.present(vc ?? FBFlutterViewContainer(), animated: false)
    }
    
    func openLocation() {
        locationManager = CLLocationManager()
        locationManager?.delegate = self
        locationManager?.desiredAccuracy = kCLLocationAccuracyBest
        locationManager?.distanceFilter = 1000.0
        locationManager?.requestWhenInUseAuthorization()
        locationManager?.requestAlwaysAuthorization()
        locationManager?.startUpdatingLocation()
    }
}

extension VRHomeVC {
    func addFlutterBoostListener() {
        //这里注册事件监听，监听flutter发送到iOS的事件
        removeOpenListener =  FlutterBoost.instance().addEventListener({[weak self] key, dic in
            printLog("receive flutter openARKit --- \(String(describing: dic))")

            let roomjson = dic?[AnyHashable(VREventDicKey.unsavedPath.rawValue)] as? String
            if let path = roomjson?.split(separator: "/").last  {
                VRFileHelper.setTotalFolderPath(name: String(path))
                if let cyberPth = VRFileHelper.getCyberRecordInfosPathUrl()?.path,let index = VRFileHelper.getCyberInfoPicIndex(path: cyberPth) {
                    self?.chiledEditorVC?.picIndex = index
                }
            }
            guard VRFileHelper.createTotalFolderInCache() else {
                return
            }
            _=VRFileHelper.createPanoOriginalInCache()
            _=VRFileHelper.createPanoVideoInCache()
            // 此处 应该传递
            if let path = VRFileHelper.getTotalFolderPathUrlOuter()?.path {
                sendMessageToFlutter(eventName: VRFlutterEventName.panoInfoPath.rawValue, arguments: [VRFlutterEventName.panoInfoPath.rawValue:path])
                printLog("createTotalFolderInCache path --- \(path)")
                printLog("createPanoOriginalInCache path --- \(VRFileHelper.getPanoOriginalPathUrl())")
                printLog("createPanoVideoInCache path --- \(VRFileHelper.getPanoOriginalPathUrl())")
                // 直接返回openARKit成功
                sendMessageToFlutter(eventName: VRFlutterEventName.openARKit.rawValue, arguments: [VRFlutterEventName.openARKit.rawValue:""])
                //self?.chiledEditorVC?.openARKit()
            }
        }, forName: VRFlutterEventName.openARKit.rawValue)
        removePauseListener =  FlutterBoost.instance().addEventListener({[weak self] key, dic in
            printLog("receive flutter pauseARKit --- \(String(describing: dic))")
            self?.chiledEditorVC?.pauseAndSaveData()
            let roomjson = dic?[AnyHashable(VREventDicKey.roomJson.rawValue)] as? String
            guard let data = roomjson?.data(using: .utf8) else {return}
            let json = (try? JSONSerialization.jsonObject(with: data, options: [])) as? [String:Any]
            let roomM: VRRoomModel? = VRDataSerialization.convertToNullableModel(responseResult: json)
            var roomStr = ""
            if let plist = roomM?.panoInfoList {
                for pano in plist {
                    guard let fn = pano.fileName, let rt = pano.roomTitle  else { return }
                    if roomStr.contains(fn)
                    {continue}
                    roomStr.append(fn)
                    roomStr.append(" ")
                    roomStr.append(rt)
                    roomStr.append("\n")
                }
            }
            guard !roomStr.isEmpty else {return}
            VRFileHelper.writeStringToRoom(dataStr: roomStr)
            if let delegate = FlutterBoost.instance().plugin().delegate as? VRBoostDelegate {
                delegate.cameraCaptureVC?.thetaAPI.stopCaptureVideo {
                    VRFileHelper.resetTotoalPth()
                }
            }
            
        }, forName: VRFlutterEventName.pauseARKit.rawValue)
        
        removePauseListener =  FlutterBoost.instance().addEventListener({[weak self] key, dic in
            if self?.httpOBSHelper.isUploadOBS == true {
                return
            }
            printLog("receive flutter uploadOBS --- \(String(describing: dic))")
            let uploadParams = dic?[AnyHashable(VREventDicKey.uploadOBS.rawValue)] as? String
            guard let udata = uploadParams?.data(using: .utf8) else {return}
            guard let ujson = (try? JSONSerialization.jsonObject(with: udata, options: [])) as? [String:Any] else {return}

            self?.httpOBSHelper.addTask(params: ujson)
            
        }, forName: VRFlutterEventName.uploadOBS.rawValue)
        
        removeGet360CameraStatusListener =  FlutterBoost.instance().addEventListener({[weak self] key, dic in
            Task {
                do {
                    try await theta.info {info in
                        printLog(info)
                        sendMessageToFlutter(eventName: VRFlutterEventName.get360CameraStatus.rawValue, arguments: [VREventDicKey.status.rawValue:true])
                    }
                } catch {
                    printLog("theta.info --- \(error)")
                    sendMessageToFlutter(eventName: VRFlutterEventName.get360CameraStatus.rawValue, arguments: [VREventDicKey.status.rawValue:false])
                }
            }
            
        }, forName: VRFlutterEventName.get360CameraStatus.rawValue)
        
        removeOBSUploadListener =  FlutterBoost.instance().addEventListener({[weak self] key, dic in
            printLog("receive flutter obsUpload --- \(String(describing: dic))")

            let uploadHouseImagejson = dic?[AnyHashable(VRFlutterEventName.uploadHouseImage.rawValue)] as? String
            guard let data = uploadHouseImagejson?.data(using: .utf8) else {return}
            let uploadHouseImageMap = (try? JSONSerialization.jsonObject(with: data, options: [])) as? [String:Any]
            //localPath: String, inputPath: String,
            let localPath = uploadHouseImageMap?["localPath"] as? String
            let inputPath = uploadHouseImageMap?["inputPath"] as? String
            //inputPath = "inputfiles/451404dd0858be5d09ab89f7dfa700df_1053/"
            printLog("localPath --- \(localPath) --- inputPath --- \(inputPath)")
            self?.httpOBSHelper.uploadOBSHouseImage(localPath: localPath, inputPath: inputPath)
        }, forName: VRFlutterEventName.uploadHouseImage.rawValue)
    }
}


extension UINavigationController{
    //子页面的状态条(电池栏)样式由它自己来决定
    open override var childForStatusBarStyle: UIViewController?{
        return topViewController
    }
}
