//
//  AdnuntiusAdWebView.swift
//  AdnuntiusSDK
//
//  Copyright (c) 2019 Adnuntius AS.  All rights reserved.
//
import UIKit
import WebKit

public class AdnuntiusAdWebView: UIWebView {
    private let ldelegate: DefaultUIWebViewDelegate = DefaultUIWebViewDelegate()
    
    override public init(frame: CGRect) {
        super.init(frame: frame)
        self.delegate = self.ldelegate
    }
    
    convenience public init() {
        self.init(frame: CGRect.zero)
        self.delegate = self.ldelegate
    }
    
    required public init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        self.delegate = self.ldelegate
        self.layoutIfNeeded()
    }
    
    override open func draw(_ rect: CGRect) {
        super.draw(rect)
    }
    
    @objc open func setAdWebViewStateDelegate(_ listener: AdWebViewStateDelegate) {
        self.ldelegate.setDelegate(listener)
    }
    
    @objc open func adView () -> AdnuntiusAdWebView {
        return self
    }
    
    @objc open func loadFromScript(_ script: String) {
        print("DEBUG: load from the script")
        self.loadHTMLString(script, baseURL: nil)
    }
    
    @objc open func loadFromApi(_ config: [String: Any]) {
        print("DEBUG: load from the api")
        
        let adConfig: AdConfig = AdConfig(config)
        
        APIService.getAds(adConfig, completion: {(ads) in
            if (ads.adUnits.count > 0) {
                if (ads.adUnits[0].ads.count > 0) {
                    let html = ads.adUnits[0].ads[0].html
                    let filtered = html.replacingOccurrences(of: "href=", with: "target=\"_blank\" href=")
                    self.loadHTMLString(filtered, baseURL: nil)
                    
                    let creativeRatio = Double(ads.adUnits[0].ads[0].creativeHeight)! / Double(ads.adUnits[0].ads[0].creativeWidth)!
                    
                    self.frame = CGRect(x: self.frame.origin.x, y: self.frame.origin.y, width: self.frame.width, height: CGFloat(Double(UIScreen.main.bounds.width) * creativeRatio))
                    
                    self.heightAnchor.constraint(equalToConstant: self.frame.height)
                    self.layoutIfNeeded()
                } else {
                    print("DEBUG: No ads returned")
                }
            } else {
                print("DEBUG: No ad units returned")
            }
            return nil
        })
    }
}

@objc public protocol AdWebViewStateDelegate {
    func adLoaded()
    func adNotLoaded()
}

class DefaultUIWebViewDelegate: NSObject, UIWebViewDelegate {
    private var delegate: AdWebViewStateDelegate?
    
    open func setDelegate(_ delegate: AdWebViewStateDelegate) {
        self.delegate = delegate
    }
    
    open func webViewDidFinishLoad(_ webView: UIWebView) {
        let html = webView.stringByEvaluatingJavaScript(from: "document.body.innerHTML")
        if let page = html {
            // fixme - we need to distinguish between the initial load of the javascript and it
            // getting replaced with the ad
            if page.contains("<iframe") {
                if (self.delegate != nil) {
                    self.delegate!.adLoaded()
                }
            } else {
                if (self.delegate != nil) {
                    self.delegate!.adNotLoaded()
                }
            }
        }
    }

    open func webView(_ webView: UIWebView, shouldStartLoadWith request: URLRequest, navigationType: UIWebView.NavigationType) -> Bool {
        // Define a behaviour that will happen when an ad is clicked
        guard let url = request.url, navigationType == .linkClicked else { return true }
        if #available(iOS 10.0, *) {
            UIApplication.shared.open(url)
        } else {
            UIApplication.shared.openURL(url)
        }
        return false
    }
}
