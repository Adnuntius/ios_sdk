//
//  Copyright (c) 2022 Adnuntius AS.  All rights reserved.
//

import WebKit

@available(*, deprecated, message: "Use LoadAdHandler")
@objc public protocol AdnSdkHandler {
    /*
     Used for close view from layout
     https://github.com/Adnuntius/ios_sdk/wiki/Adnuntius-Advertising#close-view-from-layout
     */
    func onClose(_ view: AdnuntiusAdWebView)
}

@available(*, deprecated, message: "Use LoadAdHandler")
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

@objc public class AdResponseInfo: NSObject {
    @objc public var definedWidth: Int = 0
    @objc public var definedHeight: Int = 0
    @objc public var width: Int = 0
    @objc public var height: Int = 0
    @objc public var lineItemId: String = ""
    @objc public var creativeId: String = ""
    
    public override var description: String {
        return "{definedWidth: \(self.definedWidth),"
            + " definedHeight: \(self.definedHeight),"
            + " width: \(self.width),"
            + " height: \(self.height),"
            + " lineItemId: \(self.lineItemId),"
            + " creativeId: \(self.creativeId)}"
    }
}

@objc public protocol LoadAdHandler {
    /*
     No ads was returned
     */
    @objc optional func onNoAdResponse(_ view: AdnuntiusAdWebView)
   
    /*
     If adnuntius ad server returns a non 200 status, or there is no target div
     or adn.js reports any other issue
    */
    @objc optional func onFailure(_ view: AdnuntiusAdWebView, _ message: String)
    
    /*
     This will not be called if there is no ad rendered (should be obvious)
    */
    @objc optional func onAdResponse(_ view: AdnuntiusAdWebView, _ response: AdResponseInfo)
    
    /*
     Pass through the onRestyle event from adn.js, this is
     enabled experimentally and may be removed in a future release
     */
    @objc optional func onAdResize(_ view: AdnuntiusAdWebView, _ response: AdResponseInfo)
    
    /*
     Used for close view from layout
     https://github.com/Adnuntius/ios_sdk/wiki/Adnuntius-Advertising#close-view-from-layout
     */
    @objc optional func onLayoutCloseView(_ view: AdnuntiusAdWebView)
}

private class HandlerAdaptor: LoadAdHandler {
    var adnAdLoadHandler: AdLoadCompletionHandler?
    var adnSdkHandler: AdnSdkHandler?
    
    func onLayoutCloseView(_ view: AdnuntiusAdWebView) {
        if adnSdkHandler != nil {
            adnSdkHandler!.onClose(view)
        }
    }
    
    func onFailure(_ view: AdnuntiusAdWebView, _ message: String) {
        if adnAdLoadHandler != nil {
            adnAdLoadHandler!.onFailure(view, message)
        }
    }
    
    func onNoAdResponse(_ view: AdnuntiusAdWebView) {
        if adnAdLoadHandler != nil {
            adnAdLoadHandler!.onNoAdResponse(view)
        }
    }
    
    func onAdResponse(_ view: AdnuntiusAdWebView, _ response: AdResponseInfo) {
        if adnAdLoadHandler != nil {
            adnAdLoadHandler!.onAdResponse(view, response.definedWidth, response.definedHeight)
        }
    }
}

public class AdnuntiusAdWebView: WKWebView, WKUIDelegate, WKNavigationDelegate, WKScriptMessageHandler {
    public let logger: Logger = Logger()
    
    private var loadAdHandler: LoadAdHandler?
    
    // for objective c and legacy apps a handler adaptor we will only create when first used
    private var handlerAdaptor = HandlerAdaptor()
    
    private var delayVisibleEvents = false
    private var hasViewableCalled = false
    private var hasVisibleCalled = false
    private var adId: String?
    
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
    
    /**
    internal adnuntius dev use only
    */
    open func setEnv(_ env: AdnuntiusEnvironment) {
        self.env = env
    }
    
    // left here for objective-c to use ffs
    @objc open func enableDebug(_ b: Bool) {
        self.logger.debug = b
    }

