//
//  VRRequestManager.swift
//  VRCapture_iOS
//
//  Created by wzb on 2023/5/9.
//

import UIKit

internal class VRDataSerialization {
    ///
    /// - Parameters:
    ///   - result: Data response result.
    public static func convertToNullableModel<T: VRMappable>(
        responseResult result: Any?) -> T? {
        guard result != nil else { return nil }
            let m = toModelObject(result, to: T.self)
            return m
    }
    
    /// Handle Json Array.
    ///
    /// - Parameters:
    ///   - result: Data response result.
    public static func convertToNullableModelArray<T: VRMappable>(responseResult result: Any?) -> [T]? {
        guard result != nil else { return nil }
        
        var resultArr = [T]()
        if let array = result as? [[String : Any]] {
            for obj in array {
                if let m = toModelObject(obj, to: T.self) {
                    resultArr.append(m)
                }
            }
            return resultArr
        }
        return nil
    }
    
    /// If result is nil. Will call failure callback
    ///
    /// - Parameters:
    ///   - result: Data response result.
    ///   - success: Success callback.
    ///   - failure: Failure callback.
    public static func convertToNonnullModel<T: VRMappable>(
        responseResult result: Any?,
        success: (T) -> Void,
        failure: (VRDataError) -> Void) {
        if let m = toModelObject(result, to: T.self) {
            success(m)
        } else {
            failure(.unknown)
        }
    }
    
    public static func converToJson<T: VRMappable>(from model: T?) -> Any? {
        guard model != nil else { return nil }
        let json = modelToJson(model)
        return json
    }
    
    public static func converToJson<T: VRMappable>(from list: [T]?) -> Any? {
        guard let list = list else { return nil }
        var resultArr = [Any]()
        for sub in list {
            if let json = modelToJson(sub) {
                resultArr.append(json)
            }
        }
        return resultArr
    }
    
    /// 字典转模型
    public static func toModelObject<T>(_ dictionary: Any?, to type: T.Type) -> T? where T: VRMappable {
        
        guard let dictionary = dictionary else {
            printLog("❌ 传入的数据解包失败!")
            return nil
        }
        
        if !JSONSerialization.isValidJSONObject(dictionary) {
            printLog("❌ 不是合法的json对象!")
            return nil
        }
        
        guard let data = try? JSONSerialization.data(withJSONObject: dictionary, options: []) else {
            printLog("❌ JSONSerialization序列化失败!")
            return nil
        }
        
        do {
            let decoder = JSONDecoder()
            decoder.keyDecodingStrategy = .convertFromSnakeCase
            let model = try decoder.decode(type, from: data)
            modelMapFinsh(model: model, dictionary: dictionary as? [String: Any])
            return model
        } catch {
            printLog(error)
            printLog("❌ JSONDecoder字典转模型失败!")
            return nil
        }
    }
}

extension VRDataSerialization {
    
    static private func modelMapFinsh(model: VRMappable, dictionary: [String: Any]?) {
        model.didConvertToObjectWithKeyValues(dictionary: dictionary)
        model.mapToJson(data: dictionary)
        let mirro = Mirror(reflecting: model)
        for child in mirro.children {
            if let subModel = (child.value as? AnyObject) as? VRMappable{
                let dic = dictionary?[child.label ?? ""] as? [String: Any]
                modelMapFinsh(model: subModel, dictionary: dic)
            } else if let arr = child.value as? [VRMappable] {
                arr.forEach { subModel in
                    modelMapFinsh(model: subModel, dictionary: subModel.toDictionary())
                }
            }
        }
    }
    

    public static func modelToJson<T>(_ encodable: T?) -> Any? where T: Encodable {
        guard let encodable = encodable else {
            print("❌ 传入的数据为空!")
            return nil
        }
        
        let encoder = JSONEncoder()
        encoder.keyEncodingStrategy = .convertToSnakeCase
        
        guard let data = try? encoder.encode(encodable) else {
            print("❌ 传入的数据Encode失败!")
            return nil
        }
        
        guard let result = dataToJSON(data: data) else {
            print("❌ JSONSerialization转JSON失败!")
            return nil
        }
        return result
    }
    
    static func dataToJSON(data: Data) -> AnyObject? {
        do {
            return try JSONSerialization.jsonObject(with: data as Data, options: .mutableContainers) as AnyObject
        } catch {
            print(error)
        }
        return nil
    }
    
}
