//
//  JSON.swift
//  Plug
//
//  Created by Ben Gottlieb on 2/22/15.
//  Copyright (c) 2015 Stand Alone, inc. All rights reserved.
//

import Foundation

func ValidateJSON(object value: Any) -> Bool {
	if let dict = value as? JSONDictionary {
		if dict.validateJSON() { return true }
	}
	
	if let array = value as? JSONArray {
		if array.validateJSON() { return true }
	}
	
	if value is Int || value is String || value is JSONArray || value is Bool || value is Float || value is Double { return true }
	
	print("▽▽▽▽▽▽▽▽▽▽▽▽▽▽▽▽▽▽▽▽▽▽▽▽▽▽▽▽▽▽▽▽▽▽▽▽▽▽▽▽▽▽▽▽▽▽▽▽▽▽▽▽▽▽▽▽▽▽▽▽▽▽▽▽▽▽▽")
	print("Illegal value \(type(of: value)):  \(value)")
	print("△△△△△△△△△△△△△△△△△△△△△△△△△△△△△△△△△△△△△△△△△△△△△△△△△△△△△△△△△△△△△△△△△△△")
	
	return false
}

public extension Dictionary {
	@discardableResult public func validateJSON() -> Bool {
		for (key, value) in self {
			if !(key is String) {
				print("Illegal key: \(key)")
				return false
			}
			
			if !ValidateJSON(object: value) { return false }
		}
		return true
	}
}

public extension NSDictionary {
	@discardableResult public func validateJSON() -> Bool {
		for (key, value) in self {
			if !(key is String) {
				print("Illegal key: \(key)")
				return false
			}
			
			if !ValidateJSON(object: value) { return false }
		}
		return true
	}
}

public extension Array {
	@discardableResult public func validateJSON() -> Bool {
		for value in self {
			if !ValidateJSON(object: value) { return false }
		}
		
		return true
	}
}

public extension NSArray {
	@discardableResult public func validateJSON() -> Bool {
		for value in self {
			if !ValidateJSON(object: value) { return false }
		}
		
		return true
	}
}

public protocol JSONContainer {}			//either a JSONArray or JSONDictionary

public typealias JSONArray = [Any]
public typealias JSONDictionary = [String : Any]

public protocol JSONObject {
	var JSONString: String? { get }
	var JSONData: Data? { get }
}

public protocol JSONInitable {
	init?(json: JSONDictionary)
}

public protocol JSONConvertible {
	var json: JSONDictionary? { get }
}

extension NSString: JSONObject {
	public var JSONString: String? { return (self as String) }
	public var JSONData: Data? { return self.data(using: String.Encoding.utf8.rawValue) }
}

extension Data: JSONObject {
	public var JSONString: String? { return self.base64EncodedString() }
	public var JSONData: Data? { return self.base64EncodedString().data(using: String.Encoding.utf8) }
}

extension NSNumber: JSONObject {
	public var JSONString: String? { return self.description }
	public var JSONData: Data? { return self.description.data(using: String.Encoding.utf8) }
}

extension Bool: JSONObject {
	public var JSONString: String? { return self ? "true" : "false" }
	public var JSONData: Data? { return self.JSONString?.data(using: String.Encoding.utf8) }
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
		return String(data: self.JSONData ?? Data(), encoding: String.Encoding.utf8) ?? ""
	}
}

public func ==(lhs: JSONDictionary, rhs: JSONDictionary) -> Bool {
	let lhd = lhs as NSDictionary
	let rhd = rhs as NSDictionary
	
	return lhd == rhd
}

extension Dictionary: JSONContainer {}
extension Array: JSONContainer {}

extension NSDictionary: JSONObject {
	public var JSONData: Data? {
		do {
			if !self.validateJSON() { return nil }
			return try JSONSerialization.data(withJSONObject: self, options: .prettyPrinted)
		} catch let error {
			print("Unable to convert \(self) to JSON: \(error)")
			return nil
		}
	}
	
}

extension NSArray: JSONObject {
	public var JSONData: Data? {
		do {
			if !self.validateJSON() { return nil }
			return try JSONSerialization.data(withJSONObject: self, options: .prettyPrinted)
		} catch let error {
			print("Unable to convert \(self) to JSON: \(error)")
			return nil
		}
	}
}

public extension String {
	public var json: JSONDictionary? { return self.jsonDictionary() }
	
