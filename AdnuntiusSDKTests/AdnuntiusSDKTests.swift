//
//  Copyright (c) 2020 Adnuntius AS.  All rights reserved.
//

import XCTest
@testable import AdnuntiusSDK

class AdnuntiusSDKTests: XCTestCase {
    override func setUp() {
    }

    override func tearDown() {
    }

    func testAdConfig() {
        let config = AdConfig("0000000000023ae5")
        config.setSiteId("mysite")
        config.setHeight("100")
        config.setWidth("300")
        config.addCategory("sports")
        config.addCategory("casinos")
        config.addKeyValue("car", "toyota")
        config.addKeyValue("car", "ford")
        config.addKeyValue("sport", "football")
        let script = config.toJson()
        //print(script)
        XCTAssertTrue(script.contains("'c':"))
        XCTAssertTrue(script.contains("'kv':"))
    }
    
    func testAdConfigNoKvOrCategories() {
        let config = AdConfig("0000000000023ae5")
        config.setHeight("100")
        config.setWidth("300")
        let script = config.toJson()
        print(script)
        XCTAssertFalse(script.contains("'c':"))
        XCTAssertFalse(script.contains("'kv':"))
    }
}
