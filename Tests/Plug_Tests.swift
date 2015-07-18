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

var persistentDelegate = Plug_TestPersistentDelegate()

class Plug_TestPersistentDelegate: PlugPersistentDelegate {
	var persistenceInfo = Plug.PersistenceInfo(objectKey: "test")
	var expectations: [XCTestExpectation] = []
	
	func connectionCompleted(connection: Plug.Connection, info: Plug.PersistenceInfo?) {
		if self.expectations.count > 0 {
			let expectation = self.expectations[0]
			expectation.fulfill()
			self.expectations.removeAtIndex(0)
		}
		
		connection.log()
		
		if self.expectations.count == 0 {
			XCTAssertFalse(NetworkActivityIndicator.isVisible, "Activity indicator not set to hidden");
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
    
    func testGET2() {
		let expectation = expectationWithDescription("GET")
		let url = "http://httpbin.org/get"
		let params: Plug.Parameters = .None
		
		let connection = Plug.request(.GET, URL: url, parameters: params)
			
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
			
		}
		
		connection.log()
		connection.logErrorToFile("test label")
		XCTAssert(true, "Pass")
    }
	
	func testKeyAXS() {
		persistentDelegate.expectations.append(expectationWithDescription("GET"))
		let url = "http://axs-doorstep.rhcloud.com:80/api/v1/account/login.json"
		//url = "http://httpbin.org/get"
		let request = Plug.request(.GET, URL: url, parameters: .None, persistence: .Persistent(persistentDelegate.persistenceInfo))
		request.completion { data in
			request.log()
		}
		request.addHeader(.BasicAuthorization("utd_client", "Pr4d00rz"))
		request.addHeader(.Custom("login_email", "ben@standalone.com"))
		request.addHeader(.Custom("login_password", "doorlock"))

		request.start()
		waitForExpectationsWithTimeout(10) { (error) in
			
		}
	}
	
	func testPersistent2() {
		persistentDelegate.expectations.append(expectationWithDescription("GET"))
		let url = "http://httpbin.org/get"
		let params: Plug.Parameters = .None
		let headers = Plug.Headers([.Accept(["*/*"])])
		
		let connection = Plug.request(.GET, URL: url, parameters: params, persistence: .Persistent(persistentDelegate.persistenceInfo))
		connection.headers = headers
		let dict = connection.JSONRepresentation
		
		let json = dict.JSONString
		
		do {
			if let dict = try NSJSONSerialization.JSONObjectWithData(json!.dataUsingEncoding(NSUTF8StringEncoding, allowLossyConversion: false)!, options: []) as? NSDictionary {
				let replacement = Plug.Connection(JSONRepresentation: dict)
				
				replacement?.start()
			}
		} catch let error as NSError {
			print("Error while decoding JSON: \(error)")
		}
		
		waitForExpectationsWithTimeout(10) { (error) in
			
		}
	}
    
    func _testPerformanceExample() {
        // This is an example of a performance test case.
        self.measureBlock() {
            // Put the code you want to measure the time of here.
        }
    }
    
}