    private func setupCallbacks(_ delayVisibleEvents: Bool, _ handler: LoadAdHandler) {
        self.adId = nil
        if delayVisibleEvents {
            self.adId = UUID().uuidString
        }
        self.hasVisibleCalled = false
        self.hasViewableCalled = false

        // we only want to do this once
        if self.loadAdHandler == nil {
            let metaScript = WKUserScript(source: AdUtils.META_VIEWPORT_JS,
                                                injectionTime: WKUserScriptInjectionTime.atDocumentEnd, forMainFrameOnly: true)

            let shimScript = WKUserScript(source: AdUtils.getAdnuntiusAjaxShimJs(self.logger.debug),
                                        injectionTime: WKUserScriptInjectionTime.atDocumentStart, forMainFrameOnly: true)

            self.configuration.userContentController.addUserScript(metaScript)
            self.configuration.userContentController.addUserScript(shimScript)
            self.configuration.userContentController.add(self, name: AdUtils.INTERNAL_ADNUNTIUS_MESSAGE_HANDLER)
            self.configuration.userContentController.add(self, name: AdUtils.ADNUNTIUS_MESSAGE_HANDLER)
        }
        
        self.loadAdHandler = handler
        self.navigationDelegate = self
        self.uiDelegate = self
    }

    /**
     Parameter request: The Ad Request configuration
     Parameter completionHandler: deprecated handler
     Parameter: adnSdkHandler: - deprecated handler
     
     Warning: Before release 1.10.0 of the iOS SDK, calls to loadAd would generate viewable and visible events as soon as the ad was rendered but before it was visible in the device viewport.
     From 1.10.0 onwards, this version of loadAd visible and viewable events will not be immediately generated.    If you want the old behaviour use `loadAd(request. handler, false)`
     */
    @available(*, deprecated, message: "Use loadAd(Request, LoadAdHandler, delayViewEvents: true) instead")
    @objc open func loadAd(_ request: AdRequest, completionHandler: AdLoadCompletionHandler? = nil, adnSdkHandler: AdnSdkHandler? = nil) -> Bool {
        self.handlerAdaptor.adnAdLoadHandler = completionHandler
        self.handlerAdaptor.adnSdkHandler = adnSdkHandler
        setupCallbacks(false, self.handlerAdaptor)
        
        let requestJson = AdUtils.toJson(self.adId, request, self.env, self.logger.debug)
        self.logger.verbose("\(requestJson)")
        self.loadHTMLString(requestJson.script, baseURL: requestJson.baseUrl)
        return true
    }

    /**
     Parameter request: The Ad Request configuration
     Parameter loadAdHandler:
     
     Warning: Before release 1.10.0 of the iOS SDK, calls to loadAd would generate viewable and visible events as soon as the ad was rendered but before it was visible in the device viewport.
     From 1.10.0 onwards, this version of loadAd visible and viewable events will not be immediately generated.    If you want the old behaviour use `loadAd(request. handler, delayViewEvents: false)`
     */
    @objc open func loadAd(_ request: AdRequest, _ handler: LoadAdHandler) {
        self.loadAd(request, handler, delayViewEvents: true)
    }
    
    /**
     Parameter config: The Ad Request configuration
     Parameter loadAdHandler:
     Parameter: delayViewEvents: if true will delay visible and viewable events until updateView(...) is called.  If false will generate visible and viewable events as soon as the ad is rendered.
    */
    @objc open func loadAd(_ request: AdRequest, _ handler: LoadAdHandler, delayViewEvents : Bool) {
        self.handlerAdaptor.adnAdLoadHandler = nil
        self.handlerAdaptor.adnSdkHandler = nil
        setupCallbacks(delayViewEvents, handler)

        let requestJson = AdUtils.toJson(self.adId, request, self.env, self.logger.debug)
        self.logger.verbose("\(requestJson)")
        self.loadHTMLString(requestJson.script, baseURL: requestJson.baseUrl)
    }

