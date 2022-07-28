//
//  AdnuntiusSDKTests.swift
//  AdnuntiusSDKTests
//
//  Created by Jason Pell on 6/10/21.
//  Copyright © 2021 Adnuntius AS. All rights reserved.
//

import XCTest
import AdnuntiusSDK

class AdnuntiusSDKTests: XCTestCase, ApiClientHandler {
    private var count: Int = 0
    
    override func setUpWithError() throws {
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }

    override func tearDownWithError() throws {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
    }

    func testContains() {
        let frame = CGRect(x: 0, y: 0, width: 300, height: 600)
        XCTAssertEqual(50, RectUtils.percentageContains(frame, CGRect(x: 150, y: 300, width: 300, height: 300)))
        XCTAssertEqual(100, RectUtils.percentageContains(frame, CGRect(x: 0, y: 300, width: 300, height: 300)))
        XCTAssertEqual(25, RectUtils.percentageContains(frame, CGRect(x: 150, y: 450, width: 300, height: 300)))
        XCTAssertEqual(17, RectUtils.percentageContains(frame, CGRect(x: 150, y: 500, width: 300, height: 300)))
        XCTAssertEqual(8, RectUtils.percentageContains(frame, CGRect(x: 150, y: 500, width: 600, height: 300)))
        XCTAssertEqual(4, RectUtils.percentageContains(frame, CGRect(x: 150, y: 550, width: 600, height: 300)))
        XCTAssertEqual(0, RectUtils.percentageContains(frame, CGRect(x: 300, y: 550, width: 600, height: 300)))
        XCTAssertEqual(0, RectUtils.percentageContains(frame, CGRect(x: 150, y: 600, width: 600, height: 300)))
        XCTAssertEqual(0, RectUtils.percentageContains(frame, CGRect(x: 299, y: 600, width: 600, height: 300)))
        XCTAssertEqual(1, RectUtils.percentageContains(frame, CGRect(x: 299, y: 599, width: 600, height: 300)))
    }
    
    func testToJson() throws {
        let config = AdRequest("some auId")
        config.userId("my global user id")
        config.sessionId = "my session id"
        config.useCookies(false)
        config.consentString("some consent string")
        config.width("100")
        config.height("200")
        config.category("cat1")
        config.category("cat2")
        config.globalParameter("gdpr", "1")
        config.keyValue("car", "holden")
        config.keyValue("car", "ford")
        config.keyValue("sport", "soccer")
        let json = AdUtils.toJson(nil, config, AdnuntiusEnvironment.production, false)
        let script = json.script.replacingOccurrences(of: "\n", with: "").replacingOccurrences(of: "  ", with: "")
        //print(script)
        let expected = "<html> <head><script type=\"text/javascript\" src=\"https://cdn.adnuntius.com/adn.js\" async></script><style>body {margin-top: 0px;margin-left: 0px;margin-bottom: 0px;margin-right: 0px;}</style> </head> <body><div id=\"adn-some auId\" style=\"display:none\"></div><script type=\"text/javascript\">window.adn = window.adn || {}; adn.calls = adn.calls || [];adn.calls.push(function() {// no versionadn.request({env: 'production',impReg: 'default',externalId: null,sdk: 'ios:\(AdnuntiusSDK.sdk_version)',onPageLoad: adnSdkShim.onPageLoad,onImpressionResponse: adnSdkShim.onImpressionResponse,onVisible: adnSdkShim.onVisible,onViewable: adnSdkShim.onViewable,onRestyle: adnSdkShim.onRestyle,onError: adnSdkShim.onError,adUnits: [{auId: 'some auId', auH: '200', auW: '100', kv: {'car': ['holden', 'ford'], 'sport': ['soccer']}, c: ['cat1', 'cat2']}],userId: 'my global user id', sessionId: 'my session id', useCookies: false, consentString: 'some consent string', gdpr: '1'});});</script> </body></html>"
        XCTAssertEqual(expected, script)
    }
    
    func testApiClient() throws {
        let creativeIds:[String] = [
            "z539bknqnplvzyjl",
            "21cq2rb9yfptpkpm",
            "h7ss1yt0ccjjwhnr",
            "07fl69n2b8wbpn37",
            "nw9z2mgs2yl9sqt7",
            "2ftc67cfl1cbsdfl",
            "9kwdysnztt7hrzbb",
            "3v3dc10m2bg30ys7",
            "bclqbzdw6nmxtm2p",
            "711fh0nm5lt5w3xg",
            "8w1595rly1963yzd",
            "311xxr0mwm75dss6",
            "y69d11l5k3x7t3f3",
            "1bcpcpphkb0rdx59",
            "p6qpcq7sq67m6mzf",
            "l1l7vz96fdxzdsbm",
            "8tgz0lsgdyvyjd50",
            "3fs90nvsqy6702fb",
            "rhwjnrv6ljrkn035",
            "z8rjcyy0bhy9357x",
            "wysy25l7zx5vbv2d",
            "l1l08kzbpwvhlcxk"
        ]

        self.count = 0
        let apiClient = ApiClient()
        apiClient.authenticate("", "")
        for cId in creativeIds {
            apiClient.creative(cId, "fag_pressen", self)
        }
        
        while(self.count < creativeIds.count) {
            print("Waiting \(count) to be \(creativeIds.count)")
            sleep(5)
        }
    }
    
    func onSuccess(_ url: String, _ json: [String : Any]) {
        let creativeId = json["id"] as! String
        let lineItem = json["lineItem"] as! [String: Any]
        let lineItemId = lineItem["id"] as! String
        print("Creative(\"\(lineItemId)\", \"\(creativeId)\"),")
        self.count+=1
    }
    
    func onFailure(_ url: String, _ message: String) {
        print("Failed \(url): \(message)")
    }
    
    func onAuthFailure() {
        print("Auth failed")
    }
}
