//
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

    private static var ADNUNTIUS_AJAX_SHIM_JS = """
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
    
    adnSdkShim.log = function(message) {
        adnSdkShim.adnAdnuntiusMessage({
                              type: "console",
                              method: "log",
                              message: message
        })
    }
    
    adnSdkShim.version = function(version) {
        adnSdkShim.adnAdnuntiusMessage({
                              type: "version",
                              version: version
        })
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
        //adnSdkShim.log("onPageLoad:" + JSON.stringify(response))

        adnSdkShim.onDimsEvent("pageLoad", response)
    }

    adnSdkShim.onRestyle = function(response) {
        //adnSdkShim.log("onResize:" + JSON.stringify(response))

        adnSdkShim.onDimsEvent("resize", response)
    }
    
    adnSdkShim.onVisible = function(response) {
        //adnSdkShim.log("onVisible:" + JSON.stringify(response))
    }

    adnSdkShim.onViewable = function(response) {
        //adnSdkShim.log("onViewable:" + JSON.stringify(response))
    }

    adnSdkShim.onImpressionResponse = function(response) {
        //adnSdkShim.log("onImpressionResponse:" + JSON.stringify(response))
    }

    adnSdkShim.onError = function(response) {
        //adnSdkShim.log("onError:" + JSON.stringify(response))
    
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

    public static func getAdnuntiusAjaxShimJs(_ debugEnabled: Bool) -> String {
        if debugEnabled {
            return ADNUNTIUS_AJAX_SHIM_JS.replacingOccurrences(of: "//adnSdkShim.log", with: "adnSdkShim.log")
        } else {
            return ADNUNTIUS_AJAX_SHIM_JS
        }
    }
    
    public static func getBaseUrl(_ env: AdnuntiusEnvironment) -> String {
        if (env == AdnuntiusEnvironment.production) {
            return "https://delivery.adnuntius.com"
        } else if (env == AdnuntiusEnvironment.localhost) {
            return "http://localhost:8078"
        } else {
            return "https://adserver.\(env).delivery.adnuntius.com"
        }
    }

    public static func toJson(_ adId: String?, _ config: AdRequest, _ env: AdnuntiusEnvironment, _ debugEnabled: Bool) -> InternalAdRequest {
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
        
        let impReg = adId != nil ? "'manual'" : "'default'"
        let externalId = adId != nil ? "'\(adId!)'" : "null"
        
        let versionDebug = debugEnabled ? "adnSdkShim.version(adn.version)" : "// no version"
        
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
                    \(versionDebug)
                    adn.request({
                        env: '\(env)',
                        impReg: \(impReg),
                        externalId: \(externalId),
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
