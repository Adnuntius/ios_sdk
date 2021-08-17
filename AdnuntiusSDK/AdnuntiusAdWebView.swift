//
//  Copyright (c) 2020 Adnuntius AS.  All rights reserved.
//

import WebKit

private struct LivePreviewConfig {
    let lpl: String
    let lpc: String
}

private struct AdRequestConfig {
    let auId: String
    let adUnitsJson: String
    let otherJson: String
    let lp: LivePreviewConfig?
}

// an optional protocol which can be used to respond to javascript calls
// on the new adnSdkHandler javascript object.   For this version we
// are adding support for closeWindow, later versions may add additional methods
@objc public protocol AdnSdkHandler {
    func onClose(_ view: AdnuntiusAdWebView)
}

@objc public protocol AdLoadCompletionHandler {
    // if this is called, it means no ads were matched
    func onNoAdResponse(_ view: AdnuntiusAdWebView)
    
    // if adnuntius delivery returns a non 200 status, or there is no target div
    // or adn.js reports any other issue, this will be called
    func onFailure(_ view: AdnuntiusAdWebView, _ message: String)

    // will return the size in pixels of each ad loaded
    // this will not be called if there is no ad rendered (should be obvious)
    func onAdResponse(_ view: AdnuntiusAdWebView, _ width: Int, _ height: Int)
}

public class AdnuntiusAdWebView: WKWebView, WKUIDelegate, WKNavigationDelegate, WKScriptMessageHandler {
    private var completionHandler: AdLoadCompletionHandler?
    private var adnSdkHandler: AdnSdkHandler?

    private static var INTERNAL_ADNUNTIUS_MESSAGE_HANDLER = "intAdnuntiusMessageHandler"
    private static var ADNUNTIUS_MESSAGE_HANDLER = "adnuntiusMessageHandler"
    private static var BASE_URL = "https://delivery.adnuntius.com/"

    // https://stackoverflow.com/questions/26295277/wkwebview-equivalent-for-uiwebviews-scalespagetofit
    private static var META_VIEWPORT_JS = """
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
    adnSdkShim.open = XMLHttpRequest.prototype.open
    adnSdkShim.send = XMLHttpRequest.prototype.send
    adnSdkShim.console = window.console;
    
    XMLHttpRequest.prototype.open = function(method, url, async, user, password) {
        url = url + "&sdk=ios:\(AdnuntiusSDK.sdk_version)"
        adnSdkShim.open.apply(this, arguments)
        adnSdkShim.url = method
        adnSdkShim.url = url
    }

    XMLHttpRequest.prototype.send = function(data) {
        var callback = this.onreadystatechange;
        this.onreadystatechange = function() {
            // good for debugging purposes to see what ajax stuff is being done
            if (this.readyState == 4) {
                adnSdkShim.adnAdnuntiusMessage({
                      type: "url",
                      url: adnSdkShim.url,
                      status: this.status,
                      statusText: this.statusText
                })
            }
            callback.apply(this, arguments)
        }
        adnSdkShim.send.apply(this, arguments)
    }

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
    
    adnSdkShim.onVisible = function(args) {
        //console.log("onVisible:" + JSON.stringify(args))
    }

    adnSdkShim.onRestyle = function(args) {
        //console.log("onRestyle:" + JSON.stringify(args))
    }
    
    adnSdkShim.onViewable = function(args) {
        //console.log("onViewable:" + JSON.stringify(args))
    }

    adnSdkShim.onPageLoad = function(args) {
        console.log("onPageLoad:" + JSON.stringify(args))

        var clientHeight = document.getElementById(args.targetId).clientHeight || 0
        var height = args.h || args.retAdsH || 0

        if (height == 0 || (clientHeight > 0 && height > clientHeight)) {
            height = clientHeight
        }
        
        var width = args.w || args.retAdsW || 0
        var clientWidth = document.getElementById(args.targetId).clientWidth || 0
        if (width == 0 || (clientWidth > 0 && height > clientWidth)) {
            width = clientWidth
        }

        adnSdkShim.adnAdnuntiusMessage({
                              type: "impression",
                              id: args.auId || "",
                              target: args.targetId || "",
                              adCount: args.retAdCount || 0,
                              height: height,
                              width: width
        })
    }

    adnSdkShim.onImpressionResponse = function(args) {
        //console.log("onImpressionResponse:" + JSON.stringify(args))
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
    """
    
    @objc open func adView () -> AdnuntiusAdWebView {
        return self
    }

