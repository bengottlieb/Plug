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
	public var JSONString: String? { return (self as String) }
}

extension NSData: JSONObject {
	public var JSONString: String? { return self.base64EncodedStringWithOptions([]) }
}

extension NSNumber: JSONObject {
	public var JSONString: String? { return self.description }
}

extension Bool: JSONObject {
	public var JSONString: String? { return self ? "true" : "false" }
}

extension NSDictionary: JSONObject {
	public var JSONString: String? {
		do {
			let data = try NSJSONSerialization.dataWithJSONObject(self, options: .PrettyPrinted)
			return (NSString(data: data, encoding: NSUTF8StringEncoding) as? String) ?? ""
		} catch let error as NSError {
			print("error while deserializing a JSON object: \(error)")
		}
		return nil
	}
}

extension NSArray: JSONObject {
	public var JSONString: String? {
		do {
			let data = try NSJSONSerialization.dataWithJSONObject(self, options: .PrettyPrinted)
			return (NSString(data: data, encoding: NSUTF8StringEncoding) as? String) ?? ""
		} catch let error as NSError {
			print("error while deserializing a JSON object: \(error)")
		}

		return nil
	}
}

