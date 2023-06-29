//
//  VR360CameraCaptureVC.swift
//  VRCapture_iOS
//
//  Created by wzb on 2023/5/18.
//

import UIKit
import Toast_Swift

class FileItem:Identifiable {
    var name: String
    var url: String
    var thumbnail: String
    init(name: String = "", url: String = "", thumbnail: String = "") {
        self.name = name
        self.url = url
        self.thumbnail = thumbnail
    }
}

let ThetaUnavailableError = "Service Unavailable"
class VR360CameraCaptureVC: UIViewController {
    var thetaAPI: VRThetaAPI!
    var isActive = false
    var item: FileItem?
    var collectionData: [String] = ["5秒","15秒","30秒"]
    @IBOutlet weak var fpsBtn: UIButton!
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var secondLabel: UILabel!
    
    var flutterPamrams: [String:Any]?
    var staticCount = 5
    var timeCount: Int = 0
    @IBOutlet weak var collectionFL: UICollectionViewFlowLayout!
    
    @IBOutlet weak var captureBtn: UIButton!
    @IBOutlet weak var previewView: UIImageView!
    @IBOutlet weak var countDownBGView: UIView!
    @IBOutlet weak var countdownCollection: UICollectionView!
    @IBOutlet weak var countdownBGIV: UIImageView!
    
    @IBOutlet weak var countdownBtnLabel: UILabel!
    
    @IBOutlet weak var countdownIV: UIImageView!
    
    var audioPlayer: VRAudioPlayer?
    
    @IBAction func countdownBtnClick(_ sender: Any) {
        if thetaAPI.isTakingPic {
            return
        }
        countDownBGView.isHidden = !countDownBGView.isHidden
    }
    @IBAction func backBtnClick(_ sender: Any) {
        if thetaAPI.isTakingPic {
            return
        }
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
    
    @IBAction func fpsBtnClick(_ sender: Any) {
        fpsBtn.isSelected = !fpsBtn.isSelected
    }
    deinit {
        printLog("VR360CameraCaptureVC deinit")
    }
}

// lift cycle
extension VR360CameraCaptureVC {
    override func viewDidLoad() {
        super.viewDidLoad()
        thetaAPI = VRThetaAPI()
        audioPlayer = VRAudioPlayer()
        initUI()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        //self.thetaAPI.INSCameraManagerSocketSetup()
        self.thetaAPI.previewing = true
        self.livePreview()
        if let title = flutterPamrams?["title"] as? String {
            titleLabel.text = title
        }
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        self.thetaAPI.previewing = false
            thetaAPI.startCaptureTimer?.invalidate()
    }
    
    func initUI() {
        countDownBGView.isHidden = true
        countdownCollection.backgroundColor = .clear
        let image = UIImage(named: "countdownBg")
        image?.resizableImage(withCapInsets: UIEdgeInsets(top: 0, left: 100, bottom: 0, right: 0), resizingMode: .stretch)
        countdownBGIV.image = image
        resetTimeData()
        titleLabel.text = "客厅"
//        self.livePreview()
        collectionFL.minimumLineSpacing = 30
        collectionFL.minimumInteritemSpacing = 30
        timeCount = self.staticCount
        secondLabel.text = "\(self.staticCount)"
        countdownBtnLabel.text = secondLabel.text
        fpsBtn.setTitle("不允许间隔采样", for:  .normal)
        fpsBtn.setTitle("允许间隔采样", for: .selected)
    }
    
    override var preferredStatusBarStyle: UIStatusBarStyle {
      return .lightContent
    }
}

let cellID = "VRCountdownCell"
extension VR360CameraCaptureVC: UICollectionViewDataSource, UICollectionViewDelegate {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return collectionData.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let title = collectionData[indexPath.row]
        if let cell = collectionView.dequeueReusableCell(withReuseIdentifier: cellID, for: indexPath) as? VRCountdownCell {
            cell.titleLabel.text = title
            if "\(staticCount)秒" == title {
                cell.titleLabel.textColor = UIColor.transferStringToColor("5C5DFF")
            } else {
                cell.titleLabel.textColor = .white
            }
            return cell
        }
        