    private func setupCallbacks(_ completionHandler: AdLoadCompletionHandler, adnSdkHandler: AdnSdkHandler? = nil) {
        self.completionHandler = completionHandler
        self.adnSdkHandler = adnSdkHandler

        self.navigationDelegate = self
        self.uiDelegate = self
        
        let metaScript = WKUserScript(source: AdnuntiusAdWebView.META_VIEWPORT_JS,
                                            injectionTime: WKUserScriptInjectionTime.atDocumentEnd, forMainFrameOnly: true)
                
        let shimScript = WKUserScript(source: AdnuntiusAdWebView.ADNUNTIUS_AJAX_SHIM_JS,
                                    injectionTime: WKUserScriptInjectionTime.atDocumentStart, forMainFrameOnly: true)
        
        self.configuration.userContentController.addUserScript(metaScript)
        self.configuration.userContentController.addUserScript(shimScript)
        self.configuration.userContentController.add(self, name: AdnuntiusAdWebView.INTERNAL_ADNUNTIUS_MESSAGE_HANDLER)
        self.configuration.userContentController.add(self, name: AdnuntiusAdWebView.ADNUNTIUS_MESSAGE_HANDLER)
    }

    @available(*, deprecated, message: "Use loadAd instead")
    @objc open func loadFromConfig(_ config: [String: Any], completionHandler: AdLoadCompletionHandler) -> Bool {
        return self.loadAd(config, completionHandler: completionHandler)
    }
    
    // from 1.5.0 onwards loadFromApi internally just calls loadAd, it does not use the format=json, but the
    // function is left here to make migration a little less painful
    @available(*, deprecated, message: "Use loadAd instead")
    @objc open func loadFromApi(_ config: [String: Any], completionHandler: AdLoadCompletionHandler) -> Bool {
        return self.loadAd(config, completionHandler: completionHandler)
    }
    
    /*
     Return false if the initial validation of the config parameter fails, otherwise all other signals will be via
     the completion handler
     */
    @objc open func loadAd(_ config: [String: Any], completionHandler: AdLoadCompletionHandler, adnSdkHandler: AdnSdkHandler? = nil) -> Bool {
        setupCallbacks(completionHandler, adnSdkHandler: adnSdkHandler)

        guard let jsonData = self.parseConfig(config) else {
            return false
        }

        // we are overriding these default css settings cos wkwebview does not seem to provide
        // a UI that can do it, and ive tried many
        let script = """
        <html>
           <head>
            <script type="text/javascript" src="https://cdn.adnuntius.com/adn.js" async></script>
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
                <div id="adn-\(jsonData.auId)" style="display:none"></div>
                <script type="text/javascript">
                window.adn = window.adn || {}; adn.calls = adn.calls || [];
                adn.calls.push(function() {
                    adn.request({
                        onPageLoad: adnSdkShim.onPageLoad,
                        onImpressionResponse: adnSdkShim.onImpressionResponse,
                        onVisible: adnSdkShim.onVisible,
                        onViewable: adnSdkShim.onViewable,
                        onRestyle: adnSdkShim.onRestyle,
                        adUnits: \(jsonData.adUnitsJson)
                        \(jsonData.otherJson)
                    });
                });
                </script>
           </body>
        </html>
        """
        
        Logger.debug("Html Request: " + script)
        
        var baseUrl: String = AdnuntiusAdWebView.BASE_URL
        if jsonData.lp != nil {
            baseUrl = AdnuntiusAdWebView.BASE_URL + "?adn-lp-li=" + jsonData.lp!.lpl + "&adn-lp-c=" + jsonData.lp!.lpc
        }
        self.loadHTMLString(script, baseURL: URL(string: baseUrl))
        
        return true
    }
    
    private func parseConfig(_ config: [String: Any]) -> AdRequestConfig? {
        guard let adUnits = config["adUnits"] as? [[String : Any]] else {
            Logger.error("Malformed request: missing an adUnits section")
            return nil
        }
        
        guard adUnits.count == 1 else {
            Logger.error("Malformed request: Too many adUnits in adUnits section")
            return nil
        }

        let adUnit = adUnits.first!
        guard let auId = adUnit["auId"] as? String else {
            Logger.error("Malformed request: Missing an auId for the adUnit")
            return nil
        }

        guard let jsonData = try? JSONSerialization.data(withJSONObject: adUnits) else {
            Logger.error("Malformed request: Could not parse request")
            return nil
        }
        
        guard let adUnitsJsonText = String(data: jsonData, encoding: .utf8) else {
            Logger.error("Malformed request: Could not parse request")
            return nil
        }
        
        var lp: LivePreviewConfig? = nil
        if let lpl = config["lpl"] as? String, let lpc = config["lpc"] as? String {
            lp = LivePreviewConfig(lpl: lpl, lpc: lpc)
        }
        
        // support the adn.js noCookies parameter, as well as the ad server useCookies
        // to provide support for loadFromApi customers migrating over
        var otherJsonText = ""
        if let noCookies = config["noCookies"] {
            if noCookies as! Bool == true {
                otherJsonText = ", useCookies: false"
            }
        } else if let useCookies = config["useCookies"] {
            otherJsonText = ", useCookies: \(useCookies)"
        }
        Logger.debug("Json Request: " + adUnitsJsonText)
        Logger.debug("Other Request: " + otherJsonText)
        
        return AdRequestConfig(auId: auId, adUnitsJson: adUnitsJsonText, otherJson: otherJsonText, lp: lp)
    }

