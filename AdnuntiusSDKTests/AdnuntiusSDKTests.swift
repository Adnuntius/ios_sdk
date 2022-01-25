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
                    "auId": "some auId", "kv": ["key": ["value"]]
                   ]
            ],
            "useCookies": false
        ] as [String : Any]
        var jsonData = configParser.parseConfig(config)
        
        XCTAssertEqual(jsonData?.otherJson, "\"useCookies\":false")
        
        config = [
            "adUnits": [
                   [
                    "auId": "some auId", "kv": ["key": ["value"]]
                   ]
            ],
            "useCookies": true
        ] as [String : Any]
        jsonData = configParser.parseConfig(config)
        XCTAssertEqual(jsonData?.otherJson, "")
        
        config = [
            "userId": "my global user id",
            "adUnits": [
                   [
                    "auId": "some auId", "kv": ["key": ["value"]]
                   ]
            ],
            "useCookies": true
        ] as [String : Any]
        jsonData = configParser.parseConfig(config)
        XCTAssertEqual(jsonData?.otherJson, "\"userId\":\"my global user id\"")
        
        config = [
            "userId": "my global user id",
            "sessionId": "my session id",
            "adUnits": [
                   [
                    "auId": "some auId", "kv": ["key": ["value"]]
                   ]
            ],
            "useCookies": true
        ] as [String : Any]
        jsonData = configParser.parseConfig(config)
        XCTAssertEqual(jsonData?.otherJson, "\"sessionId\":\"my session id\",\"userId\":\"my global user id\"")

        config = [
            "userId": "my global user id",
            "sessionId": "my session id",
            "adUnits": [
                   [
                    "auId": "some auId", "kv": ["key": ["value"]]
                   ]
            ],
            "useCookies": false,
            "lpl": "my preview line item",
            "lpc": "my preview creative"
        ] as [String : Any]
        jsonData = configParser.parseConfig(config)
        XCTAssertEqual(jsonData?.otherJson, "\"sessionId\":\"my session id\",\"userId\":\"my global user id\",\"useCookies\":false")
        XCTAssertEqual("my preview line item", jsonData?.lp?.lpl)
        XCTAssertEqual("my preview creative", jsonData?.lp?.lpc)
        
        config = [
            "userId": "my global user id",
            "sessionId": "my session id",
            "adUnits": [
                   [
                    "auId": "some auId", "kv": ["key": ["value"]]
                   ]
            ],
            "useCookies": false,
            "lpl": "my preview line item"
        ] as [String : Any]
        jsonData = configParser.parseConfig(config)
        XCTAssertEqual(jsonData?.otherJson, "\"sessionId\":\"my session id\",\"userId\":\"my global user id\",\"useCookies\":false")
        
        // both lpl and lpc have to be provided for this feature to work
        XCTAssertNil(jsonData?.lp?.lpl)
        XCTAssertNil(jsonData?.lp?.lpc)
        
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
        jsonData = configParser.parseConfig(config)
        XCTAssertEqual(jsonData?.otherJson, "\"gdpr\":\"1\",\"sessionId\":\"my session id\",\"userId\":\"my global user id\",\"useCookies\":false")
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
        var jsonData = configParser.parseConfig(config)
        XCTAssertNil(jsonData)
        
        config = [
            "adUnits": [
                   [
                    "auId": "some auId", "kv": ["key": ["value", "value_2"], "key2": ["value2", "value2_2"]]
                   ]
            ]
        ] as [String : Any]
        jsonData = configParser.parseConfig(config)
        XCTAssertNotNil(jsonData?.adUnitsJson.range(of:"\"kv\":"))
        XCTAssertNotNil(jsonData?.adUnitsJson.range(of:"\"key2\":[\"value2\",\"value2_2\"]"))
        XCTAssertNotNil(jsonData?.adUnitsJson.range(of:"\"key\":[\"value\",\"value_2\"]"))
        
        config = [
            "adUnits": [
                   [
                    "auId": "some auId", "kv": ["key": "value", "key2": "value2"]
                   ]
            ]
        ] as [String : Any]
        jsonData = configParser.parseConfig(config)
        XCTAssertNotNil(jsonData?.adUnitsJson.range(of:"\"kv\":"))
        XCTAssertNotNil(jsonData?.adUnitsJson.range(of:"\"key2\":\"value2\""))
        XCTAssertNotNil(jsonData?.adUnitsJson.range(of:"\"key\":\"value\""))
    }
}
