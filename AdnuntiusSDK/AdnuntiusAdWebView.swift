//
//  Copyright (c) 2020 Adnuntius AS.  All rights reserved.
//

import WebKit

@objc public protocol AdnSdkHandler {
    /*
     Used for close view from layout
     https://github.com/Adnuntius/ios_sdk/wiki/Adnuntius-Advertising#close-view-from-layout
     */
    func onClose(_ view: AdnuntiusAdWebView)
}

@objc public protocol AdLoadCompletionHandler {
    /*
     if this is called, it means no ads were matched
    */
    func onNoAdResponse(_ view: AdnuntiusAdWebView)
    
    /*
     if adnuntius delivery returns a non 200 status, or there is no target div
     or adn.js reports any other issue, this will be called
    */
    func onFailure(_ view: AdnuntiusAdWebView, _ message: String)

    /*
     Will return the size in pixels of each ad loaded
     this will not be called if there is no ad rendered (should be obvious)
    */
    func onAdResponse(_ view: AdnuntiusAdWebView, _ width: Int, _ height: Int)
}

public struct AdResponseInfo {
    public var definedWidth: Int = 0
    public var definedHeight: Int = 0
    public var width: Int = 0
    public var height: Int = 0
    public var creativeId: String = ""
    public var lineItemId: String = ""
}

public protocol LoadAdHandler {
    /*
     No ads was returned
     */
    func onNoAdResponse()
   
    /*
     If adnuntius ad server returns a non 200 status, or there is no target div
     or adn.js reports any other issue
    */
    func onFailure(_ message: String)
    
    /*
     This will not be called if there is no ad rendered (should be obvious)
    */
    func onAdResponse(_ response: AdResponseInfo)
    
    /*
     Pass through the onRestyle event from adn.js, this is currently
     enabled experimentally and for debugging purposes only
     */
    func onAdResize(_ response: AdResponseInfo)
    
    /*
     Used for close view from layout
     https://github.com/Adnuntius/ios_sdk/wiki/Adnuntius-Advertising#close-view-from-layout
     */
    func onLayoutCloseView()
}

public extension LoadAdHandler {
    func onLayoutCloseView() {
        // do nothing
    }
    
    func onFailure(_ message: String) {
        // do nothing
    }
    
    func onNoAdResponse() {
        // do nothing
    }
    
    func onAdResponse(_ response: AdResponseInfo) {
        // do nothing
    }
    
    func onAdResize(_ response: AdResponseInfo) {
        // do nothing
    }
}

private class HandlerAdaptor: LoadAdHandler {
    private let webView: AdnuntiusAdWebView?
    var adnAdLoadHandler: AdLoadCompletionHandler?
    var adnSdkHandler: AdnSdkHandler?
    
    public init(_ webview: AdnuntiusAdWebView) {
        self.webView = webview
    }
    
    func onLayoutCloseView() {
        if adnSdkHandler != nil {
            adnSdkHandler!.onClose(self.webView!)
        }
    }
    
    func onFailure(_ message: String) {
        if adnAdLoadHandler != nil {
            adnAdLoadHandler!.onFailure(self.webView!, message)
        }
    }
    
    func onNoAdResponse() {
        if adnAdLoadHandler != nil {
            adnAdLoadHandler!.onNoAdResponse(self.webView!)
        }
    }
    
    func onAdResponse(_ response: AdResponseInfo) {
        if adnAdLoadHandler != nil {
            adnAdLoadHandler!.onAdResponse(self.webView!, response.definedWidth, response.definedHeight)
        }
    }
}

public class AdnuntiusAdWebView: WKWebView, WKUIDelegate, WKNavigationDelegate, WKScriptMessageHandler {
    private let logger: Logger = Logger()
    
    private var loadAdHandler: LoadAdHandler?
    
    // for objective c and legacy apps a handler adaptor we will only create when first used
    private var handlerAdaptor: HandlerAdaptor?
    
    private var env : AdnuntiusEnvironment = AdnuntiusEnvironment.production
    
    public override init(frame: CGRect, configuration: WKWebViewConfiguration) {
        super.init(frame: frame, configuration: AdnuntiusAdWebView.allowsInlineMediaPlayback(configuration))
    }

    private static func allowsInlineMediaPlayback(_ configuration: WKWebViewConfiguration) -> WKWebViewConfiguration {
        configuration.allowsInlineMediaPlayback = true
        return configuration
    }

    public required init?(coder: NSCoder) {
        super.init(coder: coder)
    }
    
    @objc open func adView () -> AdnuntiusAdWebView {
        return self
    }

    /*
    internal adnuntius dev use only
    */
    open func setEnv(_ env: AdnuntiusEnvironment) {
        self.env = env
    }
    
    @objc open func enableDebug(_ debug: Bool) {
        self.logger.enableDebug(debug)
    }
    