    // https://nemecek.be/blog/1/how-to-open-target_blank-links-in-wkwebview-in-ios
    open func webView(_ webView: WKWebView, createWebViewWith configuration: WKWebViewConfiguration,
                 for navigationAction: WKNavigationAction,
                 windowFeatures: WKWindowFeatures) -> WKWebView? {
        if let frame = navigationAction.targetFrame,
            frame.isMainFrame {
            return nil
        }
        webView.load(navigationAction.request)
        return nil
    }
    
    open func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        UIApplication.shared.isNetworkActivityIndicatorVisible = false
    }
    
    open func webView(_ webView: WKWebView, didStartProvisionalNavigation navigation: WKNavigation) {
        UIApplication.shared.isNetworkActivityIndicatorVisible = true
    }

    open func webView(_ webView: WKWebView,
                     didFailProvisionalNavigation navigation: WKNavigation!,
                     withError error: Error) {
        UIApplication.shared.isNetworkActivityIndicatorVisible = false
        self.doOnFailure("Failed loading: \(error as NSError?)")
    }
    
    open func userContentController(_ userContentController: WKUserContentController,
                                   didReceive wkmessage: WKScriptMessage) {
        guard let dict = wkmessage.body as? [String : AnyObject] else {
            return
        }

        let type = dict["type"] as! String
        if type == "console" {
            let method = dict["method"] as! String
            let message = dict["message"] as! String
            
            // this message is output currently by adn.js
            // TODO - come up with something better
            if message.contains("Unable to find HTML element") {
                self.doOnFailure(message)
            } else {
                Logger.debug("\(method): \(message)")
            }
        } else if (type == "impression") {
            let adCount = dict["adCount"] as! Int
            if adCount > 0 {
                let width = dict["width"] as! Int
                let height = dict["height"] as! Int
                self.doOnAdResponse(width, height)
            } else {
                self.doOnNoAdResponse()
            }
        } else if (type == "url") {
            let httpStatus = dict["status"] as! Int
            let requestUrl = dict["url"] as! String
            
            if httpStatus != 200 {
                let statusText = dict["statusText"] as! String
                self.doOnFailure("\(httpStatus.description) [\(statusText)] error returned for \(requestUrl)")
            } else {
                Logger.debug("Url Request: \(requestUrl)")
            }
        } else if (type == "closeView") {
            if (self.adnSdkHandler != nil) {
                self.adnSdkHandler?.onClose(self)
            }
        }
    }

    open func webView(_ webView: WKWebView,
                     decidePolicyFor navigationAction: WKNavigationAction,
                     decisionHandler: @escaping (WKNavigationActionPolicy) -> Void) {
        let url = navigationAction.request.url!
        let navigationType = navigationAction.navigationType
        let urlAbsoluteString = url.absoluteString

        if urlAbsoluteString == "about:blank"
            || urlAbsoluteString == "about:srcdoc"
            || urlAbsoluteString == AdnuntiusAdWebView.BASE_URL
            || urlAbsoluteString.contains(AdnuntiusAdWebView.BASE_URL + "?") { // allows for query parameters added to the base url, like for live preview
            decisionHandler(.allow)
            return
        }
        
        if (navigationType == .linkActivated) {
            Logger.debug("Normal Click Url: " + urlAbsoluteString)
            doClick(url)
            decisionHandler(.cancel)
            return
        } else {
            decisionHandler(.allow)
            return
        }
    }
    
    private func doOnNoAdResponse() {
        if (self.completionHandler != nil) {
            self.completionHandler?.onNoAdResponse(self)
        }
    }
    
    private func doOnFailure(_ message: String) {
        Logger.debug(message)
        if (self.completionHandler != nil) {
            self.completionHandler?.onFailure(self, message)
        }
    }
    
    private func doOnAdResponse(_ width: Int, _ height: Int) {
        if (self.completionHandler != nil) {
            if (width == 0) {
                let frameWidth = Int(self.frame.width)
                Logger.debug("Ad Response: frameWidth=\(frameWidth), heigth=\(height)")
                self.completionHandler?.onAdResponse(self, frameWidth, height)
            } else {
                Logger.debug("Ad Response: width=\(width), heigth=\(height)")
                self.completionHandler?.onAdResponse(self, width, height)
            }
        }
    }
    
    private func doClick(_ url: URL) {
        if #available(iOS 10.0, *) {
            UIApplication.shared.open(url)
        } else {
            UIApplication.shared.openURL(url)
        }
    }
}
