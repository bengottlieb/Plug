//
//  JSON.swift
//  Plug
//
//  Created by Ben Gottlieb on 2/22/15.
//  Copyright (c) 2015 Stand Alone, inc. All rights reserved.
//

import Foundation

public protocol JSONObject {
	var JSONString: String? { get }
}

extension NSString: JSONObject {
	public var JSONString: String? { return self }
}

extension NSData: JSONObject {
	public var JSONString: String? { return self.base64EncodedStringWithOptions(nil) }
}

extension NSNumber: JSONObject {
	public var JSONString: String? { return self.description }
}

extension Bool: JSONObject {
	public var JSONString: String? { return self ? "true" : "false" }
}

extension NSDictionary: JSONObject {
	public var JSONString: String? {
		var error: NSError?
		
		if let data = NSJSONSerialization.dataWithJSONObject(self, options: .PrettyPrinted, error: &error) {
			if error != nil { println("Error \(error) while JSON encoding \(self)") }
			return NSString(data: data, encoding: NSUTF8StringEncoding)
		}
		return nil
	}
}

extension NSArray: JSONObject {
	public var JSONString: String? {
		var error: NSError?
		
		if let data = NSJSONSerialization.dataWithJSONObject(self, options: .PrettyPrinted, error: &error) {
			if error != nil { println("Error \(error) while JSON encoding \(self)") }
			return NSString(data: data, encoding: NSUTF8StringEncoding)
		}

		return nil
	}
}

