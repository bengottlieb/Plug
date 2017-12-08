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
			self.expectations.remove(at: 0)
		}
		
		connection.log()
		
		if self.expectations.count == 0 {
		//	XCTAssertFalse(NetworkActivityIndicator.isVisible, "Activity indicator not set to hidden");
		}
	}
	
	init() {		
		Plug.PersistenceManager.defaultManager.register(self)
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
		let expect = expectation(description: "GET download to file")
		let connection = Plug.request(method: .GET, url: url)
		connection.destinationFileURL = Plug.instance.generateTemporaryFileURL()
		print("Downloading to \(connection.destinationFileURL!)")
		connection.completion { connection, data in
			print("got \(data.length) bytes")
			XCTAssert(data.length == 35460, "Failed to download correct file bytes: (expected 35460, got \(data.length)")
			
			expect.fulfill()
		}
		waitForExpectations(timeout: 20) { (error) in
			XCTAssert(error == nil, "Failed to download to file")
		}
		
	}
	
    func testGET2() {
		let expect = expectation(description: "GET")
		let url = "http://httpbin.org/get"
		let params: Plug.Parameters = .none
		var completionCount = 0
		
		let connection = Plug.request(method: .GET, url: url, parameters: params).completion { c, d in
			completionCount += 1;
			if completionCount == 2 { expect.fulfill() }
		}
		let connection2 = Plug.request(method: .GET, url: url, parameters: params).completion { c, d in
			completionCount += 1;
			if completionCount == 2 { expect.fulfill() }
		}
		XCTAssert(connection == connection2, "Identical connections should be identical")

		connection.completion(completion: { (conn, data) in
			let str = String(data: data.data, encoding: .utf8)
			print("Data: \(str)")

			//XCTAssert(Plug.activityUsageCount == 0, "Activity indicator not set to hidden");
			print("Block3")
		}).error(completion: {conn, error in
			print("Got error: \(error)")
			
			//XCTAssert(Plug.activityUsageCount == 0, "Activity indicator not set to hidden");
			print("Block4")
		})
		
		print("\(connection.log())")
		connection.start()

		waitForExpectations(timeout: 10) { (error) in
			XCTAssert(completionCount == 2, "Failed to complete one or more connections")
		}
		
		connection.log()
		connection.logErrorToFile(label: "test label")
		XCTAssert(true, "Pass")
    }
	
//	func testPersistent2() {
//		let expect = expectation(description: "GET_Persistent")
////		persistentDelegate.expectations.append()
//		let url = "http://httpbin.org/get"
//		let params: Plug.Parameters = .none
//		let headers = Plug.Headers([.accept(["*/*"])])
//
//		let connection = Plug.request(method: .GET, url: url, parameters: params, persistence: .persistent(persistentDelegate.persistenceInfo))
//		connection.headers = headers
//		let dict: JSONDictionary = connection.JSONRepresentation as? NSDictionary
//
//		guard let json = dict.JSONData else { return }
//		connection.cancel()
//
//		do {
//			if let dict = try JSONSerialization.jsonObject(with: json, options: []) as? NSDictionary {
//				let replacement = Connection(JSONRepresentation: dict)
//
//				replacement?.completion { req, data in
//					expect.fulfill()
//				}.start()
//			}
//		} catch let error as Error {
//			print("Error while decoding JSON: \(error)")
//		}
//
//		waitForExpectations(timeout: 1000) { (error) in
//
//		}
//	}
	
    func _testPerformanceExample() {
        // This is an example of a performance test case.
        self.measure() {
            // Put the code you want to measure the time of here.
        }
    }
	
	func testTimeout() {
		let expect = expectation(description: "GET")
		let url = "http://128.0.0.1/"
		
		Plug.instance.timeout = 5
		let request = Plug.request(method: .GET, url: url)
		
		request.error { req, error in
			XCTAssert(error.isTimeoutError, "Should have timed out")
			expect.fulfill()
		}
		
		request.start()
		
		waitForExpectations(timeout: 10) { (error) in
			
		}
	}
	
	let largeURL = "http://mirror.internode.on.net/pub/test/50meg.test"
	var lastPercent = 0.0
	func testTimeoutLargeDownload() {
		let expect = expectation(description: "GET")
		let url = largeURL
		
		Plug.instance.timeout = 10
		let request = Plug.request(method: .GET, url: url)
		
		request.error { req, error in
			XCTAssert(!error.isTimeoutError, "Should not have timed out")
			expect.fulfill()
		}
		
		request.progress { req, percent in
			if percent > (self.lastPercent + 0.01) {
				print("Got \(percent * 100.0) %")
				self.lastPercent = percent
			}
		}
		
		request.completion { req, data in
			print("Downloaded \(data.length)")
			expect.fulfill()
		}
		
		request.start()
		
		waitForExpectations(timeout: 200) { (error) in
			
		}
	}
	
}