	public func jsonDictionary(options: JSONSerialization.ReadingOptions = []) -> JSONDictionary? {
		guard let data = self.data(using: .utf8) else { return nil }

		do {
			let dict = try JSONSerialization.jsonObject(with: data, options: options) as? JSONDictionary
			return dict
		} catch let error {
			print("Error while parsing JSON Dictionary: \(error)")
		}
		return nil
	}
}

public extension Data {
	public var json: JSONDictionary? { return self.jsonDictionary() }
	
	public func jsonDictionary(options: JSONSerialization.ReadingOptions = []) -> JSONDictionary? {
		do {
			let dict = try JSONSerialization.jsonObject(with: self, options: options) as? JSONDictionary
			return dict
		} catch let error {
			print("Error while parsing JSON Dictionary: \(error)")
		}
		return nil
	}
	
	public func jsonArray(options: JSONSerialization.ReadingOptions = []) -> JSONArray? {
		do {
			let dict = try JSONSerialization.jsonObject(with: self, options: options) as? JSONArray
			return dict
		} catch let error {
			print("Error while parsing JSON Array: \(error)")
		}
		return nil
	}
	
	public func jsonContainer(options: JSONSerialization.ReadingOptions = []) -> JSONContainer? {
		do {
			let container = try JSONSerialization.jsonObject(with: self, options: options)
			
			if let array = container as? JSONArray { return array }
			if let dict = container as? JSONDictionary { return dict }
		} catch let error {
			print("Error while parsing JSON Array: \(error)")
		}
		return nil
	}
}

let JSONSeparatorsCharacterSet = CharacterSet(charactersIn: ".[]")
extension Dictionary where Key: ExpressibleByStringLiteral, Value: Any {
//	public func path(path: String) -> AnyObject? {
	public subscript(path path: String) -> Any? {
		let components = path.components(separatedBy: JSONSeparatorsCharacterSet)
		return self[components: components]
	}
	
	public subscript(int int: String) -> Int? {
		let components = int.components(separatedBy: JSONSeparatorsCharacterSet)
		if let integer = self[components: components] as? Int { return integer }
		if let str = self[components: components] as? String { return Int(str) }
		return nil
	}
	
	public subscript(components comps: [String]) -> Any? {
		guard let dict = (self as AnyObject) as? [String: AnyObject] else { return nil }
		var components = comps
		
		while components.first == "" { components.remove(at: 0) }
		guard components.count > 0 else { return nil }
		
		let key = components[0]

		components.remove(at: 0)
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
			let data = try JSONSerialization.data(withJSONObject: self as AnyObject, options: .prettyPrinted)
			return (NSString(data: data, encoding: String.Encoding.utf8.rawValue) as? String) ?? ""
		} catch let error as NSError {
			print("error while deserializing a JSON object: \(error)")
		}
		
		return nil
	}
}

extension Dictionary: JSONObject {
	public var JSONString: String? {
		if let dict = (self as AnyObject) as? NSDictionary {
			return dict.JSONString
		}
		return nil
	}
	public var JSONData: Data? {
		if !self.validateJSON() { return nil }
		return self.JSONString?.data(using: String.Encoding.utf8)
	}
}

extension Array: JSONObject {
	public subscript(path: String) -> Any? {
		let components = path.components(separatedBy: JSONSeparatorsCharacterSet)
		return self[components: components]
	}
	
	public subscript(int int: String) -> Int? {
		let components = int.components(separatedBy: JSONSeparatorsCharacterSet)
		if let integer = self[components: components] as? Int { return integer }
		if let str = self[components: components] as? String { return Int(str) }
		return nil
	}
	
	public subscript(components comps: [String]) -> Any? {
		var components = comps
		
		while components.first == "" { components.remove(at: 0) }
		guard components.count > 0 else { return nil }
		
		guard let index = Int(components[0]) else { return nil }
		components.remove(at: 0)
		while components.first == "" { components.remove(at: 0) }
		guard components.count > 0 else { return self[index] as AnyObject }
		
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
			let data = try JSONSerialization.data(withJSONObject: (self as AnyObject) as! [AnyObject], options: .prettyPrinted)
			return (NSString(data: data, encoding: String.Encoding.utf8.rawValue) as? String) ?? ""
		} catch let error as NSError {
			print("error while deserializing a JSON object: \(error)")
		}
		
		return nil
	}
	
	public var JSONData: Data? { return self.JSONString?.data(using: String.Encoding.utf8) }
	var description: String { return self.JSONString ?? "" }
}
