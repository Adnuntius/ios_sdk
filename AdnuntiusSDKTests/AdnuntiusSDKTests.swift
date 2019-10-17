//
//  AdnuntiusSDKTests.swift
//  AdnuntiusSDKTests
//
//  Created by Adnuntius Australia on 30/8/19.
//  Copyright (c) 2019 Adnuntius AS.  All rights reserved.
//
import XCTest
@testable import AdnuntiusSDK

class AdnuntiusSDKTests: XCTestCase {
    override func setUp() {
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }

    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
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
