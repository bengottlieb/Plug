//
//  CodableTests.swift
//  Plug Tests
//
//  Created by Ben Gottlieb on 12/8/17.
//  Copyright © 2017 Stand Alone, inc. All rights reserved.
//

import XCTest
@testable import Plug

class CodableTests: XCTestCase {
    
    override func setUp() {
        super.setUp()
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }
    
    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        super.tearDown()
    }
    
    func testExample() {
		let conn = Connection(method: .POST, url: "https://standalone.com", parameters: .url(["Test": "Value"]))!
		let encoded = try! JSONEncoder().encode(conn)
		let decoded = try! JSONDecoder().decode(Connection.self, from: encoded)
		
		XCTAssert(conn.method == decoded.method, "Method failed to decode")
		XCTAssert(conn.url == decoded.url, "URL failed to decode")
		XCTAssert(conn.parameters == decoded.parameters, "parameters failed to decode")
    }
    
    func testPerformanceExample() {
        // This is an example of a performance test case.
        self.measure {
            // Put the code you want to measure the time of here.
        }
    }
    
}
