//
//  AdnuntiusAdWebView.swift
//  AdnuntiusSDK
//
//  Copyright (c) 2019 Adnuntius AS.  All rights reserved.
//
import UIKit
import WebKit

@objc public protocol AdLoadCompletionHandler {
    func onComplete(_ view: AdnuntiusAdWebView, _ adCount: Int)
    func onFailure(_ view: AdnuntiusAdWebView, _ message: String)
}

// TODO - support WKWebView and UIWebView
// https://github.com/globalpayments/rxp-ios/blob/master/Pod/Classes/RealexComponent/HPPViewController.swift
public class AdnuntiusAdWebView: UIWebView, UIWebViewDelegate {
    private var completionHandler: AdLoadCompletionHandler?
    
    // a poor mans version of this is what we have implemented here
    // https://github.com/tcoulter/jockeyjs
    
    // https://stackoverflow.com/questions/5353278/uiwebviewdelegate-not-monitoring-xmlhttprequest
    public static var adnSdkShim = """
    if(!adnSdkShim) {
        var adnSdkShim = new Object();
        adnSdkShim.open = XMLHttpRequest.prototype.open;
        adnSdkShim.send = XMLHttpRequest.prototype.send;
        adnSdkShim.console = Window.console;

        adnSdkShim.eventUrl = function(url) {
            var i = document.createElement("iframe");
            i.src = url;
            i.style.opacity=0;
            document.body.appendChild(i);
            setTimeout(function(){i.parentNode.removeChild(i)},200);
        }
    
        adnSdkShim.ajaxEvent = function(url, status, response) {
            var adCount = 0
            if (status == 200) {
                adCount = this.getAdsCount(response)
            }
            this.eventUrl('adnuntius://ajax?status=' + status + '&adCount=' + adCount + '&url=' + encodeURIComponent(url))
        }

        adnSdkShim.consoleEvent = function(method, message) {
            this.eventUrl('adnuntius://console?method=' + method + '&message=' + encodeURIComponent(message))
        }

        XMLHttpRequest.prototype.open = function(method, url, async, user, password) {
          url = url + "&sdk=ios:\(AdnuntiusSDK.sdk_version)"
          adnSdkShim.open.apply(this, arguments);
          adnSdkShim.url = url;
        }

        XMLHttpRequest.prototype.send = function(data) {
          var callback = this.onreadystatechange;
          this.onreadystatechange = function() {
               if (this.readyState == 4) {
                   try {
                      adnSdkShim.ajaxEvent(adnSdkShim.url, this.status, this.response);
                   } catch(e) {}
               }
               callback.apply(this, arguments);
          }
          adnSdkShim.send.apply(this, arguments);
        }

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
            adnSdkShim.consoleEvent(method, message)
            adnSdkShim.console[method](message)
        }

        window.console = {
            log: function(){
                adnSdkShim.handleConsole('log', arguments)
            }
            , warn: function(){
                adnSdkShim.handleConsole('warn', arguments)
            }
            , error: function(){
                adnSdkShim.handleConsole('error', arguments)
            }
        }
    }
    """
    
    override public init(frame: CGRect) {
        super.init(frame: frame)
        self.delegate = self
    }

    required public init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        self.delegate = self
    }

    @objc open func adView () -> AdnuntiusAdWebView {
        return self
    }
    
    @objc open func loadFromScript(_ script: String, completionHandler: AdLoadCompletionHandler) -> Void {
        Logger.debug("load from script")

        self.completionHandler = completionHandler
        self.loadHTMLString(script, baseURL: nil)
    }
    
    /*
     Very basic interface where only auId, width, height, categories and key values for a single ad unit are required
     */
    @objc open func loadFromConfig(_ config: AdConfig, completionHandler: AdLoadCompletionHandler) -> Void {
        Logger.debug("load from config")

        self.completionHandler = completionHandler
        
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
        self.loadHTMLString(script, baseURL: nil)
    }
    
    @objc open func loadFromApi(_ config: [String: Any], completionHandler: AdLoadCompletionHandler) -> Void {
        Logger.debug("load from api")

        self.completionHandler = completionHandler
                
        APIService.getAds(config, completion: {(ads, error) in
            if ads != nil {
                if ads!.adUnits.count > 0 {
                    if (ads!.adUnits[0].ads.count > 0) {
                        let ad = ads!.adUnits[0].ads[0]
                        self.loadHTMLString(ad.html, baseURL: nil)

                        // FIXME this does not seem to work that well in the sample, must be missing something
                        let creativeRatio = Double(ad.creativeHeight)! / Double(ad.creativeWidth)!
                        let x = self.frame.origin.x
                        let y = self.frame.origin.y
                        let width = self.frame.width
                        let height = CGFloat(Double(UIScreen.main.bounds.width) * creativeRatio)
                        
                        self.frame = CGRect(x: x, y: y, width: width, height: height)
                        self.heightAnchor.constraint(equalToConstant: self.frame.height)
                        self.layoutIfNeeded()
                        
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
    
    open func webView(_ webView: UIWebView, didFailLoadWithError error: Error) {
        self.doOnFailure("Failed loading: \(error)")
    }
    
    open func webViewDidStartLoad(_ webView: UIWebView) {
        webView.stringByEvaluatingJavaScript(from: AdnuntiusAdWebView.adnSdkShim)
    }
    
    open func webViewDidFinishLoad(_ webView: UIWebView) {
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
    
    open func webView(_ webView: UIWebView, shouldStartLoadWith request: URLRequest, navigationType: UIWebView.NavigationType) -> Bool {
        let url = request.url!
        
        if url.absoluteString == "about:blank" {
            return true;
        }

        if url.scheme! == "adnuntius" {
            var dict = [String:String]()
            let components = URLComponents(url: url, resolvingAgainstBaseURL: false)!
            if let queryItems = components.queryItems {
                for item in queryItems {
                    dict[item.name] = item.value!
                }
                
                if let host = components.host {
                    if host == "ajax" {
                        let httpStatus = dict["status"]!
                        let requestUrl = dict["url"]!
                        let adCount = Int(dict["adCount"]!)!
                        
                        Logger.debug("Ajax Url: " + requestUrl)
                        
                        // return error code 400 for a invalid auId
                        if httpStatus != "200" {
                            self.doOnFailure(httpStatus + " error returned for " + requestUrl)
                        } else {
                            // only register an oncomplete for an impression, everything else is callbacks
                            if requestUrl.contains("delivery.adnuntius.com/i") {
                                self.doOnComplete(adCount)
                            }
                        }
                    } else if host == "console" {
                        let method = dict["method"]!
                        let message = dict["message"]!
                        
                        if message.contains("Unable to find HTML element") {
                            self.doOnFailure(message)
                        } else {
                            Logger.debug(method + " " + message)
                        }
                    }
                }
            }
            return false
        }
        
        if (navigationType == .linkClicked) {
            Logger.debug("Normal Click Url: " + url.absoluteString)
            doClick(url)
            return false
        } else if (navigationType == .other) {
            Logger.debug("Other Click Url: " + url.absoluteString)
            doClick(url)
            return false
        } else {
            return true
        }
    }
}
