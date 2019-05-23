//
//  AdnuntiusAdWebView.swift
//  AdnuntiusSDK
//
//  Created by Mateusz Grzywa on 01/09/2018.
//  Copyright © 2018 Mateusz Grzywa. All rights reserved.
//
import UIKit
import WebKit

public class AdnuntiusAdWebView: UIWebView {
    var tapAction : String = ""
    var clickUrl: String = ""
    @IBInspectable var adViewName = ""
    public var creativeRatio: Double = 0.0
    
    override public init(frame: CGRect) {
        print("init frame with conf")
        super.init(frame: frame)
        addBehavior()
    }
    
    convenience public init() {
        self.init(frame: CGRect.zero)
    }
    
    required public init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        self.layoutIfNeeded()
        addBehavior()
    }
    override open func draw(_ rect: CGRect) {
        super.draw(rect)
    }
    func webView(_ webView: WKWebView, createWebViewWith configuration: WKWebViewConfiguration, for navigationAction: WKNavigationAction, windowFeatures: WKWindowFeatures) -> WKWebView? {
        print("Create webview")
        if navigationAction.targetFrame == nil {
            webView.load(navigationAction.request)
        }
        return nil
    }
    
    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldRecognizeSimultaneouslyWithGestureRecognizer otherGestureRecognizer: UIGestureRecognizer) -> Bool {
        return true
    }
    open func adView () -> AdnuntiusAdWebView {
        return self
    }
    @objc func adTap(_ sender:UITapGestureRecognizer){
        if #available(iOS 10.0, *) {
            UIApplication.shared.open(URL(string: self.clickUrl)!)
        } else {
            UIApplication.shared.openURL(URL(string: self.clickUrl)!)
        }
    }
    open func addBehavior() {
        print("DEBUG: addBehaviour")
        if(AdnuntiusSDK.adScript != "") {
            print("DEBUG: load from the script")
            self.loadHTMLString(AdnuntiusSDK.adScript, baseURL: nil)
        } else {
            print("DEBUG: load from the api")
            APIService.getAds(completion: {(ads) in
                self.loadHTMLString(ads.adUnits[0].ads[0].html.replacingOccurrences(of: "src=\"//", with: "src=\"https://").replacingOccurrences(of: "href=", with: "target=\"_blank\" href="), baseURL: nil)
                self.clickUrl = ads.adUnits[0].ads[0].clickUrl
                self.creativeRatio = Double(ads.adUnits[0].ads[0].creativeHeight)! / Double(ads.adUnits[0].ads[0].creativeWidth)!
                self.frame = CGRect(x: self.frame.origin.x, y: self.frame.origin.y, width: self.frame.width, height: CGFloat(Double(UIScreen.main.bounds.width) * self.creativeRatio))
                self.heightAnchor.constraint(equalToConstant: self.frame.height)
                self.layoutIfNeeded()
                return nil
            })
            let gesture = UITapGestureRecognizer(target: self, action:  #selector (self.adTap (_:)))
            self.addGestureRecognizer(gesture)
        }
    }
}
