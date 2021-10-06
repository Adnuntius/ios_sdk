//
//  RequestConfigParser.swift
//  AdnuntiusSDK
//
//  Created by Jason Pell on 6/10/21.
//  Copyright © 2021 Adnuntius AS. All rights reserved.
//

import Foundation


public struct LivePreviewConfig {
    public let lpl: String
    public let lpc: String
    
    public init(lpl: String, lpc: String) {
        self.lpl = lpl
        self.lpc = lpc
    }
}

public struct AdRequestConfig {
    public let auId: String
    public let adUnitsJson: String
    public let otherJson: String
    public let lp: LivePreviewConfig?
    
    public init(auId: String, adUnitsJson: String, otherJson: String, lp: LivePreviewConfig?) {
        self.auId = auId
        self.adUnitsJson = adUnitsJson
        self.otherJson = otherJson
        self.lp = lp
    }
}

public class RequestConfigParser {
    private let logger: Logger
    
    public init(_ logger: Logger) {
        self.logger = logger
    }
    
    open func parseConfig(_ config: [String: Any]) -> AdRequestConfig? {
        var localConfig = config
        
        guard let adUnits = localConfig["adUnits"] as? [[String : Any]] else {
            logger.error("Malformed request: missing an adUnits section")
            return nil
        }
        
        guard adUnits.count == 1 else {
            logger.error("Malformed request: Too many adUnits in adUnits section")
            return nil
        }

        let adUnit = adUnits.first!
        guard let auId = adUnit["auId"] as? String else {
            logger.error("Malformed request: Missing an auId for the adUnit")
            return nil
        }

        guard let jsonData = try? JSONSerialization.data(withJSONObject: adUnits) else {
            logger.error("Malformed request: Could not parse request")
            return nil
        }
        
        guard let adUnitsJsonText = String(data: jsonData, encoding: .utf8) else {
            logger.error("Malformed request: Could not parse request")
            return nil
        }
        localConfig["adUnits"] = nil
        
        var lp: LivePreviewConfig? = nil
        if let lpl = localConfig["lpl"] as? String, let lpc = localConfig["lpc"] as? String {
            lp = LivePreviewConfig(lpl: lpl, lpc: lpc)
        }
        localConfig["lpl"] = nil
        localConfig["lpc"] = nil
        
        // support the adn.js noCookies parameter, as well as the ad server useCookies
        // to provide support for loadFromApi customers migrating over
        var useCookies: Bool = true
        if let noCookies = localConfig["noCookies"] {
            if noCookies as! Bool == true {
                useCookies = false
            }
            localConfig["noCookies"] = nil
        } else if let cUseCookies = localConfig["useCookies"] {
            if cUseCookies as! Bool == false {
                useCookies = false
            }
            localConfig["useCookies"] = nil
        }

        var otherJsonText = ""
        let keys = localConfig.keys.sorted()
        for key in keys {
            if !otherJsonText.isEmpty {
                otherJsonText.append(",")
            }
            otherJsonText.append("\"\(key)\":\"\(localConfig[key]!)\"")
        }
        if useCookies == false {
            if !otherJsonText.isEmpty {
                otherJsonText.append(",")
            }
            otherJsonText.append("\"useCookies\":false")
        }
        return AdRequestConfig(auId: auId, adUnitsJson: adUnitsJsonText, otherJson: otherJsonText, lp: lp)
    }
}
