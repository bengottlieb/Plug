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
	enum TestEnum: String { case value1 }
	func testValidation() {
		var dict: JSONDictionary = ["a": "b"]
		let test: Int? = 3

		XCTAssert(dict.validateJSON(), "Validation should have succeeded")

		dict["c"] = test
		dict["d"] = URL(string: "about:blank")!
		XCTAssert(!dict.validateJSON(), "Validation should have failed")
	}
	
//	func testPathExtraction() {
//		let url = Bundle(for: type(of: self)).url(forResource: "json_sample_1", withExtension: "json")!
//		let data = try! Data(contentsOf: url)
//		let json = data.jsonDictionary() as? NSDictionary
//		let result = json?[path: "glossary.GlossDiv.GlossList.GlossEntry.Flavors[0]"] as! String
//		XCTAssert(result == "GML", "Failed to extract JSON")
//	}

	func testJSONDictionaryDownload() {
		let expect = expectation(description: "JSONDictionary")
		let url = URL(string: "http://jsonview.com/example.json")!
		
		Connection(url: url)!.fetchJSON().then { _ in
			expect.fulfill()
		}
		
		waitForExpectations(timeout: 10) { (error) in
			XCTAssert(error == nil, "Failed to download JSON Dictionary")
		}
		
	}

	var sharedExpectation: XCTestExpectation?
	
//	func testJSONArrayDownload() {
//		self.sharedExpectation = expectation(description: "JSONDictionary")
//		let url = URL(string: "http://jsonview.com/example.json")!
//		
//		Connection(url: url)!.fetchJSON().then { _ in
//				self.sharedExpectation?.fulfill()
//				self.sharedExpectation = nil
//			}.error { request, error in
//				XCTAssertTrue(false, "Was expecting an array")
//			}
//		
//		
//		waitForExpectations(timeout: 10) { (error) in
//			XCTAssert(error == nil, "Failed to download JSON Dictionary")
//		}
//		
//	}

}
