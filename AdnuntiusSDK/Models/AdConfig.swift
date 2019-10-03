//
//  AdConfig.swift
//  AdnuntiusSDK
//
//  Created by Adnuntius Australia on 3/10/19.
//  Copyright © 2019 Adnuntius AS. All rights reserved.
//
import Foundation

public class AdConfig: NSObject {
    var _hasErrors: Bool = false
    var _config: [String: Any] = [:]
    
    required init(_ config: [String: Any]) {
        self._config = config
    }
    
    public func getConfig() -> [String: Any] {
        return self._config
    }
    
    public func setHasErrors(_ v: Bool) {
        self._hasErrors = v
    }
    
    public func getHasErrors() -> Bool {
        return self._hasErrors
    }
}
