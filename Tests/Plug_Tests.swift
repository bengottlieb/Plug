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
import Gulliver

var persistentDelegate = Plug_TestPersistentDelegate()

class Plug_TestPersistentDelegate: PlugPersistentDelegate {
	var persistenceInfo = Plug.PersistenceInfo(objectKey: "test")
	var expectations: [XCTestExpectation] = []
	
	func connectionCompleted(connection: Plug.Connection, info: Plug.PersistenceInfo?) {
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

class JSONTests: XCTestCase {
	func testPathExtraction() {
		let url = NSBundle(forClass: self.dynamicType).URLForResource("json_sample_1", withExtension: "json")!
		let data = NSData(contentsOfURL: url)!
		let json = data.jsonDictionary()!
		let result = json[path: "glossary.GlossDiv.GlossList.GlossEntry.Flavors[0]"] as! String
		XCTAssert(result == "GML", "Failed to extract JSON")
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
    
    func testGET2() {
		let expectation = expectationWithDescription("GET")
		let url = "http://httpbin.org/get"
		let params: Plug.Parameters = .None
		var completionCount = 0
		
		let connection = Plug.request(.GET, URL: url, parameters: params).completion { c, d in completionCount++ }
		let connection2 = Plug.request(.GET, URL: url, parameters: params).completion { c, d in completionCount++ }
		XCTAssert(connection == connection2, "Identical connections should be identical")

		connection.completion({ (conn, data) in
			let str = NSString(data: data, encoding: NSUTF8StringEncoding)
			print("Data: \(connection): \(str)")
			expectation.fulfill()

			XCTAssertFalse(NetworkActivityIndicator.isVisible, "Activity indicator not set to hidden");
		}).error({conn, error in
			print("Got error: \(error)")
			expectation.fulfill()
			
			XCTAssertFalse(NetworkActivityIndicator.isVisible, "Activity indicator not set to hidden");
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
				let replacement = Plug.Connection(JSONRepresentation: dict)
				
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
			XCTAssert(error.isTimeout, "Should have timed out")
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
			XCTAssert(!error.isTimeout, "Should not have timed out")
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
