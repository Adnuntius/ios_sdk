//
//  Copyright (c) 2020 Adnuntius AS.  All rights reserved.
//

import WebKit

private struct HttpError: Error {
    let code: Int
    let message: String
}

private struct JsonAdUnitString {
    let auId: String
    let data: Data
    let json: String
}

@objc public protocol AdLoadCompletionHandler {
    // if this is called, it means no ads were matched
    func onNoAdResponse(_ view: AdnuntiusAdWebView)
    
    // if adnuntius delivery returns a non 200 status, or there is no target div
    // or adn.js reports any other issue, this will be called
    func onFailure(_ view: AdnuntiusAdWebView, _ message: String)

    // will return the size in pixels of each ad loaded
    // this will not be called if there are no ad rendered (should be obvious)
    func onAdResponse(_ view: AdnuntiusAdWebView, _ width: Int, _ height: Int)
}

public class AdnuntiusAdWebView: WKWebView, WKUIDelegate, WKNavigationDelegate, WKScriptMessageHandler {
    private var completionHandler: AdLoadCompletionHandler?

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
                });
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

    adnSdkShim.handleConsole = function(method, args) {
        var message = Array.prototype.slice.apply(args).join(' ')
        adnSdkShim.adnAdnuntiusMessage({
                              type: "console",
                              method: method,
                              message: message
                            });
        adnSdkShim.console[method](message)
    }

    adnSdkShim.onPageLoad = function(args) {
        adnSdkShim.adnAdnuntiusMessage({
                              type: "ad",
                              id: args.auId || "",
                              target: args.targetId || "",
                              adCount: args.retAdCount || 0,
                              height: args.h || 0,
                              width: args.w || 0
            });
    };

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

    private var loadedViaApi: Bool = false
    
    @objc open func adView () -> AdnuntiusAdWebView {
        return self
    }

    private func setupCallbacks(_ completionHandler: AdLoadCompletionHandler) {
        self.loadedViaApi = false
        self.completionHandler = completionHandler
        self.navigationDelegate = self
        
        let metaScript = WKUserScript(source: AdnuntiusAdWebView.META_VIEWPORT_JS,
                                            injectionTime: WKUserScriptInjectionTime.atDocumentEnd, forMainFrameOnly: true)
                
        let shimScript = WKUserScript(source: AdnuntiusAdWebView.ADNUNTIUS_AJAX_SHIM_JS,
                                    injectionTime: WKUserScriptInjectionTime.atDocumentStart, forMainFrameOnly: true)
        
        self.configuration.userContentController.addUserScript(metaScript)
        self.configuration.userContentController.addUserScript(shimScript)
        self.configuration.userContentController.add(self, name: AdnuntiusAdWebView.ADNUNTIUS_MESSAGE_HANDLER)
    }

    /*
     Return false if the initial validation of the config parameter fails, otherwise all other signals will be via
     the completion handler
     */
    @objc open func loadFromConfig(_ config: [String: Any], completionHandler: AdLoadCompletionHandler) -> Bool {
        setupCallbacks(completionHandler)

        guard let jsonData = self.parseConfig(config, false) else {
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
                        adUnits: \(jsonData.json)
                    });
                });
                </script>
           </body>
        </html>
        """
        
        Logger.debug("Html Request: " + script)
        
        self.loadHTMLString(script, baseURL: URL(string: AdnuntiusAdWebView.BASE_URL))
        
        return true
    }

    /*
     Return false if the initial validation of the config parameter fails, otherwise all other signals will be via
     the completion handler
     */
    @objc open func loadFromApi(_ config: [String: Any], completionHandler: AdLoadCompletionHandler) -> Bool {
        guard let jsonData = self.parseConfig(config, true) else {
            return false
        }
        
        setupCallbacks(completionHandler)
        
        getAdsFromApi(jsonData, completion: {(ads, error) in
            if ads != nil {
                if ads!.adUnits.count > 0 {
                    if (ads!.adUnits[0].ads.count > 0) {
                        let ad = ads!.adUnits[0].ads[0]
                        self.loadedViaApi = true
                        self.loadHTMLString(ad.html, baseURL: URL(string: AdnuntiusAdWebView.BASE_URL))
                        
                        let width = Int(ad.creativeWidth) ?? 0
                        let height = Int(ad.creativeHeight) ?? 0
                        self.doOnAdResponse(width, height)
                    } else {
                        self.doOnNoAdResponse()
                    }
                } else {
                    self.doOnNoAdResponse()
                }
            } else {
                self.doOnFailure("Failed calling api: \(error!)")
            }
            return nil
        })

        return true
    }
    
    private func parseConfig(_ config: [String: Any], _ isApi: Bool) -> JsonAdUnitString? {
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

        guard let jsonData = try? JSONSerialization.data(withJSONObject: isApi ? config : adUnits) else {
            Logger.error("Malformed request: Could not parse request")
            return nil
        }
        
        guard let jsonText = String(data: jsonData, encoding: .utf8) else {
            Logger.error("Malformed request: Could not parse request")
            return nil
        }
        
        Logger.debug("Json Request: " + jsonText)

        return JsonAdUnitString(auId: auId, data: jsonData, json: jsonText)
    }
    
    private func getAdsFromApi(_ jsonData: JsonAdUnitString, completion: @escaping (_ ads: AdApi?, _ error: Error?) -> Void?) {
        let url = URL(string: "https://delivery.adnuntius.com/i?format=json&sdk=ios:" + AdnuntiusSDK.sdk_version)
        
        var request = URLRequest(url: url!)
        request.httpMethod = "POST"
        request.httpBody = jsonData.data
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        
        URLSession.shared.dataTask(with: request) {
            (data, response, error) in
            if error != nil {
                DispatchQueue.main.async {
                    completion(nil, error)
                }
            }
            
            guard let data = data else { return }
            do {
                let hresponse = response as! HTTPURLResponse
                if hresponse.statusCode != 200 {
                    let theData = String(data: data, encoding: .utf8)
                    DispatchQueue.main.async {
                        completion(nil, HttpError(code: hresponse.statusCode, message: theData!))
                    }
                } else {
                    let ads = try JSONDecoder().decode(AdApi.self, from: data)

                    DispatchQueue.main.async {
                        completion(ads, nil)
                    }
                }
            } catch let error {
                DispatchQueue.main.async {
                    completion(nil, error)
                }
            }
        }.resume()
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
            return
        } else if (type == "ad") {
            // we skip this section because when loading from api its already taken care of
            if !self.loadedViaApi {
                let adCount = dict["adCount"] as! Int
                if adCount > 0 {
                    let width = dict["width"] as! Int
                    let height = dict["height"] as! Int
                    self.doOnAdResponse(width, height)
                } else {
                    self.doOnNoAdResponse()
                }
            }
        } else { // type == "url"
            let httpStatus = dict["status"] as! Int
            let requestUrl = dict["url"] as! String
            
            if httpStatus != 200 {
                let statusText = dict["statusText"] as! String
                self.doOnFailure("\(httpStatus.description) [\(statusText)] error returned for \(requestUrl)")
                return
            } else {
                Logger.debug("Url Request: \(requestUrl)")
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
            self.completionHandler?.onAdResponse(self, width, height)
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
