//
//  VRRequestManager.swift
//  VRCapture_iOS
//
//  Created by wzb on 2023/5/9.
//

import UIKit

final class VRUserAccessorKey<T>: VRUserAccessorKeys {}

class VRUserAccessorKeys: RawRepresentable, Hashable {
    let rawValue: String
    required init!(rawValue: String) {
        self.rawValue = rawValue
    }
    convenience init(_ key: String) {
        self.init(rawValue: key)
    }
    
    var hashValue: Int {
        return rawValue.hashValue
    }
}
extension VRUserAccessorKeys {
    
    static let hasLogined = VRUserAccessorKey<Bool>("hasLogined")
    static let accessKey = VRUserAccessorKey<String>("accessKey")
    static let secretKey = VRUserAccessorKey<String>("secretKey")
    static let bucketName = VRUserAccessorKey<String>("bucketName")
    static let endpoint = VRUserAccessorKey<String>("endpoint")
    
    static let expireTime = VRUserAccessorKey<Double>("expireTime")
    static let vipStatus = VRUserAccessorKey<Int>("vipStatus")
    static let shortVersion = VRUserAccessorKey<String>("productCycle")
    static let token = VRUserAccessorKey<String>("flutter.token")
}

final class VRUserAccessor {
    
    static let shared = VRUserAccessor()
    let defaults = UserDefaults.standard
    private init() {
        registerDefaultPreferences()
    }
    private func registerDefaultPreferences() {
        
        let defaultValues: [String: Any] =  defaultPreferences.reduce([:]) {
            var dictionary = $0
            if (!($1.value is NSNull)) {
                dictionary[$1.key.rawValue] = $1.value
            }
            return dictionary
        }
        defaults.register(defaults: defaultValues)
    }
    
    let defaultPreferences: [VRUserAccessorKeys: Any] =
     [
        .expireTime : 10000000001,
        .shortVersion : (Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String) ?? "100000000",
        .hasLogined: false,
        .vipStatus: 0,
        .accessKey: VRConfig.defaultaccessKey,
        .secretKey: VRConfig.defaultsecretKey,
        .bucketName: VRConfig.defaultbucketName,
        .endpoint: "obs.cn-north-4.myhuaweicloud.com",
        .token: ""
    ]
}

extension VRUserAccessor {
    subscript(key: VRUserAccessorKey<Any>) -> Any? {
        get { return defaults.object(forKey: key.rawValue) }
        set { defaults.set(newValue, forKey: key.rawValue) }
    }
    
    subscript(key: VRUserAccessorKey<URL>) -> URL? {
        get { return defaults.url(forKey: key.rawValue) }
        set { defaults.set(newValue, forKey: key.rawValue) }
    }
    
    subscript(key: VRUserAccessorKey<[Any]>) -> [Any]? {
        get { return defaults.array(forKey: key.rawValue) }
        set { defaults.set(newValue, forKey: key.rawValue) }
    }
    
    subscript(key: VRUserAccessorKey<[String: Any]>) -> [String: Any]? {
        get { return defaults.dictionary(forKey: key.rawValue) }
        set { defaults.set(newValue, forKey: key.rawValue) }
    }
    
    subscript(key: VRUserAccessorKey<String>) -> String? {
        get { return defaults.string(forKey: key.rawValue) }
        set { defaults.set(newValue, forKey: key.rawValue) }
    }
    
    subscript(key: VRUserAccessorKey<[String]>) -> [String]? {
        get { return defaults.stringArray(forKey: key.rawValue) }
        set { defaults.set(newValue, forKey: key.rawValue) }
    }
    
    subscript(key: VRUserAccessorKey<Data>) -> Data? {
        get { return defaults.data(forKey: key.rawValue) }
        set { defaults.set(newValue, forKey: key.rawValue) }
    }
    
    subscript(key: VRUserAccessorKey<Bool>) -> Bool {
        get { return defaults.bool(forKey: key.rawValue) }
        set { defaults.set(newValue, forKey: key.rawValue) }
    }
    
    subscript(key: VRUserAccessorKey<Int>) -> Int {
        get { return defaults.integer(forKey: key.rawValue) }
        set { defaults.set(newValue, forKey: key.rawValue) }
    }
    
    subscript(key: VRUserAccessorKey<Float>) -> Float {
        get { return defaults.float(forKey: key.rawValue) }
        set { defaults.set(newValue, forKey: key.rawValue) }
    }
    
    subscript(key: VRUserAccessorKey<Double>) -> Double {
        get { return defaults.double(forKey: key.rawValue) }
        set { defaults.set(newValue, forKey: key.rawValue) }
    }
    
}

let Preference : VRUserAccessor = VRUserAccessor.shared
