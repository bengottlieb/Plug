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
		let url = Bundle(for: type(of: self)).url(forResource: "json_sample_1", withExtension: "json")!
		let data = try! Data(contentsOf: url)
		let json = data.jsonDictionary()!
		let result = json[path: "glossary.GlossDiv.GlossList.GlossEntry.Flavors[0]"] as! String
		XCTAssert(result == "GML", "Failed to extract JSON")
	}

	func testJSONDictionaryDownload() {
		let expect = expectation(description: "JSONDictionary")
		let url = URL(string: "http://jsonview.com/example.json")!
		
		JSONConnection(url: url)?.completion { (request: Connection, json: JSONDictionary) in
			expect.fulfill()
			}.start()
		
		waitForExpectations(timeout: 10) { (error) in
			XCTAssert(error == nil, "Failed to download JSON Dictionary")
		}
		
	}

	var sharedExpectation: XCTestExpectation?
	
	func testJSONArrayDownload() {
		self.sharedExpectation = expectation(description: "JSONDictionary")
		let url = URL(string: "http://jsonview.com/example.json")!
		
		JSONConnection(url: url)?.completion { (request: Connection, json: JSONArray) in
				XCTAssert(false, "Was expecting an array")
			}.error { request, error in
				self.sharedExpectation?.fulfill()
				self.sharedExpectation = nil
		}
		
		
		waitForExpectations(timeout: 10) { (error) in
			XCTAssert(error == nil, "Failed to download JSON Dictionary")
		}
		
	}

}
