//
//  DuplicateConnections.swift
//  Plug
//
//  Created by Ben Gottlieb on 3/20/16.
//  Copyright © 2016 Stand Alone, inc. All rights reserved.
//

import XCTest
@testable import Plug

class DuplicateConnections: XCTestCase {

    override func setUp() {
        super.setUp()
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }
    
    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        super.tearDown()
    }

    func testDupes() {
		let expectation = expectationWithDescription("Duplicate Request Test")
		let channel = Plug.Channel.defaultChannel
		let request1 = Plug.request(.GET, URL: "http://httpbin.org/get", parameters: nil, channel: channel)
		let request2 = Plug.request(.GET, URL: "http://httpbin.org/get", parameters: nil, channel: channel)
		
		request1.tag = 1
		request2.tag = 2
		
		request1.start()
		request2.completion { request, data in
			XCTAssert(request.superconnection == request1, "Second request did not have first as its superconnection")
			expectation.fulfill()
		}.start()
		
		waitForExpectationsWithTimeout(20) { (error) in
			XCTAssert(error == nil, "Failed to complete duplicate downloads")
		}
		
    }


}
