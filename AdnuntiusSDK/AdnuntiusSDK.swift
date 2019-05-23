//
//  AdnuntiusSDK.swift
//  AdnuntiusSDK
//
//  Created by Mateusz Grzywa on 27/08/2018.
//  Copyright © 2018 Mateusz Grzywa. All rights reserved.
//

import UIKit

public protocol AdnuntiusSDKProtocol {
    func didCallPing()
    func setConfig(adId: String)
}

open class AdnuntiusSDK: NSObject {
    public static let shared = AdnuntiusSDK()
    public static var hasErrors = false
    public static var config: [String: Any] = Dictionary<String, Any>()
    public static var adScript: String = ""
    
    public var delegate:AdnuntiusSDKProtocol?
    
    open func Ping() {
        AdnuntiusSDK.shared.delegate?.didCallPing()
    }
}
