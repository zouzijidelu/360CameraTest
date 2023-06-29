//
//  VRImageHelper.swift
//  VRCapture_iOS
//
//  Created by wzb on 2023/5/11.
//

import UIKit

class VRImageHelper {
    //  需要旋转
    static func create(pixelBuffer: CVPixelBuffer) -> UIImage? {
        let context = CIContext()
        let ciImage = CIImage(cvPixelBuffer: pixelBuffer)
      let rect = CGRect(x: 0, y: 0, width: CVPixelBufferGetWidth(pixelBuffer),
                                    height: CVPixelBufferGetHeight(pixelBuffer))
        guard let cgimage = context.createCGImage(ciImage, from: rect) else {return nil}
        let img = UIImage(cgImage: cgimage)
//        let rImg = rotateImage(img, withAngle: 90)
      return img
    }
    
    static func rotateImage(_ image: UIImage, withAngle angle: Double) -> UIImage? {
        if angle.truncatingRemainder(dividingBy: 360) == 0 { return image }
        
        let imageRect = CGRect(origin: .zero, size: image.size)
        let radian = CGFloat(angle / 180 * Double.pi)
        let rotatedTransform = CGAffineTransform.identity.rotated(by: radian)
        var rotatedRect = imageRect.applying(rotatedTransform)
        rotatedRect.origin.x = 0
        rotatedRect.origin.y = 0
        
        UIGraphicsBeginImageContext(rotatedRect.size)
        guard let context = UIGraphicsGetCurrentContext() else { return nil }
        context.translateBy(x: rotatedRect.width / 2, y: rotatedRect.height / 2)
        context.rotate(by: radian)
        context.translateBy(x: -image.size.width / 2, y: -image.size.height / 2)
        image.draw(at: .zero)
        let rotatedImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        return rotatedImage
    }
    
    static func saveData(data: Data?,filePath: String?) -> Bool {
        guard let data = data, let framesPath = filePath else {
            printLog("❌ saveImage framesPath is nil")
            return false
        }
        return VRFileHelper.manager.createFile(atPath: framesPath, contents: data, attributes: nil)
    }
}
