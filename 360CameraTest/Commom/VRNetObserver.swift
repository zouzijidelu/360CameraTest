//
//  VRNetObserver.swift
//  VRCapture_iOS
//
//  Created by wzb on 2023/5/31.
//

import UIKit
import Alamofire

class VRNetObserver {
    public static let didRemindPlaybackViaWWANOnceKey = "didRemindPlaybackViaWWANOnce"
    
    private static var reach: NetworkReachabilityManager?
    
    /// Check basic network status(aka check if there are valid connections to internet).
    ///
    /// - Parameters:
    ///   - notReachableHanldler: Not reachable callback
    ///   - reachableViaWWANHandler: WWAN is available callback.
    ///   - reachableViaWIFIHandler: WiFi is available callback
    /// - Returns: True - Maybe can connect to internet. False - No route connect to internet.
    @discardableResult
    public static func checkBasicNetworkStatus(
        notReachableHanldler: () -> Void,
        reachableViaWWANHandler: () -> Void,
        reachableViaWIFIHandler: (() -> Void)? = nil) -> Bool {
        
        // TODO: check error.  关闭蜂窝移动访问权限，保持4G连接，测试结果为Reachable. Maybe system bug.
        if let reach = NetworkReachabilityManager() {
            handleStatus(
                status: reach.networkReachabilityStatus,
                notReachableHandler: notReachableHanldler,
                reachableViaWWANHandler: reachableViaWWANHandler,
                reachableViaWIFIHandler: reachableViaWIFIHandler)
            return true
        } else {
            printLog("WARNIG: net observer prepare failed")
            return false
        }
    }
    
    /// Start listening network status change.
    ///
    /// - Parameters:
    ///   - host: The host name to check.
    ///   - notReachableHandler: Callback for unreacheable to host.
    ///   - reachableViaWWANHandler: Callback for reacheable to host over WWAN.
    ///   - reachableViaWIFIHandler: Callback for reacheable to host over WiFi.
    /// - Returns: True: Reachable to host. False: unreachable to host.
    @discardableResult
    public static func startObservingNetworkStatus(
        host: String?,
        notReachableHandler: @escaping () -> Void,
        reachableViaWWANHandler: @escaping () -> Void,
        reachableViaWIFIHandler: @escaping () -> Void) -> Bool {
        
        if let reach = ((host != nil) ? NetworkReachabilityManager(host: host!) : NetworkReachabilityManager()) {
        VRNetObserver.reach = reach
            reach.startListening()
            reach.listener = { status in
                handleStatus(
                    status: status,
                    notReachableHandler: notReachableHandler,
                    reachableViaWWANHandler: reachableViaWWANHandler,
                    reachableViaWIFIHandler: reachableViaWIFIHandler)
            }
            return true
        } else {
            printLog("WARNIG: net observer prepare failed")
            return false
        }
    }
    
    /// Stop observing network status.
    public static func stopObservingNetworkStatus() {
        reach?.stopListening()
        reach = nil
    }
    
    private static func handleStatus(
        status: NetworkReachabilityManager.NetworkReachabilityStatus,
        notReachableHandler: () -> Void,
        reachableViaWWANHandler: () -> Void,
        reachableViaWIFIHandler: (() -> Void)? = nil) {
        
        switch status {
        case .unknown:
            break
        case .notReachable:
            printLog("网络不可达，请检查网络状态！")
            notReachableHandler()
        case .reachable(let connectionType):
            switch connectionType {
            case .ethernetOrWiFi:
                printLog("移动网络请注意流量消耗")
                reachableViaWIFIHandler?()
            case .wwan:
                printLog("wifi网络")
                reachableViaWWANHandler()
            }
        }
    }
}
/// Check net work status.
///
/// - Parameters:
///   - notReachableHandler: notReachableHandler
///   - reachable: A call back when network connection is available.
public func checkNetWork(notReachableHandler: (() -> Void)?, reachable: (() -> Void)?) {
    
    func handleReachable() {
        if reachable != nil {
            reachable!()
        }
    }
    
    VRNetObserver.checkBasicNetworkStatus(notReachableHanldler: {
        printLog("Unrechable!!")
        if notReachableHandler != nil {
            notReachableHandler!()
        }
    }, reachableViaWWANHandler: {
        handleReachable()
    }, reachableViaWIFIHandler: {
        handleReachable()
    })
}
