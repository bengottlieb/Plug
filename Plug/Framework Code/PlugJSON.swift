//
//  JSON.swift
//  Plug
//
//  Created by Ben Gottlieb on 2/22/15.
//  Copyright (c) 2015 Stand Alone, inc. All rights reserved.
//

import Foundation


public typealias JSONArray = [AnyObject]
public typealias JSONDictionary = [String : AnyObject]

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

extension JSONObject {
	func log() {
		print("\(self.JSONString)")
	}
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

public extension NSData {
	public func jsonDictionary(options: NSJSONReadingOptions = []) -> JSONDictionary? {
		do {
			let dict = try NSJSONSerialization.JSONObjectWithData(self, options: options) as? JSONDictionary
			return dict
		} catch let error {
			print("Error while parsing JSON Dictionary: \(error)")
		}
		return nil
	}
	
	public func jsonArray(options: NSJSONReadingOptions = []) -> JSONArray? {
		do {
			let dict = try NSJSONSerialization.JSONObjectWithData(self, options: options) as? JSONArray
			return dict
		} catch let error {
			print("Error while parsing JSON Array: \(error)")
		}
		return nil
	}
}

public protocol JSONKey {
	func toString() -> String
}
extension String: JSONKey {
	public func toString() -> String { return self }
}

let JSONSeparatorsCharacterSet = NSCharacterSet(charactersInString: ".[]")
extension Dictionary where Key: StringLiteralConvertible, Value: AnyObject {
//	public func path(path: String) -> AnyObject? {
	public subscript(path path: String) -> AnyObject? {
		let components = path.componentsSeparatedByCharactersInSet(JSONSeparatorsCharacterSet)
		return self[components: components]
	}
	
	public subscript(components comps: [String]) -> AnyObject? {
		guard let dict = (self as? AnyObject) as? [String: AnyObject] else { return nil }
		var components = comps
		
		while components.first == "" { components.removeAtIndex(0) }
		guard components.count > 0 else { return nil }
		
		let key = components[0]
		if Int(key) != nil { return nil }
		components.removeAtIndex(0)
		guard components.count > 0 else { return dict[key] }
		
		if Int(components[0]) != nil {
			guard let array = dict[key] as? JSONArray else { return nil }
			return array[components: components]
		} else {
			guard let dict = dict[key] as? JSONDictionary else { return nil }
			return dict[components: components]
		}
	}

	public var JSONString: String? {
		do {
			let data = try NSJSONSerialization.dataWithJSONObject(self as! AnyObject, options: .PrettyPrinted)
			return (NSString(data: data, encoding: NSUTF8StringEncoding) as? String) ?? ""
		} catch let error as NSError {
			print("error while deserializing a JSON object: \(error)")
		}
		
		return nil
	}
}

extension Array {
	public subscript(path: String) -> AnyObject? {
		let components = path.componentsSeparatedByCharactersInSet(JSONSeparatorsCharacterSet)
		return self[components: components]
	}
	
	public subscript(components comps: [String]) -> AnyObject? {
		var components = comps
		
		while components.first == "" { components.removeAtIndex(0) }
		guard components.count > 0 else { return nil }
		
		guard let index = Int(components[0]) else { return nil }
		components.removeAtIndex(0)
		while components.first == "" { components.removeAtIndex(0) }
		guard components.count > 0 else { return self[index] as? AnyObject }
		
		if Int(components[0]) != nil {
			guard let array = self[index] as? JSONArray else { return nil }
			return array[components: components]
		} else {
			guard let dict = self[index] as? JSONDictionary else { return nil }
			return dict[components: components]
		}
	}

	public var JSONString: String? {
		do {
			let data = try NSJSONSerialization.dataWithJSONObject((self as! AnyObject) as! [AnyObject], options: .PrettyPrinted)
			return (NSString(data: data, encoding: NSUTF8StringEncoding) as? String) ?? ""
		} catch let error as NSError {
			print("error while deserializing a JSON object: \(error)")
		}
		
		return nil
	}
	
	var description: String { return self.JSONString ?? "" }
}