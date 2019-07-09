//
//  ViewController.swift
//  AdnuntiusTestApp
//
//  Created by Mateusz Grzywa on 27/08/2018.
//  Copyright © 2018 Mateusz Grzywa. All rights reserved.
//

import UIKit
import AdnuntiusSDK
import WebKit

class ViewController: UIViewController {

    @IBOutlet weak var adView: UIView!
    @IBOutlet weak var webView: WKWebView!
    
    @IBAction func applyAndReload(_ sender: Any) {
        webView.loadHTMLString("<!DOCTYPE html>\n<html>\n<head>\n    <meta charset=\"utf-8\">\n    <style type=\"text/css\" media=\"all\">\n        html, body, #responseCtr {\n            margin: 0;\n            padding: 0;\n            outline: 0;\n            border: 0;\n            overflow: hidden;\n        }\n\n        #responseCtr {\n            display: inline-block;\n            line-height: 0;\n            vertical-align: top;\n        }\n\n        #responseCtr a {\n            line-height: 0;\n        }\n\n        #responseCtr *, #responseCtr a * {\n            line-height: normal;\n        }\n\n        #responseCtr .adWrapper {\n            margin: 0;\n            padding: 0;\n            outline: 0;\n            border: 0;\n            display: inline-block;\n            line-height: 0;\n        }\n\n        a img {\n            border: none;\n            outline: none;\n        }\n\n        img {\n            margin: 0;\n            padding: 0;\n        }\n\n        /* need this displayNone class to ensure images are preloaded for smooth transition */\n        img.displayNone {\n            position: absolute;\n            top: -99999px;\n            left: -99999px;\n        }\n    </style>\n\n    <script type=\"text/javascript\" src=\"https://cdn.adnuntius.com/adn.js\"></script>\n</head>\n<body>\n<div id=\"responseCtr\">\n<div class=\"adWrapper\" id=\"adn-id-178465760\" data-line-item-id=\"70txx1grk8xm7ws0\" data-creative-id=\"bsm713jwp99s5sh1\" data-response-token=\"EeRjPApHSl6Uxjkt8GsCnlReEnlW9kaOAir7r2xnQalZ10R-viMZ5GMoGB1ZiGg49jTSe81W0EdwJm34Pu38doubmoEgDLbjwBxxzWH-_znIZ5dhyHyt1RWSUZ8l9jTjRws9lpjP8CBD4kAlw0_vvj2ZjYy1LJujq2WHe-m1KsatSaWwjSfDCTaTaZXK\"><a rel=\"nofollow\" target=\"_top\" href=\"https://delivery.adnuntius.com/c/EeRjPApHSl6Uxjkt8GsCnlReEnlW9kaOAir7r2xnQalZ10R-viMZ5GMoGB1ZiGg49jTSe81W0EdwJm34Pu38doubmoEgDLbjwBxxzWH-_znIZ5dhyHyt1RWSUZ8l9jTjRws9lpjP8CBD4kAlw0_vvj2ZjYy1LJujq2WHe-m1KsatSaWwjSfDCTaTaZXK?r=http%3A%2F%2Fnews.adnuntius.com&amp;ct=2501\" style=\"width: 100%\">\n<img src=\"http://assets.adnuntius.com/TaoCczuM6RaIubHort2nQ9L7xiwvOey2-iG3zUcp1nI.jpg\" style=\"width: 100%; max-width: 980px; margin: 0 auto; display: block;\" alt=\"\"/>\n</a>\n\n<script>\n\tadn.util.forEach(document.getElementsByClassName(\"adWrapper\"), function(el) {\n    \tel.style.width = \"100%\";\n    });\n\tvar iframeId = adn.inIframe.getIframeId();\n\tvar container = document.getElementById('responseCtr')\n    container.style.width = \"100%\"\n\tvar responsiveIframe = function(){\n        adn.inIframe.updateAd({\n        \tifrH: container.offsetHeight,\n            ifrStyle:{width: '100%', 'min-width':'100%', '*width':'100%' },\n            ifrId: iframeId\n        });\n\t}\n\twindow.onresize = function(){ responsiveIframe() }\n\twindow.onload = function(){ responsiveIframe() }\n    adn.inIframe.blockResizeToContent();\n</script>\n\n<div style=\"clear: both\"></div></div>\n</div>\n\n    \n        \n        \n<iframe src=\"https://delivery.adnuntius.com/b/EeRjPApHSl6Uxjkt8GsCnlReEnlW9kaOAir7r2xnQalZ10R-viMZ5GMoGB1ZiGg49jTSe81W0EdwJm34Pu38doubmoEgDLbjwBxxzWH-_znIZ5dhyHyt1RWSUZ8l9jTjRws9lpjP8CBD4kAlw0_vvj2ZjYy1LJujq2WHe-m1KsatSaWwjSfDCTaTaZXK.html\" scrolling=\"no\" frameborder=\"0\" width=\"1\" height=\"1\" style=\"position:absolute;top:-10000px;left:-100000px;\"></iframe>\n        \n\n<script type=\"text/javascript\">\n//<![CDATA[\n(function() { adn.inIframe.processAdResponse({ matchedAdCount: 1 }); })();\n//]]>\n</script>\n\n    \n\n</body>\n</html>", baseURL: nil)
    }
    override func viewDidLoad() {
        super.viewDidLoad()
        AdnuntiusSDK.shared.Hello()
        
        // Do any additional setup after loading the view, typically from a nib.
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }


}

