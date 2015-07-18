//
//  PlugParameters.swift
//  Plug
//
//  Created by Ben Gottlieb on 2/9/15.
//  Copyright (c) 2015 Stand Alone, inc. All rights reserved.
//

import Foundation

extension Plug {
	public enum Parameters: CustomStringConvertible {
		case None
		case URL([String: String])
		case Form([String: String])
		case JSON(NSDictionary)
		
		var stringValue: String {
			switch (self) {
			case .URL(let params):
				return (params.keys.reduce("?") { if let v = params[$1] { return $0 + "\($1)=\(v.stringByAddingPercentEncodingWithAllowedCharacters(.URLHostAllowedCharacterSet())!)&" }; return $0 })
				
			case .Form(let params):
				return params.keys.reduce("") { if let v = params[$1] { return $0 + "\($1)=\(v)&" }; return $0 }
				
			case .JSON(let object):
				return object.JSONString ?? ""
				
			case .None:
				return ""
			}
		}
		
		var type: String {
			switch (self) {
			case .URL: return "URL"
			case .Form: return "Form"
			case .JSON: return "JSON"
			default: return "None"
			}
		}
		
		var URLString: String {
			switch (self) {
			case .URL: return self.stringValue
			default: return ""
			}
		}
		
		var bodyData: NSData? {
			switch (self) {
			case .Form: fallthrough
			case .JSON:
				return self.stringValue.dataUsingEncoding(NSUTF8StringEncoding, allowLossyConversion: false)
			default: return nil
			}
		}
		
		func normalizeMethod(method: Plug.Method) -> Plug.Method {
			switch (self) {
			case .Form: fallthrough
			case .JSON:
				if method == .GET { return .POST }
				return method
			default: return method
			}
		}
		
		var contentTypeHeader: Plug.Header? {
			switch (self) {
			case .JSON: return .ContentType("application/json")
			default: return nil
			}
		}
		
		public var description: String {
			switch (self) {
			case .URL(let params): return params.keys.reduce("[") { if let v = params[$1] { return $0 + "\($1): \(v), " }; return $0 } + "]"
			case .Form(let params): return params.keys.reduce("[") { if let v = params[$1] { return $0 + "\($1): \(v), " }; return $0 } + "]"
			case .JSON: return "[" + self.stringValue + "]"
				
			default: return ""
			}
		}
		
		public var JSONValue: [String: NSDictionary]? {
			switch (self) {
			case .URL(let params): return ["URL": NSMutableDictionary(stringDictionary: params)]
			case .Form(let params): return ["Form": NSMutableDictionary(stringDictionary: params)]
			case .JSON(let json): return ["JSON": json]
				
			default: return nil
			}
		}
		
		init(dictionary: [String: NSDictionary]) {
			if let urlParams = dictionary["URL"] as? [String: String] {
				self = .URL(urlParams)
				return
			}
			if let formParams = dictionary["Form"] as? [String: String] {
				self = .Form(formParams)
				return
			}
			
			if let JSONParams = dictionary["JSON"] {
				self = .JSON(JSONParams)
				return
			}
			
			self = .None
		}
	}
}

public func ==(lhs: Plug.Parameters, rhs: Plug.Parameters) -> Bool {
	return lhs.type == rhs.type && lhs.type == "None"
}

extension NSMutableDictionary {
	convenience init(stringDictionary: [String: String?]) {
		self.init()
		
		for (key, value) in stringDictionary {
			if value != nil {
				self[key] = value!
			}
		}
	}
	
	var stringDictionary: [String: String] {
		var result: [String: String] = [:]
		
		for (key, value) in self {
			if let str = value as? String {
				if let key = key as? String {
					result[key] = str
				}
			}
		}
		return result
	}
}

