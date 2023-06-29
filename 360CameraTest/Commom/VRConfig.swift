//
//  VRConfig.swift
//  VRCapture_iOS
//
//  Created by wzb on 2023/6/8.
//

import Foundation
class VRConfig {
#if BETAVERSION // 判断是否在测试环境下
    static let defaultaccessKey = "A5MPPBVER7UA9A2Q68N8"
    static let defaultsecretKey = "NyEL9pAQqRoB9wj31jneYpSSdW9BRkJvwKRQk53O"
    static let defaultbucketName = "huawei-vr-test"
#elseif DEVVERSION
    static let defaultaccessKey = "A5MPPBVER7UA9A2Q68N8"
    static let defaultsecretKey = "NyEL9pAQqRoB9wj31jneYpSSdW9BRkJvwKRQk53O"
    static let defaultbucketName = "huawei-vr-test"
#else
    static let defaultaccessKey = "N72GQRZ6BZUUGWMQHGKB"
    static let defaultsecretKey = "mXHVVd9Gi1yzarrPHwH0JDlwuuEXE4O4ihdoFwZ0"
    static let defaultbucketName = "huawei-vr"
#endif
}
