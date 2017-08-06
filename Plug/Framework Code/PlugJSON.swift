//
//  JSON.swift
//  Plug
//
//  Created by Ben Gottlieb on 2/22/15.
//  Copyright (c) 2015 Stand Alone, inc. All rights reserved.
//

import Foundation


public protocol JSONPrimitive: JSONConvertible {}			// Int, String, Float, Bool, [String: JSONPrimitive], [JSONPrimitive]
public protocol JSONContainer {}			//either a JSONArray or JSONDictionary

public protocol JSONConvertible {			// any object that can be converted into a JSONPrimitive
	var jsonRepresentation: JSONPrimitive? { get }
	var jsonString: String? { get }
	var jsonData: Data? { get }
}

public protocol JSONInitable {				// any object that can be initialized with a JSON object
	init?(json: JSONPrimitive)
}

public protocol JSONLoadable {				//any object that can be loaded with a JSON object
	@discardableResult func load(json: JSONPrimitive) -> Bool
}

func ValidateJSON(object value: JSONConvertible) -> Bool {
	if let dict = value as? JSONDictionary { return dict.validateJSON() }
	if let array = value as? JSONArray { return array.validateJSON() }
	
	if value is Int || value is String || value is JSONArray || value is Bool || value is Float || value is Double || value is NSNull { return true }
	
	if let rep = value.jsonRepresentation {
		return ValidateJSON(object: rep)
	}
	
	ReportInvalidJSON(value)
	return false
}

public func ReportInvalidJSON(_ value: Any) {
	print("▽▽▽▽▽▽▽▽▽▽▽▽▽▽▽▽▽ [ break on ReportInvalidJSON(_:) to debug ] ▽▽▽▽▽▽▽▽▽▽▽▽▽▽▽▽▽▽▽▽▽▽")
	print("Illegal value \(type(of: value)):  \(value)")
	print("△△△△△△△△△△△△△△△△△△△△△△△△△△△△△△△△△△△△△△△△△△△△△△△△△△△△△△△△△△△△△△△△△△△")
}

public typealias JSONArray = [Any]
public typealias JSONDictionary = [String : Any]

extension Dictionary where Key == String, Value: Any {
	func encode(to encoder: Encoder) {
		var container = encoder.singleValueContainer()
		try? container.encode(self)
	}
}

public extension Dictionary {
	@discardableResult public func validateJSON() -> Bool {
		for (key, value) in self {
			if !(key is String) {
				print("Illegal key: \(key)")
				return false
			}
			
			guard let jsonValue = value as? JSONConvertible else {
				if value is JSONPrimitive { continue }
				ReportInvalidJSON(value)
				return false
			}
			if !ValidateJSON(object: jsonValue) {
				ReportInvalidJSON(jsonValue)
				return false
			}
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
			
			guard let jsonValue = value as? JSONConvertible else {
				if value is JSONPrimitive { continue }
				return false
			}
			if !ValidateJSON(object: jsonValue) { return false }
		}
		return true
	}
}

public extension Array {
	@discardableResult public func validateJSON() -> Bool {
		for value in self {
			guard let jsonValue = value as? JSONConvertible else {
				if value is JSONPrimitive { continue }
				return false
			}
			if !ValidateJSON(object: jsonValue) { return false }
		}
		
		return true
	}
}

public extension NSArray {
	@discardableResult public func validateJSON() -> Bool {
		for value in self {
			guard let jsonValue = value as? JSONConvertible else {
				if value is JSONPrimitive { continue }
				return false
			}
			if !ValidateJSON(object: jsonValue) { return false }
		}
		
		return true
	}
}

extension NSString: JSONPrimitive {
	public var jsonRepresentation: JSONPrimitive? { return self }
	public var jsonString: String? { return (self as String) }
}

extension Data: JSONPrimitive {
	public var jsonRepresentation: JSONPrimitive? { return self }
	public var jsonString: String? { return self.base64EncodedString() }
}

extension NSNumber: JSONPrimitive {
	public var jsonRepresentation: JSONPrimitive? { return self }
	public var jsonString: String? { return self.description }
}

extension Bool: JSONPrimitive  {
	public var jsonRepresentation: JSONPrimitive? { return self }
	public var jsonString: String? { return self ? "true" : "false" }
}

extension JSONConvertible {
	public func log() {
		if let string = self.jsonString {
			print("\(string)")
		} else {
			print("\(self)")
		}
	}
	
	public var jsonData: Data? {
		if let json = self.jsonRepresentation {
			return try? JSONSerialization.data(withJSONObject: json, options: [])
		} else {
			return nil
		}
	}

