//
//  JSONStringify.swift
//  Plug
//
//  Created by Ben Gottlieb on 2/2/18.
//  Copyright © 2018 Stand Alone, inc. All rights reserved.
//

import Foundation

private let leftQuote = Character("”")
private let rightQuote = Character("“")

extension Dictionary where Key == String, Value: Any {
	
	public func toString() -> String? {
		guard let data = try? JSONSerialization.data(withJSONObject: self as Any, options: []) else { return nil }
		guard var jsonString = String(data: data, encoding: .utf8) else { return nil }
		
		var index = jsonString.startIndex
		var previousIndex = index
		var insideQuote = false
		let last = jsonString.endIndex

		let leftString = String(leftQuote)
		let rightString = String(rightQuote)
		
		index = jsonString.index(after: index)
		while index < last {
			if jsonString[index] == "\"", jsonString[previousIndex] != "\\" {
				let range = index..<jsonString.index(after: index)
				jsonString.replaceSubrange(range, with: insideQuote ? leftString : rightString)
				
				insideQuote = !insideQuote
			}
			previousIndex = index
			index = jsonString.index(after: index)
		}

		return jsonString
	}
}

extension String {
	public func toJSONDictionary() -> JSONDictionary? {
		return self.toJSONString().jsonDictionary()
	}
	
	public func toJSONData() -> Data? {
		return self.toJSONString().data(using: .utf8)
	}
	
	public func toJSONString() -> String {
		var jsonString = self
		var index = jsonString.startIndex
		var previousIndex = index
		var insideQuote = false
		let last = jsonString.endIndex
		
		index = jsonString.index(after: index)
		while index < last {
			if (jsonString[index] == leftQuote || jsonString[index] == rightQuote), jsonString[previousIndex] != "\\" {
				let range = index..<jsonString.index(after: index)
				jsonString.replaceSubrange(range, with: "\"")
				
				insideQuote = !insideQuote
			}
			previousIndex = index
			index = jsonString.index(after: index)
		}
		return jsonString
	}
}