    private func setupCallbacks(_ loadAdHandler: LoadAdHandler) {
        // we only want to do this once
        if self.loadAdHandler == nil {
            let metaScript = WKUserScript(source: AdUtils.META_VIEWPORT_JS,
                                                injectionTime: WKUserScriptInjectionTime.atDocumentEnd, forMainFrameOnly: true)

            let shimScript = WKUserScript(source: AdUtils.getAdnuntiusAjaxShimJs(self.logger.isDebugEnabled()),
                                        injectionTime: WKUserScriptInjectionTime.atDocumentStart, forMainFrameOnly: true)

            self.configuration.userContentController.addUserScript(metaScript)
            self.configuration.userContentController.addUserScript(shimScript)
            self.configuration.userContentController.add(self, name: AdUtils.INTERNAL_ADNUNTIUS_MESSAGE_HANDLER)
            self.configuration.userContentController.add(self, name: AdUtils.ADNUNTIUS_MESSAGE_HANDLER)
        }
        
        self.loadAdHandler = loadAdHandler

        self.navigationDelegate = self
        self.uiDelegate = self
    }

    /*
     Return false if the initial validation of the config parameter fails, otherwise all other signals will be via
     the completion handler
     */
    @available(*, deprecated, message: "Use loadAd(AdRequest, LoadAdHandler) instead")
    open func loadAd(_ config: [String: Any], completionHandler: AdLoadCompletionHandler) -> Bool {
        guard let requestConfig = AdUtils.parseConfig(config, self.logger) else {
            return false
        }
        return loadAd(requestConfig, completionHandler: completionHandler)
    }

    /*
     The return state can be ignored it will always be true.   Was accidentally left in the method signature when migrating from the
     previous loadAd method.
     */
    @objc open func loadAd(_ config: AdRequest, completionHandler: AdLoadCompletionHandler? = nil, adnSdkHandler: AdnSdkHandler? = nil) -> Bool {
        if self.handlerAdaptor == nil {
            self.handlerAdaptor = HandlerAdaptor(self)
        }
        self.handlerAdaptor!.adnAdLoadHandler = completionHandler
        self.handlerAdaptor!.adnSdkHandler = adnSdkHandler
        setupCallbacks(self.handlerAdaptor!)
        
        let request = AdUtils.toJson(config, self.env)
        self.loadHTMLString(request.script, baseURL: request.baseUrl)
        return true
    }
    
    /*
     Swift Only implementation which relies on default implementations of methods in the LoadAdHandler for extensibility
     */
    open func loadAd(_ config: AdRequest, _ loadAdHandler: LoadAdHandler) -> Void {
        setupCallbacks(loadAdHandler)
        let request = AdUtils.toJson(config, self.env)
        self.loadHTMLString(request.script, baseURL: request.baseUrl)
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
        self.loadAdHandler!.onFailure("Failed loading: \(error as NSError?)")
    }
    
    open func userContentController(_ userContentController: WKUserContentController,
                                   didReceive wkmessage: WKScriptMessage) {
        if let dict = wkmessage.body as? [String : AnyObject] {
            if let type = dict["type"] as? String {
                if type == "console" {
                    if let method = dict["method"] as? String, let message = dict["message"] as? String {
                        self.logger.debug("\(method): \(message)")
                    }
                } else if (type == "pageLoad") {
                    if let adCount = dict["adCount"] as? Int {
                        if (adCount > 0) {
                            let response: AdResponseInfo = newAdResponseInfo(dict)
                            self.loadAdHandler!.onAdResponse(response)
                        } else {
                            self.loadAdHandler!.onNoAdResponse()
                        }
                    }
                } else if (type == "resize") {
                    let response: AdResponseInfo = newAdResponseInfo(dict)
                    if response.width > 0 && response.height > 0 {
                        self.loadAdHandler!.onAdResize(response)
                    }
                } else if (type == "failure") {
                    if let httpStatus = dict["status"] as? Int, let response = dict["response"] as? String {
                        self.loadAdHandler!.onFailure("\(httpStatus) error: \(response)")
                    }
                } else if (type == "closeView") {
                    self.loadAdHandler!.onLayoutCloseView()
                }
            }
        }
    }
    
    // FIXME - perhaps there is an automated way to populate the AdResponseInfo from the dict
    private func newAdResponseInfo(_ dict: [String : AnyObject]) -> AdResponseInfo {
        var adResponseInfo = AdResponseInfo()
        if let definedWidth = dict["definedWidth"] as? Int,
                    let definedHeight = dict["definedHeight"] as? Int,
                    let height = dict["height"] as? Int,
                    let width = dict["width"] as? Int,
                    let creativeId = dict["creativeId"] as? String,
                    let lineItemId = dict["lineItemId"] as? String {
            adResponseInfo.width = width
            adResponseInfo.height = height
            adResponseInfo.definedWidth = definedWidth
            adResponseInfo.definedHeight = definedHeight
            adResponseInfo.creativeId = creativeId
            adResponseInfo.lineItemId = lineItemId
        }
        return adResponseInfo
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
        
    private func doClick(_ url: URL) {
        if #available(iOS 10.0, *) {
            UIApplication.shared.open(url)
        } else {
            UIApplication.shared.openURL(url)
        }
    }
}
