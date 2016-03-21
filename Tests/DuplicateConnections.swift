//
//  DuplicateConnections.swift
//  Plug
//
//  Created by Ben Gottlieb on 3/20/16.
//  Copyright © 2016 Stand Alone, inc. All rights reserved.
//

import XCTest
import Plug
import Gulliver

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
		let channel = Plug.Channel.defaultChannel
		let request1 = Plug.request(.GET, URL: "http://httpbin.org/get", parameters: nil, channel: channel)
		let request2 = Plug.request(.GET, URL: "http://httpbin.org/get", parameters: nil, channel: channel)
		
		request1.start()
		request2.start()
		
		XCTAssert(channel.count == 1, "Failed to detect duplicate connection")
		
    }


}
