//
//  Copyright (c) 2020 Adnuntius AS.  All rights reserved.
//

import WebKit

@objc public protocol AdLoadCompletionHandler {
    func onComplete(_ view: AdnuntiusAdWebView, _ adCount: Int)
    func onFailure(_ view: AdnuntiusAdWebView, _ message: String)
}

public class AdnuntiusAdWebView: WKWebView, WKUIDelegate, WKNavigationDelegate, WKScriptMessageHandler {
    private var completionHandler: AdLoadCompletionHandler?
    
    public static var ADNUNTIUS_MESSAGE_HANDLER = "adnuntiusMessageHandler"
    public static var BASE_URL = "https://delivery.adnuntius.com/"
    
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
            if (this.readyState == 4) {
                var adCount = 0
                if (this.status == 200) {
                    adCount = adnSdkShim.getAdsCount(this.response)
                    adnSdkShim.adnAdnuntiusMessage({
                          "type": "ad",
                          "url": adnSdkShim.url,
                          "status": this.status,
                          "adCount": adCount
                    });
                } else {
                    adnSdkShim.adnAdnuntiusMessage({
                          "type": "add",
                          "url": adnSdkShim.url,
                          "status": this.status,
                          "statusText": this.statusText
                    });
                }
            }
            callback.apply(this, arguments)
        }
        adnSdkShim.send.apply(this, arguments)
    }

    adnSdkShim.adnAdnuntiusMessage = function(message) {
        if (window.webkit && window.webkit.messageHandlers && window.webkit.messageHandlers.\(ADNUNTIUS_MESSAGE_HANDLER)) {
              window.webkit.messageHandlers.\(ADNUNTIUS_MESSAGE_HANDLER).postMessage(message)
        }
    }

    // way easier to do the parsing in here than in swift code
    adnSdkShim.getAdsCount = function(response) {
        var totalCount = 0
        try {
           var obj = JSON.parse(response)
           if (obj.adUnits != undefined) {
               obj.adUnits.forEach(function (item, index) {
                    var count = item.matchedAdCount
                    totalCount += count
               });
           }
        } catch(e) {}
        return totalCount
    }

    adnSdkShim.handleConsole = function(method, args) {
        var message = Array.prototype.slice.apply(args).join(' ')
        adnSdkShim.adnAdnuntiusMessage({
                              "type": "console",
                              "method": method,
                              "message": message
                            });
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
    """
    
    @objc open func adView () -> AdnuntiusAdWebView {
        return self
    }
    
    private func setupCallbacks(_ completionHandler: AdLoadCompletionHandler) {
        self.uiDelegate = self
        self.navigationDelegate = self
        self.completionHandler = completionHandler

        let metaScript = WKUserScript(source: AdnuntiusAdWebView.META_VIEWPORT_JS,
                                    injectionTime: WKUserScriptInjectionTime.atDocumentEnd, forMainFrameOnly: true)
        
        let shimScript = WKUserScript(source: AdnuntiusAdWebView.ADNUNTIUS_AJAX_SHIM_JS,
                                    injectionTime: WKUserScriptInjectionTime.atDocumentStart, forMainFrameOnly: true)
        
        self.configuration.userContentController.addUserScript(metaScript)
        self.configuration.userContentController.addUserScript(shimScript)
        self.configuration.userContentController.add(self, name: AdnuntiusAdWebView.ADNUNTIUS_MESSAGE_HANDLER)
    }
    
    @objc open func loadFromScript(_ script: String, completionHandler: AdLoadCompletionHandler) -> Void {
        Logger.debug("load from script")
        setupCallbacks(completionHandler)
        self.loadHTMLString(script)
    }
    
    private func loadHTMLString(_ script: String) {
        self.loadHTMLString(script, baseURL: URL(string: AdnuntiusAdWebView.BASE_URL))
    }

    /*
       Very basic interface where only auId, width, height, categories and key values for a single ad unit are required
     */
    @objc open func loadFromConfig(_ config: AdConfig, completionHandler: AdLoadCompletionHandler) -> Void {
        Logger.debug("load from config")

        let output = config.toJson()
        let script = """
        <html>
           <head>
            <script type="text/javascript" src="https://cdn.adnuntius.com/adn.js" async></script>
           </head>
           <body>
                <div id="adn-\(config.getAuId())" style="display:none"></div>
                <script type="text/javascript">
                    window.adn = window.adn || {}; adn.calls = adn.calls || [];
                    adn.calls.push(function() {
                        adn.request({ adUnits: [
                        \(output)
                   ]});
                });
                </script>
           </body>
        </html>
        """
        
        setupCallbacks(completionHandler)
        self.loadHTMLString(script)
    }
    
    @objc open func loadFromApi(_ config: [String: Any], completionHandler: AdLoadCompletionHandler) -> Void {
        Logger.debug("load from api")

        setupCallbacks(completionHandler)
        
        APIService.getAds(config, completion: {(ads, error) in
            if ads != nil {
                if ads!.adUnits.count > 0 {
                    if (ads!.adUnits[0].ads.count > 0) {
                        let ad = ads!.adUnits[0].ads[0]
                        self.loadHTMLString(ad.html)
                        self.doOnComplete(1)
                    } else {
                        self.doOnComplete(0)
                    }
                } else {
                    self.doOnComplete(0)
                }
            } else {
                self.doOnFailure("Failed calling api: \(error!)")
            }
            return nil
        })
    }
    
    open func webView(_ webView: WKWebView, didStartProvisionalNavigation navigation: WKNavigation) {
        UIApplication.shared.isNetworkActivityIndicatorVisible = true
    }

    open func webView(_ webView: WKWebView, didFinish navigation: WKNavigation) {
        UIApplication.shared.isNetworkActivityIndicatorVisible = false
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
                Logger.debug(method + " " + message)
            }
            return
        } else { // type == "ad"
            let httpStatus = dict["status"] as! Int
            let requestUrl = dict["url"] as! String
            
            if httpStatus != 200 {
                let statusText = dict["statusText"] as! String
                self.doOnFailure("\(httpStatus.description) [\(statusText)] error returned for \(requestUrl)")
                return
            }
            
            Logger.debug("Ajax Url: \(requestUrl)")
            
            // only register an oncomplete for an impression, everything else is callbacks
            if requestUrl.contains("delivery.adnuntius.com/i") {
                let adCount = dict["adCount"] as! Int
                self.doOnComplete(adCount)
            }
        }
    }

    open func webView(_ webView: WKWebView,
                     decidePolicyFor navigationAction: WKNavigationAction,
                     decisionHandler: @escaping (WKNavigationActionPolicy) -> Void) {
        let url = navigationAction.request.url!
        let navigationType = navigationAction.navigationType

        if url.absoluteString == "about:blank" || url.absoluteString == AdnuntiusAdWebView.BASE_URL {
            decisionHandler(.allow)
            return
        }
        
        if (navigationType == .linkActivated) {
            Logger.debug("Normal Click Url: " + url.absoluteString)
            doClick(url)
            decisionHandler(.cancel)
            return
        } else if (navigationType == .other) {
            Logger.debug("Other Click Url: " + url.absoluteString)
            doClick(url)
            decisionHandler(.cancel)
            return
        } else {
            decisionHandler(.allow)
            return
        }
    }
    
    private func doOnComplete(_ count: Int) {
        if (self.completionHandler != nil) {
            self.completionHandler?.onComplete(self, count)
        }
    }
    
    private func doOnFailure(_ message: String) {
        if (self.completionHandler != nil) {
            self.completionHandler?.onFailure(self, message)
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
