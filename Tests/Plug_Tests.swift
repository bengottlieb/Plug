//
//  Plug_Tests.swift
//  Plug Tests
//
//  Created by Ben Gottlieb on 2/9/15.
//  Copyright (c) 2015 Stand Alone, inc. All rights reserved.
//

import UIKit
import XCTest
@testable import Plug

var persistentDelegate = Plug_TestPersistentDelegate()

class Plug_TestPersistentDelegate: PlugPersistentDelegate {
	var persistenceInfo = Plug.PersistenceInfo(objectKey: "test")
	var expectations: [XCTestExpectation] = []
	
	func connectionCompleted(connection: Connection, info: Plug.PersistenceInfo?) {
		if info == nil { return }
		if self.expectations.count > 0 {
			let expectation = self.expectations[0]
			expectation.fulfill()
			self.expectations.removeAtIndex(0)
		}
		
		connection.log()
		
		if self.expectations.count == 0 {
		//	XCTAssertFalse(NetworkActivityIndicator.isVisible, "Activity indicator not set to hidden");
		}
	}
	
	init() {		
		Plug.PersistenceManager.defaultManager.registerObject(self)
	}
}

class Plug_Tests: XCTestCase {
    
    override func setUp() {
        super.setUp()
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }
    
    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        super.tearDown()
    }
	
	func testDownloadToFile() {
		let url = "https://www.wikipedia.org/portal/wikipedia.org/assets/img/Wikipedia-logo-v2@2x.png"
		let expectation = expectationWithDescription("GET download to file")
		let connection = Plug.request(.GET, URL: url)
		connection.destinationFileURL = Plug.instance.generateTemporaryFileURL()
		print("Downloading to \(connection.destinationFileURL!)")
		connection.completion { connection, data in
			print("got \(data.length) bytes")
			XCTAssert(data.length == 34245, "Failed to download correct file bytes: (expected 34245, got \(data.length)")
			
			expectation.fulfill()
		}
		waitForExpectationsWithTimeout(20) { (error) in
			XCTAssert(error == nil, "Failed to download to file")
		}
		
	}
	
    func testGET2() {
		let expectation = expectationWithDescription("GET")
		let url = "http://httpbin.org/get"
		let params: Plug.Parameters = .None
		var completionCount = 0
		
		let connection = Plug.request(.GET, URL: url, parameters: params).completion { c, d in
			completionCount += 1;
			if completionCount == 2 { expectation.fulfill() }
		}
		let connection2 = Plug.request(.GET, URL: url, parameters: params).completion { c, d in
			completionCount += 1;
			if completionCount == 2 { expectation.fulfill() }
		}
		XCTAssert(connection == connection2, "Identical connections should be identical")

		connection.completion({ (conn, data) in
			let str = NSString(data: data.data, encoding: NSUTF8StringEncoding)
			print("Data: \(str)")

			XCTAssert(Plug.activityUsageCount == 0, "Activity indicator not set to hidden");
			print("Block3")
		}).error({conn, error in
			print("Got error: \(error)")
			
			XCTAssert(Plug.activityUsageCount == 0, "Activity indicator not set to hidden");
			print("Block4")
		})
		
		print("\(connection.log())")
		connection.start()

		waitForExpectationsWithTimeout(10) { (error) in
			XCTAssert(completionCount == 2, "Failed to complete one or more connections")
		}
		
		connection.log()
		connection.logErrorToFile("test label")
		XCTAssert(true, "Pass")
    }
	
	func testPersistent2() {
		let expectation = expectationWithDescription("GET_Persistent")
//		persistentDelegate.expectations.append()
		let url = "http://httpbin.org/get"
		let params: Plug.Parameters = .None
		let headers = Plug.Headers([.Accept(["*/*"])])
		
		let connection = Plug.request(.GET, URL: url, parameters: params, persistence: .Persistent(persistentDelegate.persistenceInfo))
		connection.headers = headers
		let dict = connection.JSONRepresentation
		
		let json = dict.JSONString
		connection.cancel()
		
		do {
			if let dict = try NSJSONSerialization.JSONObjectWithData(json!.dataUsingEncoding(NSUTF8StringEncoding, allowLossyConversion: false)!, options: []) as? NSDictionary {
				let replacement = Connection(JSONRepresentation: dict)
				
				replacement?.completion { req, data in
					expectation.fulfill()
				}.start()
			}
		} catch let error as NSError {
			print("Error while decoding JSON: \(error)")
		}
		
		waitForExpectationsWithTimeout(1000) { (error) in
			
		}
	}
    
    func _testPerformanceExample() {
        // This is an example of a performance test case.
        self.measureBlock() {
            // Put the code you want to measure the time of here.
        }
    }
	
	func testTimeout() {
		let expectation = expectationWithDescription("GET")
		let url = "http://128.0.0.1/"
		
		Plug.instance.timeout = 5
		let request = Plug.request(.GET, URL: url)
		
		request.error { req, error in
			XCTAssert(error.isTimeoutError, "Should have timed out")
			expectation.fulfill()
		}
		
		request.start()
		
		waitForExpectationsWithTimeout(10) { (error) in
			
		}
	}
	
	let largeURL = "http://mirror.internode.on.net/pub/test/50meg.test"
	var lastPercent = 0.0
	func testTimeoutLargeDownload() {
		let expectation = expectationWithDescription("GET")
		let url = largeURL
		
		Plug.instance.timeout = 10
		let request = Plug.request(.GET, URL: url)
		
		request.error { req, error in
			XCTAssert(!error.isTimeoutError, "Should not have timed out")
			expectation.fulfill()
		}
		
		request.progress { req, percent in
			if percent > (self.lastPercent + 0.01) {
				print("Got \(percent * 100.0) %")
				self.lastPercent = percent
			}
		}
		
		request.completion { req, data in
			print("Downloaded \(data.length)")
			expectation.fulfill()
		}
		
		request.start()
		
		waitForExpectationsWithTimeout(200) { (error) in
			
		}
	}
	
}