	public var jsonString: String? {
		if !ValidateJSON(object: self) { return nil }
		if let json = self.jsonRepresentation, let data = try? JSONSerialization.data(withJSONObject: json, options: [.prettyPrinted]) {
			return String(data: data, encoding: String.Encoding.utf8)
		} else {
			return nil
		}
	}
}

public func ==(lhs: JSONDictionary, rhs: JSONDictionary) -> Bool {
	let lhd = lhs as NSDictionary
	let rhd = rhs as NSDictionary
	
	return lhd == rhd
}

extension Dictionary: JSONContainer {}
extension Array: JSONContainer {}

extension NSDictionary: JSONPrimitive {
	public var jsonData: Data? {
		do {
			if !self.validateJSON() { return nil }
			return try JSONSerialization.data(withJSONObject: self, options: [])
		} catch let error {
			print("Unable to convert \(self) to JSON: \(error)")
			return nil
		}
	}
	public var jsonRepresentation: JSONPrimitive? { return self as? JSONDictionary }
}

extension NSArray: JSONPrimitive {
	public var jsonData: Data? {
		do {
			if !self.validateJSON() { return nil }
			return try JSONSerialization.data(withJSONObject: self, options: [])
		} catch let error {
			print("Unable to convert \(self) to JSON: \(error)")
			return nil
		}
	}
	public var jsonRepresentation: JSONPrimitive? { return self as? JSONArray }
}

public extension String {
	public var json: JSONDictionary? { return self.jsonDictionary() }
	
	public func jsonDictionary(options: JSONSerialization.ReadingOptions = [], suppressErrors: Bool = false) -> JSONDictionary? {
		guard let data = self.data(using: .utf8) else { return nil }
		
		do {
			let dict = try JSONSerialization.jsonObject(with: data, options: options) as? JSONDictionary
			return dict
		} catch let error {
			if !suppressErrors { print("Error while parsing JSON Dictionary: \(error)") }
		}
		return nil
	}
	
	public func jsonArray(options: JSONSerialization.ReadingOptions = [], suppressErrors: Bool = false) -> JSONArray? {
		guard let data = self.data(using: .utf8) else { return nil }
		
		do {
			let arr = try JSONSerialization.jsonObject(with: data, options: options) as? JSONArray
			return arr
		} catch let error {
			if !suppressErrors { print("Error while parsing JSON Dictionary: \(error)") }
		}
		return nil
	}
}

public extension Data {
	public var json: JSONDictionary? { return self.jsonDictionary() }
	
	public func jsonDictionary(options: JSONSerialization.ReadingOptions = [], suppressErrors: Bool = false) -> JSONDictionary? {
		do {
			let dict = try JSONSerialization.jsonObject(with: self, options: options) as? JSONDictionary
			return dict
		} catch let error {
			if !suppressErrors { print("Error while parsing JSON Dictionary: \(error)") }
		}
		return nil
	}
	
	public func jsonArray(options: JSONSerialization.ReadingOptions = [], suppressErrors: Bool = false) -> JSONArray? {
		do {
			let dict = try JSONSerialization.jsonObject(with: self, options: options) as? JSONArray
			return dict
		} catch let error {
			if !suppressErrors { print("Error while parsing JSON Array: \(error)") }
		}
		return nil
	}
	
	public func jsonContainer(options: JSONSerialization.ReadingOptions = [], suppressErrors: Bool = false) -> JSONContainer? {
		do {
			let container = try JSONSerialization.jsonObject(with: self, options: options)
			
			if let array = container as? JSONArray { return array }
			if let dict = container as? JSONDictionary { return dict }
		} catch let error {
			if !suppressErrors { print("Error while parsing JSON Array: \(error)") }
		}
		return nil
	}
}

let JSONSeparatorsCharacterSet = CharacterSet(charactersIn: ".[]")
extension Dictionary where Key == String, Value: Any {
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
	
	public subscript(bool bool: String) -> Bool? {
		let components = bool.components(separatedBy: JSONSeparatorsCharacterSet)
		if let boolean = self[components: components] as? Bool { return boolean }
		if let integer = self[components: components] as? Int { return integer != 0 }
		if let str = self[components: components] as? String {
			let lower = str.lowercased()
			return lower == "false" || lower == "no"
		}
		return nil
	}
	

