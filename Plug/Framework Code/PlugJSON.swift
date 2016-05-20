//
//  JSON.swift
//  Plug
//
//  Created by Ben Gottlieb on 2/22/15.
//  Copyright (c) 2015 Stand Alone, inc. All rights reserved.
//

import Foundation

extension Dictionary where Key: StringLiteralConvertible, Value: AnyObject {
	
}

public protocol JSONContainer {}			//either a JSONArray or JSONDictionary

public typealias JSONArray = [AnyObject]
public typealias JSONDictionary = [String : AnyObject]

public protocol JSONObject {
	var JSONString: String? { get }
	var JSONData: NSData? { get }
}

public protocol JSONInitable {
	init?(json: JSONDictionary)
}

public protocol JSONConvertible {
	var json: JSONDictionary? { get }
}

extension NSString: JSONObject {
	public var JSONString: String? { return (self as String) }
	public var JSONData: NSData? { return self.dataUsingEncoding(NSUTF8StringEncoding) }
}

extension NSData: JSONObject {
	public var JSONString: String? { return self.base64EncodedStringWithOptions([]) }
	public var JSONData: NSData? { return self.base64EncodedStringWithOptions([]).dataUsingEncoding(NSUTF8StringEncoding) }
}

extension NSNumber: JSONObject {
	public var JSONString: String? { return self.description }
	public var JSONData: NSData? { return self.description.dataUsingEncoding(NSUTF8StringEncoding) }
}

extension Bool: JSONObject {
	public var JSONString: String? { return self ? "true" : "false" }
	public var JSONData: NSData? { return self.JSONString?.dataUsingEncoding(NSUTF8StringEncoding) }
}

extension JSONObject {
	public func log() {
		if let string = self.JSONString {
			print("\(string)")
		} else {
			print("\(self)")
		}
	}
	
	public var JSONString: String? {
		return String(data: self.JSONData ?? NSData(), encoding: NSUTF8StringEncoding) ?? ""
	}
}

extension Dictionary: JSONContainer {}
extension Array: JSONContainer {}

extension NSDictionary: JSONObject {
	public var JSONData: NSData? {
		do {
			return try NSJSONSerialization.dataWithJSONObject(self, options: .PrettyPrinted)
		} catch let error {
			print("Unable to convert \(self) to JSON: \(error)")
			return nil
		}
	}
	
}

extension NSArray: JSONObject {
	public var JSONData: NSData? {
		do {
			return try NSJSONSerialization.dataWithJSONObject(self, options: .PrettyPrinted)
		} catch let error {
			print("Unable to convert \(self) to JSON: \(error)")
			return nil
		}
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

let JSONSeparatorsCharacterSet = NSCharacterSet(charactersInString: ".[]")
extension Dictionary where Key: StringLiteralConvertible, Value: AnyObject {
//	public func path(path: String) -> AnyObject? {
	public subscript(path path: String) -> AnyObject? {
		let components = path.componentsSeparatedByCharactersInSet(JSONSeparatorsCharacterSet)
		return self[components: components]
	}
	
	public subscript(int int: String) -> Int? {
		let components = int.componentsSeparatedByCharactersInSet(JSONSeparatorsCharacterSet)
		if let integer = self[components: components] as? Int { return integer }
		if let str = self[components: components] as? String { return Int(str) }
		return nil
	}
	
	public subscript(components comps: [String]) -> AnyObject? {
		guard let dict = (self as? AnyObject) as? [String: AnyObject] else { return nil }
		var components = comps
		
		while components.first == "" { components.removeAtIndex(0) }
		guard components.count > 0 else { return nil }
		
		let key = components[0]

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

extension Dictionary: JSONObject {
	public var JSONString: String? {
		if let dict = (self as? AnyObject) as? NSDictionary {
			return dict.JSONString
		}
		return nil
	}
	public var JSONData: NSData? { return self.JSONString?.dataUsingEncoding(NSUTF8StringEncoding) }
}

extension Array: JSONObject {
	public subscript(path: String) -> AnyObject? {
		let components = path.componentsSeparatedByCharactersInSet(JSONSeparatorsCharacterSet)
		return self[components: components]
	}
	
	public subscript(int int: String) -> Int? {
		let components = int.componentsSeparatedByCharactersInSet(JSONSeparatorsCharacterSet)
		if let integer = self[components: components] as? Int { return integer }
		if let str = self[components: components] as? String { return Int(str) }
		return nil
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
			guard index < self.count, let dict = self[index] as? JSONDictionary else { return nil }
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
	
	public var JSONData: NSData? { return self.JSONString?.dataUsingEncoding(NSUTF8StringEncoding) }
	var description: String { return self.JSONString ?? "" }
}