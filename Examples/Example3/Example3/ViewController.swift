//
//  ViewController.swift
//  Example3
//
//  Created by Mateusz Grzywa on 01/07/2019.
//  Copyright © 2019 Adnuntius. All rights reserved.
//

import UIKit
import AdnuntiusSDK

class ViewController: UIViewController, UIWebViewDelegate {

    @IBOutlet weak var adView: AdnuntiusAdWebView!
    
    func webView(_ webView: UIWebView, shouldStartLoadWith request: URLRequest, navigationType: UIWebView.NavigationType) -> Bool {
        // Define a behaviour that will happen when an ad is clicked
        guard let url = request.url, navigationType == .linkClicked else { return true }
        if #available(iOS 10.0, *) {
            UIApplication.shared.open(url)
        } else {
            UIApplication.shared.openURL(url)
        }
        return false
    }
    func webViewDidFinishLoad(_ webView: UIWebView) {
        // Detect if an ad is not present
        let html = webView.stringByEvaluatingJavaScript(from: "document.body.innerHTML")
        if let page = html {
            if !page.contains("<iframe") {
                // Ad is not present
                // Do any behaviour that you want to hide an ad
                // Ex. self.adView.isHidden = true
            }
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.adView.delegate = self
        // Do any additional setup after loading the view.
    }


}

