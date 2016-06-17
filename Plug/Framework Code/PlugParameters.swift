//
//  PlugParameters.swift
//  Plug
//
//  Created by Ben Gottlieb on 2/9/15.
//  Copyright (c) 2015 Stand Alone, inc. All rights reserved.
//

import Foundation

extension Plug {
	public class FormComponents: Equatable, CustomStringConvertible {
		var fields: JSONDictionary = [:]
		var fileURLs: [(name: String, mimeType: String, url: URL)] = []
		var boundary = FormComponents.generateBoundaryString()
		var contentTypeHeader: String { return "multipart/form-data; boundary=\(self.boundary)" }
		
		public subscript(key: String) -> AnyObject? {
			get { return self.fields[key] }
			set { self.fields[key] = newValue }
		}
		
		public func addFile(url: URL?, name: String, mimeType: String) {
			guard let url = url else { return }
			self.fileURLs.append((name: name, mimeType: mimeType, url: url))
		}
		
		class func generateBoundaryString() -> String {
			return "Boundary-\(NSUUID().uuidString)"
		}
		
		func labeledFieldsArray(dict: JSONDictionary, prefix: String? = nil) -> [(String, String)] {
			var results: [(String, String)] = []
			
			for (key, value) in dict {
				if let subDict = value as? JSONDictionary {
					let extendedPrefix = prefix == nil ? key : "\(prefix!)[\(key)]"
					results += self.labeledFieldsArray(dict: subDict, prefix: extendedPrefix)
				} else {
					let label = prefix == nil ? "" : "\(prefix!)[\(key)]"
					results.append((label, "\(value)"))
				}
			}
			return results
		}
		
		var dataValue: Data {
			let data = NSMutableData()
			let fields = self.labeledFieldsArray(dict: self.fields)
			
			for (key, value) in fields {
				for line in ["--\(self.boundary)\r\n",
							 "Content-Disposition: form-data; name=\"\(key)\"\r\n\r\n",
							 "\(value)\r\n"
					] {
					if let lineData = line.data(String.Encoding.utf8) {
						data.appendData(lineData)
					}
				}
			}
			
			for (name, mimeType, url) in self.fileURLs {
				guard let filedata = Data(contentsOfURL: url) else { continue }
				guard let path = url.path else { continue }
				let filename = (path as NSString).lastPathComponent
				
				for line in ["--\(self.boundary)\r\n",
					"Content-Disposition: form-data; name=\"\(name)\"; filename=\"\(filename)\"\r\n",
					"Content-Type: \(mimeType)\r\n\r\n"
					] {
						if let lineData = line.dataUsingEncoding(String.Encoding.utf8) {
							data.appendData(lineData)
						}
				}
				data.appendData(filedata)
				data.appendData("\(self.boundary)\r\n".dataUsingEncoding(String.Encoding.utf8)!)
			}
	
			data.appendData("--\(self.boundary)--\r\n".dataUsingEncoding(String.Encoding.utf8)!)

			return data
		}
		
		var JSONValue: String {
			return self.fields.keys.reduce("") { if let v = self.fields[$1] { return $0 + "\($1)=\(v)&" }; return $0 }
		}
		
		public init(fields dictionary: JSONDictionary) {
			fields = dictionary
		}
		
		public var description: String {
			var string = ""
			let fields = self.labeledFieldsArray(self.fields)
			
			for (key, value) in fields {
				for line in ["--\(self.boundary)\r\n",
					"Content-Disposition: form-data; name=\"\(key)\"\r\n\r\n",
					"\(value)\r\n"
					] {
						string += line
				}
			}
			
			for (name, mimeType, url) in self.fileURLs {
				guard let filedata = Data(contentsOfURL: url) else { continue }
				guard let path = url.path else { continue }
				let filename = (path as NSString).lastPathComponent
				
				for line in ["--\(self.boundary)\n",
					"Content-Disposition: form-data; name=\"\(name)\"; filename=\"\(filename)\"\n",
					"Content-Type: \(mimeType)\n\n"
					] {
						string += line
				}
				string += "<<<<<<\(filedata.length) bytes>>>>>>\n"
				string += "\(self.boundary)\n"
			}
			
			string += "--\(self.boundary)--\n"
			
			return string
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
		
		var bodyData: Data? {
			switch (self) {
			case .Form(let components):
				return components.dataValue
			case .JSON:
				return self.stringValue.dataUsingEncoding(String.Encoding.utf8, allowLossyConversion: false)
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
			case .Form(let components): return .ContentType(components.contentTypeHeader)
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