	public var jsonString: String? {
		do {
			let data = try JSONSerialization.data(withJSONObject: self as Any, options: [.prettyPrinted])
			return (NSString(data: data, encoding: String.Encoding.utf8.rawValue) as String?) ?? ""
		} catch let error {
			print("error while deserializing a JSON object: \(error)")
		}
		
		return nil
	}
	
	public subscript(components comps: [String]) -> Any? {
		guard let dict = (self as AnyObject) as? [String: Any] else { return nil }
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
			guard let dict = dict[key] as? NSDictionary else { return nil }
			return dict[components: components]
		}
	}
}

extension NSDictionary {
	public subscript(components comps: [String]) -> Any? {
		guard let dict = (self as AnyObject) as? [String: Any] else { return nil }
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
			guard let dict = dict[key] as? NSDictionary else { return nil }
			return dict[components: components]
		}
	}
	
	public subscript(path path: String) -> Any? {
		let components = path.components(separatedBy: JSONSeparatorsCharacterSet)
		return self[components: components]
	}
}

extension Dictionary: JSONPrimitive {
	public var jsonString: String? {
		if let dict = (self as AnyObject) as? NSDictionary {
			return dict.jsonString
		}
		return nil
	}
	
	public var prettyPrinted: String? { return self.jsonString }
	
	public var jsonData: Data? {
		if !self.validateJSON() { return nil }
		return try? JSONSerialization.data(withJSONObject: self, options: [])
	}
	public var jsonRepresentation: JSONPrimitive? { return (self as AnyObject) as? JSONDictionary }
}

extension Array: JSONPrimitive {
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
		var components = comps
		
		while components.first == "" { components.remove(at: 0) }
		guard components.count > 0 else { return nil }
		
		guard let index = Int(components[0]) else { return nil }
		components.remove(at: 0)
		while components.first == "" { components.remove(at: 0) }
		guard components.count > 0 else { return self[index] }
		
		if Int(components[0]) != nil {
			guard let array = self[index] as? JSONArray else { return nil }
			return array[components: components]
		} else {
			guard index < self.count, let dict = self[index] as? NSDictionary else { return nil }
			return dict[components: components]
		}
	}

	public var jsonString: String? {
		do {
			let data = try JSONSerialization.data(withJSONObject: (self as AnyObject) as! [Any], options: [.prettyPrinted])
			return (NSString(data: data, encoding: String.Encoding.utf8.rawValue) as String?) ?? ""
		} catch let error {
			print("error while deserializing a JSON object: \(error)")
		}
		
		return nil
	}
	
	public var jsonData: Data? {
		if !self.validateJSON() { return nil }
		return try? JSONSerialization.data(withJSONObject: self, options: [])
	}
	var description: String { return self.jsonString ?? "" }

	public var jsonRepresentation: JSONPrimitive? { return (self as AnyObject) as? JSONArray }
}

public extension Date {
	public static var JSONFormat = "yyyy-MM-dd HH:mm:ss Z"
	
	public init?(jsonString: String?, format: String = Date.JSONFormat, formats: [String]? = nil, cachedFormatter: DateFormatter? = nil) {
		var result: Date?
		
		for format in formats ?? (format == Date.JSONFormat ? [format] : [format, Date.JSONFormat]) {
			let formatter = cachedFormatter ?? {
				let formatter = DateFormatter()
				formatter.timeZone = TimeZone(secondsFromGMT: 0)
				formatter.dateFormat = format
				return formatter
			}()
			
			if let string = jsonString, let date = formatter.date(from: string) {
				result = date
				break
			}
		}
		if let date = result {
			self = date
		} else {
			return nil
		}
	}
	
	public func jsonString(format: String = Date.JSONFormat, cachedFormatter: DateFormatter? = nil) -> String {
		let formatter = cachedFormatter ?? {
			let formatter = DateFormatter()
			formatter.timeZone = TimeZone.current
			formatter.dateFormat = format
			return formatter
		}()

		return formatter.string(from: self)
	}
}

extension Int: JSONPrimitive {
	public var jsonRepresentation: JSONPrimitive? { return self }
}
extension Float: JSONPrimitive {
	public var jsonRepresentation: JSONPrimitive? { return self }
}

extension Double: JSONPrimitive {
	public var jsonRepresentation: JSONPrimitive? { return self }
}

extension UInt: JSONPrimitive {
	public var jsonRepresentation: JSONPrimitive? { return self }
}

extension String: JSONPrimitive {
	public var jsonRepresentation: JSONPrimitive? { return self }
}

extension NSNull: JSONPrimitive {
	public var jsonRepresentation: JSONPrimitive? { return nil }
}

