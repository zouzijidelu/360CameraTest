//
//  VRRequestCameraDataHelper.swift
//  360CameraTest_Beta
//
//  Created by wzb on 2023/6/14.
//

import UIKit
import INSCoreMedia

class VRRequestCameraDataHelper {
    static var shared = VRRequestCameraDataHelper()
    var session = URLSession.shared
    var semphore = DispatchSemaphore(value: 1)
    
    func requestDataFromCamera(urlStr: String?,savePath: String?,success:@escaping(String?,String?)->(),failed:@escaping(Error?)->()) {
        guard let urlStr = urlStr, let url = URL(string: urlStr), let savePath = savePath else  {
            printLog("拍摄流程  360camera request data failed")
            failed(nil)
            return
        }
        session.configuration.timeoutIntervalForRequest = 60
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        self.semphore.wait()
        printLog("拍摄流程  360camera request data 发起请求")
        let task = self.session.dataTask(with: request as URLRequest) {(
            data, response, error) in
            guard let data = data, let _:URLResponse = response, error == nil,let tempName = urlStr.split(separator: "/").last else {
                printLog("拍摄流程 360camera request data failed --- \(url)")
                failed(error)
                return
            }
            var origianlName = "\(tempName)".replacingOccurrences(of: "insp", with: "jpg")
            let path = savePath.appending("/\(origianlName)")
            let parser = INSImageInfoParser(data: data)
            var photoData: Data? = data
            if urlStr.contains("insp"), parser.open() {
                let origin = UIImage(data: data)
                let outputSize = parser.extraInfo?.metadata?.dimension
                let output = self.stitch(image: origin, extraInfo: parser.extraInfo, outputSize: outputSize)
                photoData = output?.pngData()
            }
        
            if VRImageHelper.saveData(data: photoData, filePath: path) {
                printLog("拍摄流程 360camera request data success --- \(url)")
                self.semphore.signal()
                success(path,origianlName)
            } else {
                printLog("拍摄流程 360camera request data failed --- \(url)")
                failed(nil)
            }
        }
        task.resume()
        
    }
    
    func stitch(image: UIImage?, extraInfo: INSExtraInfo?, outputSize: CGSize?) -> UIImage? {
        guard let image = image, let extraInfo = extraInfo, let outputSize = outputSize else {return nil}
        let render = INSFlatPanoOffscreenRender(renderWidth: Int32(outputSize.width), height: Int32(outputSize.height))
        render.eulerAdjust = extraInfo.metadata?.euler
        render.offset = extraInfo.metadata?.offset
        render.gyroStabilityOrientation = GLKQuaternionIdentity
        guard let gyroData = extraInfo.gyroData, let gyroPlayer = INSGyroPBPlayer(pbGyroData: gyroData) else {return nil}
        let orientation = gyroPlayer.getImageOrientation(with: .flatPanoRender)
        render.gyroStabilityOrientation = orientation
        render.setRenderImage(image)
        return render.renderToImage()
    }
}
