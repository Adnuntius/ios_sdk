//
//  AdnuntiusSDK.swift
//  AdnuntiusSDK
//
//
//  Copyright (c) 2019 Adnuntius AS.  All rights reserved.
//

import UIKit

public protocol AdnuntiusSDKProtocol {
    func didCallPing()
    func setConfig(adId: String)
}

open class AdnuntiusSDK: NSObject {
    public static let sdk_version = "1.1.5"

    public static let shared = AdnuntiusSDK()
    public static var hasErrors = false
    public static var config: [String: Any] = Dictionary<String, Any>()
    public static var adScript: String = ""
    
    public var delegate:AdnuntiusSDKProtocol?
    
    open func Ping() {
        AdnuntiusSDK.shared.delegate?.didCallPing()
    }
}
