//
//  SphereView.swift
//  SdkSample
//

import WebKit
import flutter_boost
import SnapKit
//import VRWifiName

let ScreenWidth = UIScreen.main.bounds.width
let ScreenHeight = UIScreen.main.bounds.height

class VRPreviewDownloadVC: UIViewController {
    var startExportTimer: Timer?
    var urlString: String?
    var imgeV: UIImageView?
    var flutterPamrams: [String:Any]?
    var audioPlayer: VRAudioPlayer?
    var titleStr: String? = ""
    var titleLabel: UILabel?
    var isExporting = false
    //var task: URLSessionDataTask?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.view.backgroundColor = .black
        initUI()
        VRNetObserver.startObservingNetworkStatus(host: nil) {
            
        } reachableViaWWANHandler: {
            
        } reachableViaWIFIHandler: {
            
        }
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
//        self.view.bringSubviewToFront(exportBtn)
        self.view.bringSubviewToFront(imgeV!)
        self.titleLabel?.text = self.titleStr
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        self.startExportTimer?.invalidate()
    }
    
    @objc func importAction(_ sender: Any) {
        requestDataFromCamera()
    }
    
    @objc func backAction(_ sender: Any) {
        self.dismiss(animated: false)
    }
    
    func requestDataFromCamera() {
        if isExporting { return }
        isExporting = true
        VRProgressHUD.show(shortText: "导出中")
        let savePath = VRFileHelper.getPanoOriginalPathUrl()?.path
        DispatchQueue.global().async {
            VRRequestCameraDataHelper.shared.requestDataFromCamera(urlStr: self.urlString,savePath: savePath) {path, imageName in
                self.isExporting = false
                self.flutterPamrams?["relativeCoverPath"] = "/pano_original/\(imageName)"
                self.flutterPamrams?["fileName"] = imageName
                self.flutterPamrams?["tempThumbnail"] = path
                if let p = self.flutterPamrams {
                    sendMessageToFlutter(eventName: VRFlutterEventName.capturePreviewParams.rawValue, arguments: [VRFlutterEventName.capturePreviewParams.rawValue:p])
                }
                DispatchQueue.main.async {
                    VRProgressHUD.dismiss()
                    self.startExportTimer?.invalidate()
                    //self.audioPlayer?.playAudio(imageName: "download_finish")
                    for w in UIApplication.shared.windows {
                        if w.tag == flutterTag {
                            w.makeKeyAndVisible()
                        }
                        if w.tag == flutterToNativeTag {
                            w.isHidden = true
                            w.rootViewController = nil
                        }
                    }
                }
            } failed: {error in
                self.isExporting = false
                VRProgressHUD.showFailed(shortText: "导出失败，请检查设备链接状态。")
            }
        }
    }
}

fileprivate extension VRPreviewDownloadVC {
    func initUI() {
        let view360 = VRPreView()
        self.view.addSubview(view360)
        view360.snp.makeConstraints { make in
            make.top.equalTo(self.view).offset(0)
            make.left.right.equalTo(self.view).offset(0)
            make.bottom.equalTo(self.view).offset(0)
        }
        view360.updateImage(imageUrl: urlString ?? "")
        imgeV = UIImageView(frame: CGRect(x: 0, y: 100, width: self.view.bounds.width, height: 200))
        self.view.addSubview(imgeV!)
        let exportBtnWH: CGFloat = 75
        let exportBtn = UIButton(type: .custom)
        exportBtn.setTitleColor(.black, for: .normal)
        exportBtn.setBackgroundImage(UIImage(named: "confirm"), for: .normal)
        exportBtn.addTarget(self, action: #selector(importAction), for: .touchUpInside)
        self.view.addSubview(exportBtn)
        exportBtn.layer.cornerRadius = exportBtnWH/2
        exportBtn.clipsToBounds = true
        exportBtn.backgroundColor = .white
        exportBtn.snp.makeConstraints { make in
            make.bottom.equalTo(self.view).offset(-90)
            make.centerX.equalTo(self.view)
            make.width.height.equalTo(exportBtnWH)
        }
        let backBtnWH: CGFloat = 20
        let backBtn = UIButton(type: .custom)
        backBtn.setBackgroundImage(UIImage(named: "icon-navbar-return"), for: .normal)
        backBtn.addTarget(self, action: #selector(backAction), for: .touchUpInside)
        self.view.addSubview(backBtn)
        backBtn.backgroundColor = .clear
        backBtn.imageView?.backgroundColor = .clear
        backBtn.snp.makeConstraints { make in
            make.top.equalTo(self.view).offset(56)
            make.left.equalTo(self.view).offset(backBtnWH)
            make.width.height.equalTo(backBtnWH)
        }
        
        titleLabel = UILabel(frame: CGRect(x: (ScreenWidth-100)/2, y: 56, width: 100, height: 20))
        titleLabel?.text = self.titleStr
        self.titleLabel?.textColor = .white
        self.titleLabel?.textAlignment = .center
        self.titleLabel?.font = UIFont.systemFont(ofSize: 18)
        self.view.addSubview(titleLabel!)
        
        let remakeBtn = UIButton()
        remakeBtn.backgroundColor = .clear
        remakeBtn.addTarget(self, action: #selector(backAction), for: .touchUpInside)
        view.addSubview(remakeBtn)
        remakeBtn.snp.makeConstraints { make in
            make.bottom.equalTo(exportBtn.snp.bottom).offset(-10)
            make.right.equalTo(exportBtn.snp.left).offset(-80)
            make.width.equalTo(30)
            make.height.equalTo(50)
        }
        
        let remakeImgV = UIImageView()
        remakeImgV.backgroundColor = .clear
        remakeImgV.image = UIImage(named: "remake")
        remakeBtn.addSubview(remakeImgV)
        remakeImgV.snp.makeConstraints { make in
            make.top.equalTo(remakeBtn.snp.top)
            make.width.equalTo(20)
            make.height.equalTo(20)
            make.centerX.equalTo(remakeBtn)
        }

        let remakeLabel = UILabel()
        remakeLabel.textAlignment = .center
        remakeLabel.textColor = .white
        remakeLabel.text = "重拍"
        remakeLabel.font = UIFont.systemFont(ofSize: 14)
        remakeBtn.addSubview(remakeLabel)
        remakeLabel.snp.makeConstraints { make in
            make.top.equalTo(remakeImgV.snp.bottom).offset(6)
            make.centerX.equalTo(remakeBtn)
            make.width.equalTo(32)
            make.height.equalTo(20)
        }
    }
}

extension VRPreviewDownloadVC {
    override var preferredStatusBarStyle: UIStatusBarStyle {
      return .lightContent
    }
}
