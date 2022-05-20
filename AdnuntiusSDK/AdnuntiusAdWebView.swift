//
//  Copyright (c) 2020 Adnuntius AS.  All rights reserved.
//

import WebKit

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
    private static var INTERNAL_ADNUNTIUS_MESSAGE_HANDLER = "intAdnuntiusMessageHandler"
    private static var ADNUNTIUS_MESSAGE_HANDLER = "adnuntiusMessageHandler"

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
    
    adnSdkShim.onVisible = function(args) {
        //console.log("onVisible:" + JSON.stringify(args))
    }

    adnSdkShim.onRestyle = function(args) {
        //console.log("onRestyle:" + JSON.stringify(args))
    }
    
    adnSdkShim.onViewable = function(args) {
        //console.log("onViewable:" + JSON.stringify(args))
    }

    adnSdkShim.onImpressionResponse = function(args) {
        //console.log("onImpressionResponse:" + JSON.stringify(args))
    }
    
    adnSdkShim.onPageLoad = function(args) {
        //console.log("onPageLoad:" + JSON.stringify(args))

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

    adnSdkShim.onError = function(args) {
        if (args.hasOwnProperty('args') && args['args'][0]) {
            var object = args['args'][0]
            if ('response' in object && 'status' in object) {
                adnSdkShim.adnAdnuntiusMessage({
                    type: "failure",
                    status: object['status'],
                    response: object['response']
                })
            }
        }
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
    
    private var completionHandler: AdLoadCompletionHandler?
    private var adnSdkHandler: AdnSdkHandler?
    private let logger: Logger = Logger()
    private let configParser: RequestConfigParser
    private let env : AdnuntiusEnvironment = AdnuntiusEnvironment.production;
    
    public override init(frame: CGRect, configuration: WKWebViewConfiguration) {
        self.configParser = RequestConfigParser(logger)
        super.init(frame: frame, configuration: configuration)
    }

    public required init?(coder: NSCoder) {
        self.configParser = RequestConfigParser(logger)
        super.init(coder: coder)
    }
    
    @objc open func adView () -> AdnuntiusAdWebView {
        return self
    }

    // not available for objectice-c for now
    open func setEnv(_ env: AdnuntiusEnvironment) {
        self.configParser.setEnv(env)
    }
    
    @objc open func enableDebug(_ debug: Bool) {
        self.logger.enableDebug(debug)
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

    /*
     Return false if the initial validation of the config parameter fails, otherwise all other signals will be via
     the completion handler
     */
    @available(*, deprecated, message: "Use loadAd instead")
    @objc open func loadFromConfig(_ config: [String: Any], completionHandler: AdLoadCompletionHandler, adnSdkHandler: AdnSdkHandler? = nil) -> Bool {
        return loadAd(config, completionHandler: completionHandler, adnSdkHandler: adnSdkHandler)
    }

    @available(*, deprecated, message: "Use loadAd(AdRequest) instead")
    open func loadAd(_ config: [String: Any], completionHandler: AdLoadCompletionHandler, adnSdkHandler: AdnSdkHandler? = nil) -> Bool {
        guard let requestConfig = self.configParser.parseConfig(config) else {
            return false
        }
        return loadAd(requestConfig, completionHandler: completionHandler, adnSdkHandler: adnSdkHandler)
    }
    
    /*
     Return false if the initial validation of the config parameter fails, otherwise all other signals will be via
     the completion handler
     */
    @objc open func loadAd(_ config: AdRequest, completionHandler: AdLoadCompletionHandler, adnSdkHandler: AdnSdkHandler? = nil) -> Bool {
        setupCallbacks(completionHandler, adnSdkHandler: adnSdkHandler)
        let request = self.configParser.toJson(config)
        
        self.loadHTMLString(request.script, baseURL: URL(string: request.baseUrl))
        
        return true
    }
    
    // https://nemecek.be/blog/1/how-to-open-target_blank-links-in-wkwebview-in-ios
    open func webView(_ webView: WKWebView, createWebViewWith configuration: WKWebViewConfiguration,
                 for navigationAction: WKNavigationAction,
                 windowFeatures: WKWindowFeatures) -> WKWebView? {
        
        if let frame = navigationAction.targetFrame,
            frame.isMainFrame {
            self.logger.debug("Open Link in same window")
            return nil
        }
        
        let url = navigationAction.request.url!
        self.logger.debug("Open link in new window")
        doClick(url)
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
            self.logger.debug("\(method): \(message)")
        } else if (type == "impression") {
            let adCount = dict["adCount"] as! Int
            if adCount > 0 {
                let width = dict["width"] as! Int
                let height = dict["height"] as! Int
                self.doOnAdResponse(width, height)
            } else {
                self.doOnNoAdResponse()
            }
        } else if (type == "failure") {
            let httpStatus = dict["status"] as! Int
            let response = dict["response"] as! String
            self.doOnFailure("\(httpStatus) error: \(response)")
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

        let baseUrl = AdUtils.getBaseUrl(env)
        if urlAbsoluteString == "about:blank"
            || urlAbsoluteString == "about:srcdoc"
            || urlAbsoluteString == baseUrl
            || urlAbsoluteString.contains(baseUrl + "?") { // allows for query parameters added to the base url, like for live preview
            decisionHandler(.allow)
            return
        }
        
        if (navigationType == .linkActivated) {
            self.logger.debug("Normal Click Url: \(urlAbsoluteString)")
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
        self.logger.debug(message)
        if (self.completionHandler != nil) {
            self.completionHandler?.onFailure(self, message)
        }
    }
    
    private func doOnAdResponse(_ width: Int, _ height: Int) {
        if (self.completionHandler != nil) {
            if (width == 0) {
                let frameWidth = Int(self.frame.width)
                self.logger.debug("Ad Response: frameWidth=\(frameWidth), heigth=\(height)")
                self.completionHandler?.onAdResponse(self, frameWidth, height)
            } else {
                self.logger.debug("Ad Response: width=\(width), heigth=\(height)")
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
