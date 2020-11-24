//
//  Copyright (c) 2020 Adnuntius AS.  All rights reserved.
//

import Foundation

@objcMembers
public class AdConfig: NSObject, Codable {
    private var siteId: String?
    private let auId: String
    private var auW: String?
    private var auH: String?
    private var c: [String]?
    private var kv: [String: [String]]?
    
    public init(_ auId: String) {
        self.auId = auId
    }
    
    public func toJson() -> String {
        do {
            let encoder = JSONEncoder()
            let data = try encoder.encode(self)
            let output = String(data: data, encoding: String.Encoding.utf8)!
            return output.replacingOccurrences(of: "\"", with: "'")
        } catch let error {
            print("error converting to json: \(error)")
            return String("")
        }
    }
    
    public func getAuId() -> String {
        return self.auId
    }
    
    public func setSiteId(_ v: String) {
        self.siteId = v
    }
    
    public func setHeight(_ v: String) {
        self.auH = v
    }
    
    public func setWidth(_ v: String) {
        self.auW = v
    }
    
    public func addKeyValue(_ key: String, _ value: String) {
        if (self.kv == nil) {
            let kv: [String: [String]] = [:]
            self.kv = kv
        }
        if var arr = self.kv![key] {
            arr.append(value)
            self.kv![key] = arr
        } else {
            self.kv![key] = [value]
        }
    }
    
    public func addCategory(_ category: String) {
        if (self.c == nil) {
            let c: [String] = []
            self.c = c
        }
        self.c!.append(category)
    }
}
