//
//  AdUtils.swift
//  AdnuntiusSDK
//
//  Created by Jason Pell on 23/5/2022.
//  Copyright © 2022 Adnuntius AS. All rights reserved.
//

import Foundation

public struct InternalAdRequest {
    public let script: String
    public let baseUrl: URL
    
    public init(_ script: String, _ baseUrl: String) {
        self.script = script
        self.baseUrl = URL(string: baseUrl)!
    }
}

/**
 only ever used internally so not exposed to objective-c
 */
public class LivePreviewConfig {
    public let lpl: String
    public let lpc: String
    
    public init(_ lpl: String, _ lpc: String) {
        self.lpl = lpl
        self.lpc = lpc
    }
}

@objc public class AdRequest: NSObject {
    public let auId: String
    public var auH: String?
    public var auW: String?
    public var kv: [String: [String]]?
    public var c: [String]?
    public var userId: String?
    public var useCookies: Bool?
    public var sessionId: String?
    public var consentString: String?
    public var globalParameters: [String: String]?
    public var livePreview: LivePreviewConfig?
    
    @objc public init(_ auId: String) {
        self.auId = auId
    }

    @objc public func userId(_ userId: String) {
        self.userId = userId
    }
    
    @objc public func sessionId(_ sessionId: String) {
        self.sessionId = sessionId
    }
    
    @objc public func consentString(_ consentString: String) {
        self.consentString = consentString
    }
    
    @objc public func useCookies(_ useCookies: Bool) {
        self.useCookies = useCookies
    }
    
    @objc public func width(_ auW: String) {
        self.auW = auW
    }
    
    @objc public func height(_ auH: String) {
        self.auH = auH
    }
    
    @objc public func category(_ category: String) {
        if self.c == nil {
            self.c = [category]
        } else {
            self.c!.append(category)
        }
    }
        
    @objc public func keyValue(_ key: String, _ value: String) {
        if self.kv == nil {
            self.kv = [:]
        }
        
        if self.kv![key] != nil {
            self.kv![key]!.append(value)
        } else {
            self.kv![key] = [value]
        }
    }
    
    @objc public func globalParameter(_ key: String, _ value: String) {
        if self.globalParameters == nil {
            self.globalParameters = [:]
        }
        self.globalParameters![key] = value
    }
    
    @objc public func livePreview(_ lineItemId: String, _ creativeId : String) {
        self.livePreview = LivePreviewConfig(lineItemId, creativeId)
    }
}

public class AdUtils {
    public static var INTERNAL_ADNUNTIUS_MESSAGE_HANDLER = "intAdnuntiusMessageHandler"
    public static var ADNUNTIUS_MESSAGE_HANDLER = "adnuntiusMessageHandler"

    // https://stackoverflow.com/questions/26295277/wkwebview-equivalent-for-uiwebviews-scalespagetofit
    public static var META_VIEWPORT_JS = """
    var viewportMetaTag = document.querySelector('meta[name="viewport"]');
    var viewportMetaTagIsUsed = viewportMetaTag && viewportMetaTag.hasAttribute('content');
    if (!viewportMetaTagIsUsed) {
        var meta = document.createElement('meta');
        meta.setAttribute('name', 'viewport');
        meta.setAttribute('content', 'initial-scale=1.0');
        document.getElementsByTagName('head')[0].appendChild(meta);
    }
    """

