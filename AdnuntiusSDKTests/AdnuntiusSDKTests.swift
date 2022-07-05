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

    func testOtherConfig() throws {
        let logger: Logger = Logger()
        
        var config = [
            "adUnits": [
                   [
                    "auId": "some auId"
                   ]
            ],
            "useCookies": false
        ] as [String : Any]
        var requestConfig = AdUtils.parseConfig(config, logger)
        XCTAssertEqual(requestConfig?.useCookies!, false)
        XCTAssertEqual(requestConfig?.auId, "some auId")
        XCTAssertNil(requestConfig?.kv)
        XCTAssertNil(requestConfig?.auH)
        XCTAssertNil(requestConfig?.auW)
        XCTAssertNil(requestConfig?.c)
        XCTAssertNil(requestConfig?.livePreview)
        XCTAssertNil(requestConfig?.userId)
        XCTAssertNil(requestConfig?.sessionId)
        XCTAssertNil(requestConfig?.consentString)
        XCTAssertNil(requestConfig?.globalParameters)
        
        config = [
            "adUnits": [
                   [
                    "auId": "some auId"
                   ]
            ],
            "useCookies": false
        ] as [String : Any]
        requestConfig = AdUtils.parseConfig(config, logger)
        XCTAssertEqual(requestConfig?.useCookies!, false)
        XCTAssertEqual(requestConfig?.auId, "some auId")
        
        config = [
            "adUnits": [
                   [
                    "auId": "some auId"
                   ]
            ],
            "noCookies": true
        ] as [String : Any]
        requestConfig = AdUtils.parseConfig(config, logger)
        XCTAssertEqual(requestConfig?.useCookies!, false)
        XCTAssertEqual(requestConfig?.auId, "some auId")
        
        config = [
            "userId": "my global user id",
            "sessionId": "my session id",
            "adUnits": [
                   [
                    "auId": "some auId"
                   ]
            ],
            "useCookies": true
        ] as [String : Any]
        requestConfig = AdUtils.parseConfig(config, logger)
        XCTAssertEqual(requestConfig?.useCookies!, true)
        XCTAssertEqual(requestConfig?.auId, "some auId")
        XCTAssertEqual(requestConfig?.userId!, "my global user id")
        XCTAssertEqual(requestConfig?.sessionId!, "my session id")

        config = [
            "userId": "my global user id",
            "sessionId": "my session id",
            "adUnits": [
                   [
                    "auId": "some auId"
                   ]
            ],
            "useCookies": false,
            "lpl": "my preview line item",
            "lpc": "my preview creative"
        ] as [String : Any]
        requestConfig = AdUtils.parseConfig(config, logger)
        XCTAssertEqual(requestConfig?.auId, "some auId")
        XCTAssertEqual(requestConfig?.userId!, "my global user id")
        XCTAssertEqual(requestConfig?.sessionId!, "my session id")
        XCTAssertEqual("my preview line item", requestConfig?.livePreview?.lpl)
        XCTAssertEqual("my preview creative", requestConfig?.livePreview?.lpc)
        
        config = [
            "userId": "my global user id",
            "sessionId": "my session id",
            "adUnits": [
                   [
                    "auId": "some auId"
                   ]
            ],
            "useCookies": false,
            "lpl": "my preview line item"
        ] as [String : Any]
        requestConfig = AdUtils.parseConfig(config, logger)
        XCTAssertEqual(requestConfig?.auId, "some auId")
        XCTAssertEqual(requestConfig?.userId!, "my global user id")
        XCTAssertEqual(requestConfig?.sessionId!, "my session id")
        // both lpl and lpc have to be provided for this feature to work
        XCTAssertNil(requestConfig?.livePreview?.lpl)
        XCTAssertNil(requestConfig?.livePreview?.lpc)
        
        config = [
            "userId": "my global user id",
            "sessionId": "my session id",
            "gdpr": "1",
            "adUnits": [
                   [
                    "auId": "some auId", "kv": ["key": ["value"]]
                   ]
        ],
            "useCookies": false,
            "lpl": "my preview line item"
        ] as [String : Any]
        requestConfig = AdUtils.parseConfig(config, logger)
        XCTAssertEqual(requestConfig?.auId, "some auId")
        XCTAssertEqual(requestConfig?.userId!, "my global user id")
        XCTAssertEqual(requestConfig?.sessionId!, "my session id")
        // both lpl and lpc have to be provided for this feature to work
        XCTAssertNil(requestConfig?.livePreview?.lpl)
        XCTAssertNil(requestConfig?.livePreview?.lpc)
    }
    
    func testKvConfig() throws {
        let logger: Logger = Logger()
        
        // the kv cannot be an array, it must be a dictionary only
        var config = ["adUnits": [
                   [
                    "auId": "some auId", "kv": [["key": ["value", "value_2"], "key2": ["value2", "value2_2"]]]
                   ]
            ]
        ] as [String : Any]
        var requestConfig = AdUtils.parseConfig(config, logger)
        XCTAssertNil(requestConfig)
        
        config = [
            "adUnits": [
                   [
                    "auId": "some auId", "kv": ["key": ["value", "value_2"], "key2": ["value2", "value2_2"]]
                   ]
            ]
        ] as [String : Any]
        requestConfig = AdUtils.parseConfig(config, logger)
        XCTAssertEqual(requestConfig?.auId, "some auId")
        var value = requestConfig?.kv!["key"]!
        XCTAssertEqual(value!.first, "value")
        XCTAssertEqual(value![1], "value_2")
        value = requestConfig?.kv!["key2"]!
        XCTAssertEqual(value!.first, "value2")
        XCTAssertEqual(value![1], "value2_2")
        
        config = [
            "adUnits": [
                   [
                    "auId": "some auId", "kv": ["key": "value", "key2": "value2"]
                   ]
            ]
        ] as [String : Any]
        requestConfig = AdUtils.parseConfig(config, logger)
        XCTAssertEqual(requestConfig?.auId, "some auId")
        value = requestConfig?.kv!["key"]!
        XCTAssertEqual(value!.first, "value")
        value = requestConfig?.kv!["key2"]!
        XCTAssertEqual(value!.first, "value2")
    }
    
    func testCategoryConfig() throws {
        let logger: Logger = Logger()
        
        // the kv cannot be an array, it must be a dictionary only
        var config = ["adUnits": [
                   [
                    "auId": "some auId", "c": ["value", "value2"]
                   ]
            ]
        ] as [String : Any]
        var requestConfig = AdUtils.parseConfig(config, logger)
        XCTAssertEqual(requestConfig?.auId, "some auId")
        XCTAssertEqual(requestConfig?.c!.first, "value")
        XCTAssertEqual(requestConfig?.c![1], "value2")
        
        config = ["adUnits": [
                   [
                    "auId": "some auId", "c": "value"
                   ]
            ]
        ] as [String : Any]
        requestConfig = AdUtils.parseConfig(config, logger)
        XCTAssertEqual(requestConfig?.auId, "some auId")
        XCTAssertEqual(requestConfig?.c!.first, "value")
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
        let json = AdUtils.toJson(config, AdnuntiusEnvironment.production)
        let script = json.script.replacingOccurrences(of: "\n", with: "").replacingOccurrences(of: "  ", with: "")
        print(script)
        let expected = "<html> <head><script type=\"text/javascript\" src=\"https://cdn.adnuntius.com/adn.js\" async></script><style>body {margin-top: 0px;margin-left: 0px;margin-bottom: 0px;margin-right: 0px;}</style> </head> <body><div id=\"adn-some auId\" style=\"display:none\"></div><script type=\"text/javascript\">window.adn = window.adn || {}; adn.calls = adn.calls || [];adn.calls.push(function() {adn.request({env: 'production',sdk: 'ios:\(AdnuntiusSDK.sdk_version)',onPageLoad: adnSdkShim.onPageLoad,onImpressionResponse: adnSdkShim.onImpressionResponse,onVisible: adnSdkShim.onVisible,onViewable: adnSdkShim.onViewable,onRestyle: adnSdkShim.onRestyle,onError: adnSdkShim.onError,adUnits: [{auId: 'some auId', auH: '200', auW: '100', kv: {'car': ['holden', 'ford'], 'sport': ['soccer']}, c: ['cat1', 'cat2']}],userId: 'my global user id', sessionId: 'my session id', useCookies: false, consentString: 'some consent string', gdpr: '1'});});</script> </body></html>"
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
