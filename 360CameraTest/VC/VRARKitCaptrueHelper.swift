//
//  HouseResourceEditor.swift
//  VRCapture_iOS
//
//  Created by wzb on 2023/5/8.
//

import UIKit
import ARKit

class VRARKitCaptrueHelper {
    static func calDistance(from currentPose: SCNVector3, lastKeyFramePose: SCNVector3) -> Float {
        let distanceX = currentPose.x - lastKeyFramePose.x
        let distanceY = currentPose.y - lastKeyFramePose.y
        let distanceZ = currentPose.z - lastKeyFramePose.z

        return sqrtf((distanceX * distanceX) + (distanceY * distanceY) + (distanceZ * distanceZ))
    }
    
    static func calAngle(from currentPose: SCNVector4, lastKeyFramePose: SCNVector4) -> Float {
        var currentPoseQuan: [Float] = [1.0, 0.0, 0.0, 0.0]
        var keyFramePoseQuan: [Float] = [1.0, 0.0, 0.0, 0.0]
        currentPoseQuan[0] = currentPose.x
        currentPoseQuan[1] = currentPose.y
        currentPoseQuan[2] = currentPose.z
        currentPoseQuan[3] = currentPose.w
        
        keyFramePoseQuan[0] = lastKeyFramePose.x
        keyFramePoseQuan[1] = lastKeyFramePose.y
        keyFramePoseQuan[2] = lastKeyFramePose.z
        keyFramePoseQuan[3] = lastKeyFramePose.w
        let currentPoseQuanNormal: [Float]  = quanNormalize(q: currentPoseQuan);
        let keyFramePoseQuanNormal: [Float] = quanNormalize(q: keyFramePoseQuan);
        let currentPoseRotationMatrix: [[Float]] = quan2RotationMatrix(quan: currentPoseQuanNormal);
        let keyframePoseRotationMatrix: [[Float]] = quan2RotationMatrix(quan: keyFramePoseQuanNormal);
        let dotResult: [[Float]] = dotMatrixT(r1: currentPoseRotationMatrix, r2: keyframePoseRotationMatrix);
        let traceValue: Float = trace(r: dotResult);
        var coseValue: Float = (traceValue - 1.0) / 2.0;

        if (coseValue > 1.0) {
            coseValue = 1.0
        }
        
        let acosValue = acos(coseValue) * 180.0
        let angleInDegree: Double = Double(acosValue / 3.141592502593994)
        
//        print("acosValue: \(acosValue)")
        return Float(angleInDegree)
    }
    
    static func quan2RotationMatrix(quan :[Float]) -> [[Float]] {
        let w = quan[0];
        let x = quan[1];
        let y = quan[2];
        let z = quan[3];
        var rotationMatrix: [[Float]] = [[0.0, 0.0, 0.0], [0.0, 0.0, 0.0], [0.0, 0.0, 0.0]]
        let t1 = 1.0-y*2.0*y
        let t2 = z*2.0*z
        rotationMatrix[0][0] = t1 - t2
        rotationMatrix[0][1] = (x * 2.0 * y) + (w * 2.0 * z);
        rotationMatrix[0][2] = ((x * 2.0) * z) - ((w * 2.0) * y);
        rotationMatrix[1][0] = ((x * 2.0) * y) - ((w * 2.0) * z);
        rotationMatrix[1][1] = (1.0 - ((x * 2.0) * x)) - ((z * 2.0) * z);
        rotationMatrix[1][2] = (y * 2.0 * z) + (w * 2.0 * x);
        rotationMatrix[2][0] = (x * 2.0 * z) + (w * 2.0 * y);
        rotationMatrix[2][1] = ((y * 2.0) * z) - ((w * 2.0) * x);
        rotationMatrix[2][2] = (1.0 - ((x * 2.0) * x)) - ((2.0 * y) * y);
        return rotationMatrix;
    }
    
    static func dotMatrixT(r1: [[Float]], r2: [[Float]]) -> [[Float]] {
        var dotResult: [[Float]] = [[0.0, 0.0, 0.0], [0.0, 0.0, 0.0], [0.0, 0.0, 0.0]];
        dotResult[0][0] = (r1[0][0] * r2[0][0]) + (r1[0][1] * r2[0][1]) + (r1[0][2] * r2[0][2]);
        dotResult[0][1] = (r1[0][0] * r2[1][0]) + (r1[0][1] * r2[1][1]) + (r1[0][2] * r2[1][2]);
        dotResult[0][2] = (r1[0][0] * r2[2][0]) + (r1[0][1] * r2[2][1]) + (r1[0][2] * r2[2][2]);
        dotResult[1][0] = (r1[1][0] * r2[0][0]) + (r1[1][1] * r2[0][1]) + (r1[1][2] * r2[0][2]);
        dotResult[1][1] = (r1[1][0] * r2[1][0]) + (r1[1][1] * r2[1][1]) + (r1[1][2] * r2[1][2]);
        dotResult[1][2] = (r1[1][0] * r2[2][0]) + (r1[1][1] * r2[2][1]) + (r1[1][2] * r2[2][2]);
        dotResult[2][0] = (r1[2][0] * r2[0][0]) + (r1[2][1] * r2[0][1]) + (r1[2][2] * r2[0][2]);
        dotResult[2][1] = (r1[2][0] * r2[1][0]) + (r1[2][1] * r2[1][1]) + (r1[2][2] * r2[1][2]);
        dotResult[2][2] = (r1[2][0] * r2[2][0]) + (r1[2][1] * r2[2][1]) + (r1[2][2] * r2[2][2]);
        return dotResult;
    }

    static func trace(r: [[Float]]) -> Float {
        return r[0][0] + r[1][1] + r[2][2];
    }

    static func quanNormalize(q: [Float]) -> [Float] {
        let total: Double = Double((q[0] * q[0]) + (q[1] * q[1]) + (q[2] * q[2]) + (q[3] * q[3]));
        
        let normValue = Float(sqrt(total))
        var qNormal: [Float] = [0.0, 0.0, 0.0, 0.0]
        qNormal[0] = q[0] / normValue
        qNormal[1] = q[1] / normValue
        qNormal[2] = q[2] / normValue
        qNormal[3] = q[3] / normValue
        return qNormal
    }
}