    public static var ADNUNTIUS_AJAX_SHIM_JS = """
    var adnSdkHandler = Object()
    adnSdkHandler.closeView = function() {
        if (window.webkit && window.webkit.messageHandlers && window.webkit.messageHandlers.\(ADNUNTIUS_MESSAGE_HANDLER)) {
              window.webkit.messageHandlers.\(ADNUNTIUS_MESSAGE_HANDLER).postMessage({type: "closeView"})
        }
    }
    
    var adnSdkShim = new Object()
    adnSdkShim.console = window.console;

    adnSdkShim.adnAdnuntiusMessage = function(message) {
        if (window.webkit && window.webkit.messageHandlers && window.webkit.messageHandlers.\(INTERNAL_ADNUNTIUS_MESSAGE_HANDLER)) {
              window.webkit.messageHandlers.\(INTERNAL_ADNUNTIUS_MESSAGE_HANDLER).postMessage(message)
        }
    }

    // we direct the window.console to the app, but also we still
    // send it to the console log in the browser
    adnSdkShim.handleConsole = function(method, args) {
        var message = Array.prototype.slice.apply(args).join(' ')
        adnSdkShim.adnAdnuntiusMessage({
                              type: "console",
                              method: method,
                              message: message
        })
        adnSdkShim.console[method](message)
    }

    window.console = {
        log: function() {
            adnSdkShim.handleConsole('log', arguments)
        }
        , warn: function() {
            adnSdkShim.handleConsole('warn', arguments)
        }
        , error: function() {
            adnSdkShim.handleConsole('error', arguments)
        }
    }

    adnSdkShim.onDimsEvent = function(type, response) {
        if (response.hasOwnProperty('ads') && response.ads[0]) {
            var ad = response.ads[0]
            
            if (ad.hasOwnProperty('dims') && ad.hasOwnProperty('definedDims')) {
                adnSdkShim.adnAdnuntiusMessage({
                    type: type,
                    id: response.auId || "",
                    target: response.targetId || "",
                    adCount: response.retAdCount || 0,
                    width: ad.dims.w || 0,
                    height: ad.dims.h || 0,
                    definedWidth: ad.definedDims.w || 0,
                    definedHeight: ad.definedDims.h || 0,
                    creativeId: ad.creativeId || "",
                    lineItemId: ad.lineItemId || ""
                })
            }
        }
    }
    
    adnSdkShim.onPageLoad = function(response) {
        //console.log("onPageLoad:" + JSON.stringify(response))
        adnSdkShim.onDimsEvent("pageLoad", response)
    }

    adnSdkShim.onRestyle = function(response) {
        //console.log("onResize:" + JSON.stringify(response))
        adnSdkShim.onDimsEvent("resize", response)
    }
    
    adnSdkShim.onVisible = function(response) {
        //console.log("onVisible:" + JSON.stringify(response))
    }

    adnSdkShim.onViewable = function(response) {
        //console.log("onViewable:" + JSON.stringify(response))
    }

    adnSdkShim.onImpressionResponse = function(response) {
        //console.log("onImpressionResponse:" + JSON.stringify(response))
    }

    adnSdkShim.onError = function(response) {
        console.log("onError:" + JSON.stringify(response))
    
        if (response.hasOwnProperty('args') && response.args[0]) {
            var object = response.args[0]
            if ('response' in object && 'status' in object) {
                adnSdkShim.adnAdnuntiusMessage({
                    type: "failure",
                    status: object.status,
                    response: object.response
                })
            }
        }
    }

    """

    public static func getBaseUrl(_ env: AdnuntiusEnvironment) -> String {
        if (env == AdnuntiusEnvironment.production) {
            return "https://delivery.adnuntius.com"
        } else if (env == AdnuntiusEnvironment.localhost) {
            return "http://localhost:8078"
        } else {
            return "https://adserver.\(env).delivery.adnuntius.com"
        }
    }