        return UICollectionViewCell()
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        setCountdownTime(index: indexPath.row)
        collectionView.reloadData()
    }

    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
       
        return CGSize(width: 120, height: collectionView.frame.height)
    }
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, insetForSectionAt section: Int) -> UIEdgeInsets {
        return UIEdgeInsets(top: 30, left: 0, bottom: 0, right: 20)
    }

    
    func setCountdownTime(index: Int) {
        var countStr = collectionData[index]
        guard let count = Int(countStr.replacingOccurrences(of: "秒", with: "")) else {return}
        timeCount = count
        staticCount = count
        secondLabel.text = "\(count)"
        let imageName = (count == 0) ? "countdown" : "countdown_selected"
        countdownIV.image = UIImage(named: imageName)
        countDownBGView.isHidden = true
        countdownBtnLabel.text = secondLabel.text
    }
}


// private
fileprivate extension VR360CameraCaptureVC {
    func livePreview() {
        
        self.thetaAPI.livePreview(previewView: previewView)
    }
    
    @IBAction func takeAPhoto(_ sender: Any) {
        printLog("takeAPhoto click")
        countDown_1(interval: self.timeCount)
    }
    
    // MARK: 倒计时一
    func countDown_1(interval:Int) -> Void {
        if self.thetaAPI.isTakingPic {
            return
        }
        self.audioPlayer?.playAudio(imageName: "shooting_start")
        self.thetaAPI.isTakingPic = true
        secondLabel.isHidden = (self.timeCount == 0)
        if timeCount == 3 {
            self.audioPlayer?.playAudio(imageName: "\(self.timeCount)")
        }
        Timer.scheduledTimer(withTimeInterval: 1, repeats: true, block: { (timer) in
            if self.timeCount > 1 {
                self.timeCount -= 1
                self.secondLabel.text = "\(self.timeCount)"
                if self.timeCount <= 3 {
                    self.audioPlayer?.playAudio(imageName: "\(self.timeCount)")
                }
            } else if self.timeCount <= 1 {
                timer.invalidate()
                self.resetTimeData()
                VRProgressHUD.show(shortText: "拍摄中。。。")
                Task.init {
                    printLog("thetaAPI.takePhoto")
                    await self.thetaAPI.takePhoto(self.fpsBtn.isSelected) {photoUrl in
                        
                        let parts = photoUrl.components(separatedBy: "/")
                        self.item = FileItem(
                            name: parts[parts.count - 1],
                            url: photoUrl
                        )
                        //isActive = true
                        self.audioPlayer?.playAudio(imageName: "shooting_finish")
                        VRProgressHUD.dismiss()
                        DispatchQueue.main.async {
                            let vc = VRPreviewDownloadVC()
                            vc.flutterPamrams = self.flutterPamrams
                            vc.urlString = photoUrl
                            vc.titleStr = self.titleLabel.text
                            vc.modalPresentationStyle = .fullScreen
                            self.present(vc, animated: false)
                        }
                        
                    } failed: {error in
                        // TODO: handle error
                        printLog("takePhoto --- error --- \(error)")
                        // 偶现首次链接相机，首次拍摄失败问题
                        //            if error.localizedDescription.contains(ThetaUnavailableError) {
                        //                Task.init {
                        //                    await self.takePhoto()
                        //                }
                        //            } else {
                        VRProgressHUD.showFailed(shortText: "拍摄失败，请重试！")
                        //            }
                        
                    }

                }
            }
        });
    }
    
    
    func resetTimeData() {
        self.secondLabel.isHidden = true
        self.timeCount = self.staticCount
        self.secondLabel.text = "\(self.staticCount)"
    }
}
