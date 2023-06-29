//
//  VRRequestManager.swift
//  VRCapture_iOS
//
//  Created by wzb on 2023/5/9.
//

import Foundation

enum VRResposeStatus: String {
    case success
    case failed
}

protocol VRMappable: Codable {
    func didConvertToObjectWithKeyValues(dictionary: [String: Any]?)
    func mapToJson(data: Any?)
    func toDictionary() -> [String: Any]?
}

extension VRMappable {
    func didConvertToObjectWithKeyValues(dictionary: [String: Any]?) {}
    func mapToJson(data: Any?) {}
    func toDictionary() -> [String: Any]? {
        do {
            let data = try JSONEncoder().encode(self)
            let jsonOjb = try JSONSerialization.jsonObject(with: data as Data, options: .mutableContainers) as AnyObject
            return jsonOjb as? [String: Any]
        } catch {
            return nil
        }
    }
}

extension KeyedDecodingContainer {

    func decodeIfPresent(_ type: Int.Type, forKey key: K) throws -> Int? {
        
        if let value = try? decode(type, forKey: key) {
            return value
        } else if let value = try? decode(Double.self, forKey: key) {
            return Int(value)
        } else if let value = try? decode(String.self, forKey: key) {
            return Int(value)
        }
        return nil
    }
    
    func decodeIfPresent(_ type: String.Type, forKey key: K) throws -> String? {
   
        if let value = try? decode(type, forKey: key) {
            return value
        } else if let value = try? decode(Double.self, forKey: key) {
            return String(value)
        } else if let value = try? decode(Int.self, forKey: key) {
            return String(value)
        }
        return nil
    }
    
    func decodeIfPresent(_ type: Double.Type, forKey key: K) throws -> Double? {
        
        if let value = try? decode(type, forKey: key) {
            return value
        } else if let value = try? decode(String.self, forKey: key) {
            return Double(value)
        } else if let value = try? decode(Int.self, forKey: key) {
            return Double(value)
        }
        return nil
    }
}
