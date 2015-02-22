//
//  Plug_Tests.swift
//  Plug Tests
//
//  Created by Ben Gottlieb on 2/9/15.
//  Copyright (c) 2015 Stand Alone, inc. All rights reserved.
//

import UIKit
import XCTest
import Plug

class Plug_Tests: XCTestCase {
    
    override func setUp() {
        super.setUp()
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }
    
    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        super.tearDown()
    }
    
    func testExample() {
		let expectation = expectationWithDescription("GET")
		var url = "http://httpbin.org/get"
		var params: Plug.Parameters = .None
		
		var connection = Plug.request(method: .GET, URL: url, parameters: params)
			
		connection.completion({ (data) in
			var str = NSString(data: data, encoding: NSUTF8StringEncoding)
				println("Data: \(connection)")
				expectation.fulfill()

				XCTAssertFalse(NetworkActivityIndicator.isVisible, "Activity indicator not set to hidden");
			}).error({error in
				println("Got error: \(error)")
				expectation.fulfill()
				
				XCTAssertFalse(NetworkActivityIndicator.isVisible, "Activity indicator not set to hidden");
		})
		
		println("\(connection)")

		waitForExpectationsWithTimeout(10) { (error) in
			
		}

		XCTAssert(true, "Pass")
    }
    
    func testPerformanceExample() {
        // This is an example of a performance test case.
        self.measureBlock() {
            // Put the code you want to measure the time of here.
        }
    }
    
}
