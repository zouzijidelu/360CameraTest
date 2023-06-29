//
//  VRVCExtension.swift
//  VRCapture_iOS
//
//  Created by wzb on 2023/5/15.
//

import UIKit

extension UIViewController {
    
    // 获取 tabBarController
    static func getTabBarVC() -> UITabBarController? {
        let tabBarController = UIApplication.shared.keyWindow?.rootViewController
        return tabBarController as? UITabBarController
    }
    
    class func getTopMostViewController(base: UIViewController? = UIApplication.shared.keyWindow?.rootViewController) -> UIViewController? {
        if let nav = base as? UINavigationController {
            return getTopMostViewController(base: nav.visibleViewController)
        }
        if let tab = base as? UITabBarController {
            if let selected = tab.selectedViewController {
                return getTopMostViewController(base: selected)
            }
        }
        if let presented = base?.presentedViewController {
            return getTopMostViewController(base: presented)
        }
        return base
    }
    
    /// 获取栈顶控制器
    public class func currentViewController() -> UIViewController {
        let delegate = UIApplication.shared.delegate
        let vc = delegate?.window??.rootViewController
        return UIViewController.findBestViewController(vc: vc!)
    }
    
    public class func getMainWindow() -> UIWindow? {
        let delegate = UIApplication.shared.delegate
        if let w =  delegate?.window {return w}
        let arr = UIApplication.shared.windows
        if arr.count == 1 {
            return arr.first
        } else {
            for w in arr {
                if w.windowLevel == .normal {
                    return w
                }
            }
        }
        return nil
    }
    
    /// 获取当前控制器的类名
    class func getCurrentViewControllerClassName() -> String? {
        return type(of: UIViewController.currentViewController()).description().components(separatedBy: ".")[1]
    }
    private class func findBestViewController(vc : UIViewController) -> UIViewController {
        
        if vc.presentedViewController != nil {
            return UIViewController.findBestViewController(vc: vc.presentedViewController!)
        } else if vc.isKind(of:UISplitViewController.self) {
            let svc = vc as! UISplitViewController
            if svc.viewControllers.count > 0 {
                return UIViewController.findBestViewController(vc: svc.viewControllers.last!)
            } else {
                return vc
            }
        } else if vc.isKind(of: UINavigationController.self) {
            let nvc = vc as! UINavigationController
            
            if nvc.viewControllers.count > 0 {
                return UIViewController.findBestViewController(vc: nvc.topViewController!)
            } else {
                return vc
            }
        } else if vc.isKind(of: UITabBarController.self) {
            let tvc = vc as! UITabBarController
            if (tvc.viewControllers?.count)! > 0 {
                return UIViewController.findBestViewController(vc: tvc.selectedViewController!)
            } else {
                return vc
            }
        } else {
            return vc
        }
    }
    
}

