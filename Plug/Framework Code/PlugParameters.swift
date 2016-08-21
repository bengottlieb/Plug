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
		
		public subscript(key: String) -> Any? {
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
			var data = Data()
			let fields = self.labeledFieldsArray(dict: self.fields)
			
			for (key, value) in fields {
				for line in ["--\(self.boundary)\r\n",
							 "Content-Disposition: form-data; name=\"\(key)\"\r\n\r\n",
							 "\(value)\r\n"
					] {
					if let lineData = line.data(using: String.Encoding.utf8) {
						data.append(lineData)
					}
				}
			}
			
			for (name, mimeType, url) in self.fileURLs {
				guard let filedata = try? Data(contentsOf: url) else { continue }
				let path = url.path
				let filename = (path as NSString).lastPathComponent
				
				for line in ["--\(self.boundary)\r\n",
					"Content-Disposition: form-data; name=\"\(name)\"; filename=\"\(filename)\"\r\n",
					"Content-Type: \(mimeType)\r\n\r\n"
					] {
						if let lineData = line.data(using: String.Encoding.utf8) {
							data.append(lineData)
						}
				}
				data.append(filedata)
				data.append("\(self.boundary)\r\n".data(using: String.Encoding.utf8)!)
			}
	
			data.append("--\(self.boundary)--\r\n".data(using: String.Encoding.utf8)!)

			return data as Data
		}
		
		var JSONValue: String {
			return self.fields.keys.reduce("") { if let v = self.fields[$1] { return $0 + "\($1)=\(v)&" }; return $0 }
		}
		
		public init(fields dictionary: JSONDictionary) {
			fields = dictionary
		}
		
		public var description: String {
			var string = ""
			let fields = self.labeledFieldsArray(dict: self.fields)
			
			for (key, value) in fields {
				for line in ["--\(self.boundary)\r\n",
					"Content-Disposition: form-data; name=\"\(key)\"\r\n\r\n",
					"\(value)\r\n"
					] {
						string += line
				}
			}
			
			for (name, mimeType, url) in self.fileURLs {
				guard let filedata = try? Data(contentsOf: url) else { continue }
				let path = url.path
				let filename = (path as NSString).lastPathComponent
				
				for line in ["--\(self.boundary)\n",
					"Content-Disposition: form-data; name=\"\(name)\"; filename=\"\(filename)\"\n",
					"Content-Type: \(mimeType)\n\n"
					] {
						string += line
				}
				string += "<<<<<<\(filedata.count) bytes>>>>>>\n"
				string += "\(self.boundary)\n"
			}
			
			string += "--\(self.boundary)--\n"
			
			return string
		}
	}
	
	public enum Parameters: CustomStringConvertible {
		case none
		case url([String: String])
		case form(FormComponents)
		case json(JSONDictionary)
		
		var stringValue: String {
			switch (self) {
			case .url(let params):
				if params.keys.count == 0 { return "" }
				return (params.keys.reduce("?") { if let v = params[$1] { return $0 + "\($1)=\(v.addingPercentEncoding(withAllowedCharacters: CharacterSet.urlHostAllowed)!)&" }; return $0 })
				
			case .form:
				return ""
				
			case .json(let object):
				return (object as NSDictionary).JSONString ?? ""
				
			case .none:
				return ""
			}
		}
		
		var type: String {
			switch (self) {
			case .url: return "URL"
			case .form: return "Form"
			case .json: return "JSON"
			default: return "None"
			}
		}
		
		public var URLString: String {
			switch (self) {
			case .url: return self.stringValue
			default: return ""
			}
		}
		
		var bodyData: Data? {
			switch (self) {
			case .form(let components):
				return components.dataValue
			case .json:
				return self.stringValue.data(using: String.Encoding.utf8, allowLossyConversion: false)
			default: return nil
			}
		}
		
		func normalizeMethod(method: Plug.Method) -> Plug.Method {
			switch (self) {
			case .form: fallthrough
			case .json:
				if method == .GET { return .POST }
				return method
			default: return method
			}
		}
		
		var contentTypeHeader: Plug.Header? {
			switch (self) {
			case .form(let components): return .contentType(components.contentTypeHeader)
			case .json: return .contentType("application/json")
			default: return nil
			}
		}
		
		public var description: String {
			switch (self) {
			case .url(let params): return params.keys.reduce("[") { if let v = params[$1] { return $0 + "\($1): \(v), " }; return $0 } + "]"
			case .form(let components): return "\(components)"
			case .json: return "[" + self.stringValue + "]"
				
			default: return ""
			}
		}
		
		public var JSONValue: [String: NSDictionary]? {
			switch (self) {
			case .url(let params): return ["URL": NSMutableDictionary(stringDictionary: params)]
			case .form(let components): return ["Form": components.fields as NSDictionary]
			case .json(let json): return ["JSON": json as NSDictionary]
				
			default: return nil
			}
		}
		
		init(dictionary: [String: NSDictionary]) {
			if let urlParams = dictionary["URL"] as? [String: String] {
				self = .url(urlParams)
				return
			}
			if let formParams = dictionary["Form"] as? [String: String] {
				self = .form(FormComponents(fields: formParams as JSONDictionary))
				return
			}
			
			if let JSONParams = dictionary["JSON"] as? JSONDictionary {
				self = .json(JSONParams)
				return
			}
			
			self = .none
		}
	}
}

public func ==(lhs: Plug.Parameters, rhs: Plug.Parameters) -> Bool {
	switch (lhs, rhs) {
	case (.url(let lhString), .url(let rhString)):
		return lhString == rhString
		
	case (.form(let lhComponents), .form(let rhComponents)):
		return lhComponents == rhComponents
		
	case (.json(let lhJson), .json(let rhJson)):
		return (lhJson as NSDictionary) == (rhJson as NSDictionary)
	
	case (.none, .none): return true
		
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
