//
//  PlugParameters.swift
//  Plug
//
//  Created by Ben Gottlieb on 2/9/15.
//  Copyright (c) 2015 Stand Alone, inc. All rights reserved.
//

import Foundation

extension Plug {
	public class FormComponents: Equatable {
		var fields: [String: String] = [:]
		var fileURLs: [(name: String, mimeType: String, url: NSURL)] = []
		var boundary = FormComponents.generateBoundaryString()
		var contentTypeHeader: String { return "multipart/form-data; boundary=\(self.boundary)" }
		
		public subscript(key: String) -> String? {
			get { return self.fields[key] }
			set { self.fields[key] = newValue }
		}
		
		public func addFile(url: NSURL?, name: String, mimeType: String) {
			guard let url = url else { return }
			self.fileURLs.append((name: name, mimeType: mimeType, url: url))
		}
		
		class func generateBoundaryString() -> String {
			return "Boundary-\(NSUUID().UUIDString)"
		}
		
		var dataValue: NSData {
			let data = NSMutableData()
			
			for (key, value) in self.fields {
				for line in ["--\(self.boundary)\r\n",
							 "Content-Disposition: form-data; name=\"\(key)\"\r\n\r\n",
							 "\(value)\r\n"
					] {
					if let lineData = line.dataUsingEncoding(NSUTF8StringEncoding) {
						data.appendData(lineData)
					}
				}
			}
			
			for (name, mimeType, url) in self.fileURLs {
				guard let filedata = NSData(contentsOfURL: url) else { continue }
				guard let path = url.path else { continue }
				let filename = (path as NSString).lastPathComponent
				
				for line in ["--\(self.boundary)\r\n",
					"Content-Disposition: form-data; name=\"\(name)\"; filename=\"\(filename)\"\r\n",
					"Content-Type: \(mimeType)\r\n\r\n"
					] {
						if let lineData = line.dataUsingEncoding(NSUTF8StringEncoding) {
							data.appendData(lineData)
						}
				}
				data.appendData(filedata)
				data.appendData("\(self.boundary)\r\n".dataUsingEncoding(NSUTF8StringEncoding)!)
			}
	
			data.appendData("--\(self.boundary)--\r\n".dataUsingEncoding(NSUTF8StringEncoding)!)

			return data
		}
		
		var JSONValue: String {
			return self.fields.keys.reduce("") { if let v = self.fields[$1] { return $0 + "\($1)=\(v)&" }; return $0 }
		}
		
		public init(fields dictionary: [String: String]) {
			fields = dictionary
		}
	}
	
	public enum Parameters: CustomStringConvertible {
		case None
		case URL([String: String])
		case Form(FormComponents)
		case JSON(NSDictionary)
		
		var stringValue: String {
			switch (self) {
			case .URL(let params):
				if params.keys.count == 0 { return "" }
				return (params.keys.reduce("?") { if let v = params[$1] { return $0 + "\($1)=\(v.stringByAddingPercentEncodingWithAllowedCharacters(.URLHostAllowedCharacterSet())!)&" }; return $0 })
				
			case .Form:
				return ""
				
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
		
		public var URLString: String {
			switch (self) {
			case .URL: return self.stringValue
			default: return ""
			}
		}
		
		var bodyData: NSData? {
			switch (self) {
			case .Form(let components):
				return components.dataValue
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
			case .Form(let components): return "\(components)"
			case .JSON: return "[" + self.stringValue + "]"
				
			default: return ""
			}
		}
		
		public var JSONValue: [String: NSDictionary]? {
			switch (self) {
			case .URL(let params): return ["URL": NSMutableDictionary(stringDictionary: params)]
			case .Form(let components): return ["Form": components.fields]
			case .JSON(let json): return ["JSON": json]
				
			default: return nil
			}
		}
		
		func addRequiredHeaders(var headers: Plug.Headers) -> Plug.Headers {
			switch self {
			case .Form(let components):
				headers.append(Plug.Header.ContentType(components.contentTypeHeader))
			default: break
			}
			return headers
		}
		
		init(dictionary: [String: NSDictionary]) {
			if let urlParams = dictionary["URL"] as? [String: String] {
				self = .URL(urlParams)
				return
			}
			if let formParams = dictionary["Form"] as? [String: String] {
				self = .Form(FormComponents(fields: formParams))
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
	switch (lhs, rhs) {
	case (.URL(let lhString), .URL(let rhString)):
		return lhString == rhString
		
	case (.Form(let lhComponents), .Form(let rhComponents)):
		return lhComponents == rhComponents
		
	case (.JSON(let lhJson), .JSON(let rhJson)):
		return lhJson == rhJson
	
	case (.None, .None): return true
		
	default: return false
	}
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

public func ==(lhs: Plug.FormComponents, rhs: Plug.FormComponents) -> Bool {
	return lhs === rhs
}