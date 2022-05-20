//
//  AdnuntiusSDKTests.swift
//  AdnuntiusSDKTests
//
//  Created by Jason Pell on 6/10/21.
//  Copyright © 2021 Adnuntius AS. All rights reserved.
//

import XCTest
import AdnuntiusSDK

class AdnuntiusSDKTests: XCTestCase {

    override func setUpWithError() throws {
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }

    override func tearDownWithError() throws {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
    }

    func testOtherConfig() throws {
        let logger: Logger = Logger()
        let configParser: RequestConfigParser = RequestConfigParser(logger)
        
        var config = [
            "adUnits": [
                   [
                    "auId": "some auId"
                   ]
            ],
            "useCookies": false
        ] as [String : Any]
        var requestConfig = configParser.parseConfig(config)
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
        requestConfig = configParser.parseConfig(config)
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
        requestConfig = configParser.parseConfig(config)
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
        requestConfig = configParser.parseConfig(config)
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
        requestConfig = configParser.parseConfig(config)
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
        requestConfig = configParser.parseConfig(config)
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
        requestConfig = configParser.parseConfig(config)
        XCTAssertEqual(requestConfig?.auId, "some auId")
        XCTAssertEqual(requestConfig?.userId!, "my global user id")
        XCTAssertEqual(requestConfig?.sessionId!, "my session id")
        // both lpl and lpc have to be provided for this feature to work
        XCTAssertNil(requestConfig?.livePreview?.lpl)
        XCTAssertNil(requestConfig?.livePreview?.lpc)
    }
    
    func testKvConfig() throws {
        let logger: Logger = Logger()
        let configParser: RequestConfigParser = RequestConfigParser(logger)
        
        // the kv cannot be an array, it must be a dictionary only
        var config = ["adUnits": [
                   [
                    "auId": "some auId", "kv": [["key": ["value", "value_2"], "key2": ["value2", "value2_2"]]]
                   ]
            ]
        ] as [String : Any]
        var requestConfig = configParser.parseConfig(config)
        XCTAssertNil(requestConfig)
        
        config = [
            "adUnits": [
                   [
                    "auId": "some auId", "kv": ["key": ["value", "value_2"], "key2": ["value2", "value2_2"]]
                   ]
            ]
        ] as [String : Any]
        requestConfig = configParser.parseConfig(config)
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
        requestConfig = configParser.parseConfig(config)
        XCTAssertEqual(requestConfig?.auId, "some auId")
        value = requestConfig?.kv!["key"]!
        XCTAssertEqual(value!.first, "value")
        value = requestConfig?.kv!["key2"]!
        XCTAssertEqual(value!.first, "value2")
    }
    
    func testCategoryConfig() throws {
        let logger: Logger = Logger()
        let configParser: RequestConfigParser = RequestConfigParser(logger)
        
        // the kv cannot be an array, it must be a dictionary only
        var config = ["adUnits": [
                   [
                    "auId": "some auId", "c": ["value", "value2"]
                   ]
            ]
        ] as [String : Any]
        var requestConfig = configParser.parseConfig(config)
        XCTAssertEqual(requestConfig?.auId, "some auId")
        XCTAssertEqual(requestConfig?.c!.first, "value")
        XCTAssertEqual(requestConfig?.c![1], "value2")
        
        config = ["adUnits": [
                   [
                    "auId": "some auId", "c": "value"
                   ]
            ]
        ] as [String : Any]
        requestConfig = configParser.parseConfig(config)
        XCTAssertEqual(requestConfig?.auId, "some auId")
        XCTAssertEqual(requestConfig?.c!.first, "value")
    }
    
    func testToJson() throws {
        let logger: Logger = Logger()
        let configParser: RequestConfigParser = RequestConfigParser(logger)
        
        let requestConfig = AdRequest("some auId")
        requestConfig.userId("my global user id")
        requestConfig.sessionId = "my session id"
        requestConfig.useCookies(false)
        requestConfig.consentString("some consent string")
        requestConfig.width("100")
        requestConfig.height("200")
        requestConfig.category("cat1")
        requestConfig.category("cat2")
        requestConfig.globalParameter("gdpr", "1")
        requestConfig.keyValue("car", "holden")
        requestConfig.keyValue("car", "ford")
        requestConfig.keyValue("sport", "soccer")
        let json = configParser.toJson(requestConfig)
        let script = json.script.replacingOccurrences(of: "\n", with: "").replacingOccurrences(of: "  ", with: "")
        print(script)
        let expected = "<html> <head><script type=\"text/javascript\" src=\"https://cdn.adnuntius.com/adn.js\" async></script><style>body {margin-top: 0px;margin-left: 0px;margin-bottom: 0px;margin-right: 0px;}</style> </head> <body><div id=\"adn-some auId\" style=\"display:none\"></div><script type=\"text/javascript\">window.adn = window.adn || {}; adn.calls = adn.calls || [];adn.calls.push(function() {adn.request({env: 'production',sdk: 'ios:\(AdnuntiusSDK.sdk_version)',onPageLoad: adnSdkShim.onPageLoad,onImpressionResponse: adnSdkShim.onImpressionResponse,onVisible: adnSdkShim.onVisible,onViewable: adnSdkShim.onViewable,onRestyle: adnSdkShim.onRestyle,onError: adnSdkShim.onError,adUnits: [{auId: 'some auId', auH: '200', auW: '100', kv: {'car': ['holden', 'ford'], 'sport': ['soccer']}, c: ['cat1', 'cat2']}],userId: 'my global user id', sessionId: 'my session id', useCookies: false, consentString: 'some consent string', gdpr: '1'});});</script> </body></html>"
        XCTAssertEqual(expected, script)
    }
}
