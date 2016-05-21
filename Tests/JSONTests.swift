//
//  JSONTests.swift
//  Plug
//
//  Created by Ben Gottlieb on 5/21/16.
//  Copyright © 2016 Stand Alone, inc. All rights reserved.
//

import XCTest
@testable import Plug

class JSONTests: XCTestCase {
	func testPathExtraction() {
		let url = NSBundle(forClass: self.dynamicType).URLForResource("json_sample_1", withExtension: "json")!
		let data = NSData(contentsOfURL: url)!
		let json = data.jsonDictionary()!
		let result = json[path: "glossary.GlossDiv.GlossList.GlossEntry.Flavors[0]"] as! String
		XCTAssert(result == "GML", "Failed to extract JSON")
	}

	func testJSONDictionaryDownload() {
		let expectation = expectationWithDescription("JSONDictionary")
		let url = NSURL(string: "http://jsonview.com/example.json")!
		
		JSONConnection(URL: url)?.completion { (request: Connection, json: JSONDictionary) in
			expectation.fulfill()
			}.start()
		
		waitForExpectationsWithTimeout(10) { (error) in
			XCTAssert(error == nil, "Failed to download JSON Dictionary")
		}
		
	}

	func testJSONArrayDownload() {
		let expectation = expectationWithDescription("JSONDictionary")
		let url = NSURL(string: "http://jsonview.com/example.json")!
		
		JSONConnection(URL: url)?.completion { (request: Connection, json: JSONArray) in
				XCTAssert(false, "Was expecting an array")
			}.error { request, error in
				expectation.fulfill()
		}
		
		
		waitForExpectationsWithTimeout(10) { (error) in
			XCTAssert(error == nil, "Failed to download JSON Dictionary")
		}
		
	}

}