    /**
     This function is used by calling code to notify the AdnuntiusWebView of potential changes in its visiblity
      in the device view port.

      Currently is supported for UIScrollView and UITableView (a table view *is* a ScrollView) only.
     */
    @objc open func updateView(_ scrollView: UIScrollView) {
        // ignore calls to this method for cases where loadAd has not been called or called with delayViewEvents: false
        if (self.adId == nil) {
            return
        }

        let container = CGRect(origin: scrollView.contentOffset, size: scrollView.frame.size)
        // for a table view we need the superview for correct visiblity calculations
        if scrollView is UITableView {
            // a superview will not be accessible if the cell is not on screen, is a good thing
            if let superview = self.superview {
                self.logger.verbose("container: \(container)")
                self.logger.verbose("superview frame: \(superview.frame)")
                let percentage = RectUtils.percentageContains(container, superview.frame)
                updateView(percentage)
            }
        } else {
            self.logger.verbose("container: \(container)")
            self.logger.verbose("frame: \(self.frame)")
            let percentage = RectUtils.percentageContains(container, self.frame)
            updateView(percentage)
        }
    }

    private func updateView(_ percentage: Int) -> Void {
        self.logger.debug("Percentage: \(percentage)")
        
        if percentage > 0 && !self.hasVisibleCalled {
            self.hasVisibleCalled = true
            registerEvent("Visible")
        }
        
        // FIXME - should not call until viewable for 1 second
        if percentage >= 50 && !self.hasViewableCalled {
            self.hasViewableCalled = true
            registerEvent("Viewable")
        }
    }
    
    private func registerEvent(_ event: String) {
        self.logger.debug("registerEvent: \(event)")

        let eventJsScript = """
        window.adn = window.adn || {}; adn.calls = adn.calls || [];
        adn.calls.push(function() {
            adn.reg\(event)({externalId: '\(self.adId!)'})
        })
        """
        self.evaluateJavaScript(eventJsScript)
    }
    
    open func webView(_ webView: WKWebView, createWebViewWith configuration: WKWebViewConfiguration,
                 for navigationAction: WKNavigationAction,
                 windowFeatures: WKWindowFeatures) -> WKWebView? {
        
        if let frame = navigationAction.targetFrame,
            frame.isMainFrame {
            self.logger.debug("Open Link in same window")
            return nil
        }
        
        let url = navigationAction.request.url!
        doClick(url)
        return nil
    }

    private func doClick(_ url: URL) {
        self.logger.debug("Open link in new window")
        if #available(iOS 10.0, *) {
            UIApplication.shared.open(url)
        } else {
            UIApplication.shared.openURL(url)
        }
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
        self.loadAdHandler!.onFailure?(self, "Failed loading: \(error as NSError?)")
    }
    
    open func userContentController(_ userContentController: WKUserContentController,
                                   didReceive wkmessage: WKScriptMessage) {
        if let dict = wkmessage.body as? [String : AnyObject] {
            if let type = dict["type"] as? String {
                if type == "console" {
                    if let method = dict["method"] as? String, let message = dict["message"] as? String {
                        if self.logger.verbose {
                            self.logger.verbose("console.\(method): \(message)")
                        } else if self.logger.debug {
                            let token = message.components(separatedBy: ":")
                            self.logger.debug("\(token[0])")
                        }
                    }
                } else if type == "version" {
                    if let version = dict["version"] as? String {
                        if self.logger.debug {
                            self.logger.debug("ADN JS Version: \(version)")
                        }
                    }
                } else if type == "pageLoad" {
                    if let adCount = dict["adCount"] as? Int {
                        if adCount > 0 {
                            let response: AdResponseInfo = newAdResponseInfo(dict)
                            self.loadAdHandler!.onAdResponse?(self, response)
                        } else {
                            self.loadAdHandler!.onNoAdResponse?(self)
                        }
                    }
                } else if type == "resize" {
                    let response: AdResponseInfo = newAdResponseInfo(dict)
                    if response.width > 0 && response.height > 0 {
                        self.loadAdHandler!.onAdResize?(self, response)
                    }
                } else if type == "failure" {
                    if let httpStatus = dict["status"] as? Int, let response = dict["response"] as? String {
                        self.loadAdHandler!.onFailure?(self, "\(httpStatus) error: \(response)")
                    }
                } else if type == "closeView" {
                    self.loadAdHandler!.onLayoutCloseView?(self)
                }
            }
        }
    }
    
    private func newAdResponseInfo(_ dict: [String : AnyObject]) -> AdResponseInfo {
        let adResponseInfo = AdResponseInfo()
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
}
