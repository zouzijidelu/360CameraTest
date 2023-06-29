//
//  ThetaSdk.swift
//  SdkSample
//
import UIKit
import THETAClient

typealias ThetaHandlerWithError<T> = (_ response: T?, _ error: Error?) -> Void
typealias ThetaHandler<T> = (_ response: T) -> Void
typealias ThetaErrorHandler = (_ error: Error?) -> Void
typealias ThetaFrameHandler = (_ frame: Data) -> Bool
typealias ThetaException = ThetaRepository.ThetaRepositoryException
typealias ThetaInfo = ThetaRepository.ThetaInfo
typealias ThetaState = ThetaRepository.ThetaState
typealias ThetaFileInfo = ThetaRepository.FileInfo
typealias ThetaFileType = ThetaRepository.FileTypeEnum

let theta = VRThetaSdk()
enum ThetaError : Error {
  case onError(String)
}
class VRThetaSdk {
    static let endPoint: String = "http://192.168.1.1"
    var thetaRepository: ThetaRepository? = nil
    var lastInfo: ThetaInfo? = nil

    func initialize() async throws {
        if (thetaRepository != nil) {
            return;
        }
        thetaRepository = try await withCheckedThrowingContinuation {continuation in
            //let Config = THETACThetaRepositoryConfig(dateTime: <#T##String?#>, language: <#T##ThetaRepository.LanguageEnum?#>, offDelay: <#T##ThetaRepositoryOffDelay?#>, sleepDelay: <#T##ThetaRepositorySleepDelay?#>, shutterVolume: <#T##KotlinInt?#>)
            ThetaRepository.Companion.shared.doNewInstance(
              endpoint:Self.endPoint,
              config:nil,
              timeout:nil
            ) {resp, error in
                if let response = resp {
                    continuation.resume(returning: response)
                    //todo 发送消息给flutter 链接成功
                    
                }
                if let thetaError = error {
                    continuation.resume(throwing: thetaError)
                    //todo 发送消息给flutter 链接失败
                }
            }
        }
        // 初始化时先设置一次参数 避免第一次链接全景相机 并且第一次拍照时 失败
        try await thetaRepository?.getPhotoCaptureBuilder().setFilter(filter: ThetaRepository.FilterEnum.hdr).setExposureProgram(program: .aperturePriority)?.setIsoAutoHighLimit(iso: .iso800)?.setAperture(aperture: .aperture56)?.setWhiteBalance(whiteBalance: ThetaRepository.WhiteBalanceEnum.auto_)?.setExposureDelay(delay: .delayOff)?
          .build()
    }

    func info(_ completionHandler: @escaping ThetaHandler<ThetaInfo>) async throws {
        try await initialize()
        let response: ThetaInfo = try await withCheckedThrowingContinuation {continuation in
            thetaRepository!.getThetaInfo {resp, error in
                if let response = resp {
                    continuation.resume(returning: response)
                }
                if let thetaError = error {
                    continuation.resume(throwing: thetaError)
                }
            }
        }
        lastInfo = response
        completionHandler(response)
    }
    
    func livePreview(frameHandler: @escaping ThetaFrameHandler) async throws {
        try await initialize()
        class FrameHandler: KotlinSuspendFunction1 {
            static let FrameInterval = CFTimeInterval(1.0/10.0)
            let handler: ThetaFrameHandler
            var last: CFTimeInterval = 0
            init(_ handler: @escaping ThetaFrameHandler) {
                self.handler = handler
            }
            func invoke(
              p1: Any?,
              completionHandler: @escaping ThetaHandlerWithError<Any>
            ) {
                let now = CACurrentMediaTime()
                if (now - last > Self.FrameInterval) {
                    autoreleasepool {
                        let nsData = PlatformKt.frameFrom(
                          packet: p1 as! KotlinPair<KotlinByteArray, KotlinInt>
                        )
                        let result = handler(nsData)
                        completionHandler(result, nil)
                    }
                    last = now
                } else {
                    completionHandler(true, nil)
                }
            }
        }
        let _:Bool = try await withCheckedThrowingContinuation {continuation in
            thetaRepository!.getLivePreview(
              frameHandler: FrameHandler(frameHandler)
            ) {error in
                if let thetaError = error {
                    continuation.resume(throwing: thetaError)
                } else {
                    continuation.resume(returning: true)
                }
            }
        }
    }

    func listPhotos(_ completionHandler: @escaping ThetaHandler<[ThetaFileInfo]>) async throws {
        try await initialize()
        let response: [ThetaFileInfo]
          = try await withCheckedThrowingContinuation {continuation in
              thetaRepository!.listFiles(fileType: ThetaFileType.image, startPosition: 0,
                                         entryCount: 1000) {resp, error in
                  if let response = resp {
                      continuation.resume(returning: response)
                  }
                  if let thetaError = error {
                      continuation.resume(throwing: thetaError)
                  }
              }
          }
        completionHandler(response)
    }

    func takePicture(_ callback: @escaping (_ url: String) -> Void) async throws {
        try await initialize()
        let photoCapture: PhotoCapture = try await withCheckedThrowingContinuation {continuation in
            thetaRepository!.getPhotoCaptureBuilder().setFilter(filter: ThetaRepository.FilterEnum.noiseReduction).setFilter(filter: ThetaRepository.FilterEnum.hdr).setExposureProgram(program: .aperturePriority)?.setIsoAutoHighLimit(iso: .iso800)?.setAperture(aperture: .aperture35)?.setWhiteBalance(whiteBalance: ThetaRepository.WhiteBalanceEnum.auto_)?.setExposureDelay(delay: .delayOff)?
              .build {capture, error in
                  if let photoCapture = capture {
                      printLog("thetaRepository photoCapture")
                      continuation.resume(returning: photoCapture)
                  }
                  if let thetaError = error {
                      continuation.resume(throwing: thetaError)
                      printLog("thetaRepository thetaError --- \(thetaError)")
                  }
              }
        }
        class Callback: PhotoCaptureTakePictureCallback {
            let callback: (_ url: String?, _ error: Error?) -> Void
            init(_ callback: @escaping (_ url: String?, _ error: Error?) -> Void) {
                self.callback = callback
            }
            func onSuccess(fileUrl: String) {
                printLog("onSuccess")
                callback(fileUrl, nil)
            }
            func onError(exception: ThetaException) {
                print("onError -- \(exception.description())")
                let unauailable = ThetaError.onError(exception.description())
                callback(nil, unauailable)
            }
        }
        let photoUrl: String = try await withCheckedThrowingContinuation {continuation in
            photoCapture.takePicture(
              callback: Callback {fileUrl, error in
                  if let photoUrl = fileUrl {
                      printLog("callback photoUrl")
                      continuation.resume(returning: photoUrl)
                  }
                  if let thetaError = error {
                      printLog("callback thetaError --- \(thetaError)")
                      continuation.resume(throwing: thetaError)
                  }
              }
            )
        }
        callback(photoUrl)
    }
}