    public static func parseConfig(_ config: [String: Any], _ logger: Logger) -> AdRequest? {
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

        let kv = adUnit["kv"] as? [[String : Any]]
        if kv != nil {
            logger.error("Malformed request: kv cannot be an array")
            return nil
        }

        let request = AdRequest(auId)
        
        if let kvs = adUnit["kv"] as? [String: [String]] {
            request.kv = kvs
        } else if let kvs = adUnit["kv"] as? [String: String] {
            for key in kvs.keys.sorted() {
                request.keyValue(key, kvs[key]!)
            }
        }
        
        if let c = adUnit["c"] as? [String] {
            request.c = c
        }
        
        if let c = adUnit["c"] as? String {
            request.c = [c]
        }
        
        if let auH = adUnit["auH"] as? String {
            request.auH = auH
        }
        
        if let auH = adUnit["auW"] as? String {
            request.auH = auH
        }
        localConfig["adUnits"] = nil
        
        // FIXME - apparently can do live preview without specifying the creative id!!!
        if let lpl = localConfig["lpl"] as? String, let lpc = localConfig["lpc"] as? String {
            request.livePreview(lpl, lpc)
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
        request.useCookies = useCookies

        if let userId = localConfig["userId"] as? String {
            request.userId = userId
            localConfig["userId"] = nil
        }
        
        if let sessionId = localConfig["sessionId"] as? String {
            request.sessionId = sessionId
            localConfig["sessionId"] = nil
        }
        
        if let consentString = localConfig["consentString"] as? String {
            request.consentString = consentString
            localConfig["consentString"] = nil
        }

        let keys = localConfig.keys.sorted()
        for key in keys {
            request.globalParameter(key, localConfig[key] as! String)
        }
        return request
    }
    
    public static func toJson(_ config: AdRequest, _ env: AdnuntiusEnvironment) -> InternalAdRequest {
        var rootParametersJson = ""
        if let userId = config.userId {
            appendWithComma(&rootParametersJson, "userId", "'\(userId)'")
        }
        if let sessionId = config.sessionId {
            appendWithComma(&rootParametersJson, "sessionId", "'\(sessionId)'")
        }
        if let useCookies = config.useCookies {
            appendWithComma(&rootParametersJson, "useCookies", "\(useCookies)")
        }
        if let consentString = config.consentString {
            appendWithComma(&rootParametersJson, "consentString", "'\(consentString)'")
        }
        
        if let globalParameters = config.globalParameters {
            let keys = globalParameters.keys.sorted()
            for key in keys {
                appendWithComma(&rootParametersJson, key, "'\(globalParameters[key]!)'")
            }
        }
        
        var kvs = ""
        if let kv = config.kv {
            let keys = kv.keys.sorted()
            for key in keys {
                if let values = kv[key] {
                    var kvalue = ""
                    for value in values {
                        appendWithComma(&kvalue, "'\(value)'")
                    }
                    appendWithComma(&kvs, key, "[" + kvalue + "]", true)
                    
                }
            }
        }
        
        var categories = ""
        if let c = config.c {
            for value in c {
                appendWithComma(&categories, "'\(value)'")
            }
        }
        
        var adUnitJson = ""
        appendWithComma(&adUnitJson, "auId", "'\(config.auId)'")
        if let auH = config.auH {
            appendWithComma(&adUnitJson, "auH", "'\(auH)'")
        }
        if let auW = config.auW {
            appendWithComma(&adUnitJson, "auW", "'\(auW)'")
        }
        
        if kvs != "" {
            appendWithComma(&adUnitJson, "kv", "{\(kvs)}")
        }
        
        if categories != "" {
            appendWithComma(&adUnitJson, "c", "[\(categories)]")
        }

        let adnJsUrl = self.getAdnJsUrl(env)
        
        // we are overriding these default css settings cos wkwebview does not seem to provide
        // a UI that can do it, and ive tried many
        let script = """
        <html>
           <head>
            <script type="text/javascript" src="\(adnJsUrl)" async></script>
            <style>
            body {
                margin-top: 0px;
                margin-left: 0px;
                margin-bottom: 0px;
                margin-right: 0px;
            }
            </style>
           </head>
           <body>
                <div id="adn-\(config.auId)" style="display:none"></div>
                <script type="text/javascript">
                window.adn = window.adn || {}; adn.calls = adn.calls || [];
                adn.calls.push(function() {
                    adn.request({
                        env: '\(env)',
                        sdk: 'ios:\(AdnuntiusSDK.sdk_version)',
                        onPageLoad: adnSdkShim.onPageLoad,
                        onImpressionResponse: adnSdkShim.onImpressionResponse,
                        onVisible: adnSdkShim.onVisible,
                        onViewable: adnSdkShim.onViewable,
                        onRestyle: adnSdkShim.onRestyle,
                        onError: adnSdkShim.onError,
                        adUnits: [{\(adUnitJson)}],
                        \(rootParametersJson)
                    });
                });
                </script>
           </body>
        </html>
        """

        var baseUrl: String = getBaseUrl(env)
        if config.livePreview != nil {
            baseUrl.append("?adn-lp-li=" + config.livePreview!.lpl)
            if (config.livePreview?.lpc != nil) {
                baseUrl.append("&adn-lp-c=" + config.livePreview!.lpc)
            }
            // this hides the warning in the browser when using live preview
            baseUrl.append("&adn-hide-warning=true")
        }

        // for internal adnuntius use only - testing on localhost with local adn.src.js
        if (env == AdnuntiusEnvironment.localhost) {
            baseUrl.append("?script-override=localhost")
        }

        return InternalAdRequest(script, baseUrl)
    }

    private static func getAdnJsUrl(_ env: AdnuntiusEnvironment) -> String {
        if (env == AdnuntiusEnvironment.localhost) {
            return "http://localhost:8001/adn.src.js"
        } else {
            // currently all other envs use prod cdn
            return "https://cdn.adnuntius.com/adn.js"
        }
    }
    
    private static func appendWithComma(_ string: inout String, _ key: String, _ value: String, _ includeQuotes: Bool = false) {
        if !string.isEmpty {
            string.append(", ")
        }
        if includeQuotes {
            string.append("'\(key)': ")
        } else {
            string.append("\(key): ")
        }
        string.append("\(value)")
    }

    private static func appendWithComma(_ string: inout String, _ value: String) {
        if !string.isEmpty {
            string.append(", ")
        }
        string.append("\(value)")
    }
}
