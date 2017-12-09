//
//  PlugParameters.swift
//  Plug
//
//  Created by Ben Gottlieb on 2/9/15.
//  Copyright (c) 2015 Stand Alone, inc. All rights reserved.
//

import Foundation

extension Plug {
	public class FormComponents: Equatable, CustomStringConvertible, Codable {
		enum CodableKeys: String, CodingKey { case fields, fileURLs, boundary }
		var fields: JSONDictionary = [:]
		var fileURLs: [FileURL] = []
		var boundary = FormComponents.generateBoundaryString()
		var contentTypeHeader: String { return "multipart/form-data; boundary=\(self.boundary)" }
		
		public func encode(to encoder: Encoder) throws {
			var container = encoder.container(keyedBy: CodableKeys.self)
			try container.encode(self.fields, forKey: .fields)
			try container.encode(self.fileURLs, forKey: .fileURLs)
			try container.encode(boundary, forKey: .boundary)
		}
		
		public required init(from decoder: Decoder) throws {
			let container = try decoder.container(keyedBy: CodableKeys.self)
			self.fields = try container.decode(JSONDictionary.self, forKey: .fields)
			self.fileURLs = try container.decode([FileURL].self, forKey: .fileURLs)
			self.boundary = try container.decode(String.self, forKey: .boundary)
		}
		
		public struct FileURL: Codable {
			let name: String
			let mimeType: String
			let url: URL
		}
		
		public subscript(key: String) -> Any? {
			get { return self.fields[key] }
			set { self.fields[key] = newValue }
		}
		
		public func addFile(url: URL?, name: String, mimeType: String) {
			guard let url = url else { return }
			self.fileURLs.append(FileURL(name: name, mimeType: mimeType, url: url))
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
			
			for file in self.fileURLs {
				guard let filedata = try? Data(contentsOf: file.url) else { continue }
				let path = file.url.path
				let filename = (path as NSString).lastPathComponent
				
				for line in ["--\(self.boundary)\r\n",
					"Content-Disposition: form-data; name=\"\(file.name)\"; filename=\"\(filename)\"\r\n",
					"Content-Type: \(file.mimeType)\r\n\r\n"
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
			
			for file in self.fileURLs {
				guard let filedata = try? Data(contentsOf: file.url) else { continue }
				let path = file.url.path
				let filename = (path as NSString).lastPathComponent
				
				for line in ["--\(self.boundary)\n",
					"Content-Disposition: form-data; name=\"\(file.name)\"; filename=\"\(filename)\"\n",
					"Content-Type: \(file.mimeType)\n\n"
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
	
	public enum Parameters: CustomStringConvertible, Codable {
		case none
		case url([String: String])
		case form(FormComponents)
		case json(JSONDictionary)
		case data(Data)
		
		enum CodableKeys: String, CodingKey { case label, url, form, json, data }
		enum CodingError: Error { case empty }
		public init(from decoder: Decoder) throws {
			let container = try decoder.container(keyedBy: CodableKeys.self)
			if let data = try? container.decode(Data.self, forKey: .data) {
				self = .data(data)
				return
			}
			
			if let data = try? container.decode(JSONDictionary.self, forKey: .json) {
				self = .json(data)
				return
			}
			
			if let data = try? container.decode(FormComponents.self, forKey: .form) {
				self = .form(data)
				return
			}
			
			if let data = try? container.decode([String: String].self, forKey: .url) {
				self = .url(data)
				return
			}
			
			self = .none
		}
		
		public func encode(to encoder: Encoder) throws {
			var container = encoder.container(keyedBy: CodableKeys.self)
			switch self {
			case .none: return
			case .url(let fields): try container.encode(fields, forKey: .url)
			case .form(let components): try container.encode(components, forKey: .form)
			case .json(let json): try container.encode(json, forKey: .json)
			case .data(let data): try container.encode(data, forKey: .data)
			}
		}
		
		var stringValue: String {
			switch (self) {
			case .url(let params):
				if params.keys.count == 0 { return "" }
				return (params.keys.reduce("?") { if let v = params[$1] { return $0 + "\($1)=\(v.addingPercentEncoding(withAllowedCharacters: CharacterSet.urlHostAllowed)!)&" }; return $0 })
				
			case .form:
				return ""
				
			case .data(let data):
				return String(data: data, encoding: .utf8) ?? ""
				
			case .json(let object):
				return (object as NSDictionary).jsonString ?? ""
				
			case .none:
				return ""
			}
		}
		
		var type: String {
			switch (self) {
			case .url: return "URL"
			case .form: return "Form"
			case .data: return "Data"
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
			case .data(let data): return data
			default: return nil
			}
		}
		
		func normalizeMethod(method: Plug.Method) -> Plug.Method {
			switch (self) {
			case .form: fallthrough
			case .data: fallthrough
			case .json:
				if method == .GET { return .POST }
				return method
			default: return method
			}
		}
		
		var contentTypeHeader: Plug.Header? {
			switch (self) {
			case .form(let components): return .contentType(components.contentTypeHeader)
			case .data: return .contentType("application/data")
			case .json: return .contentType("application/json")
			default: return nil
			}
		}
		
		public var description: String {
			switch (self) {
			case .url(let params): return params.keys.reduce("[") { if let v = params[$1] { return $0 + "\($1): \(v), " }; return $0 } + "]"
			case .form(let components): return "\(components)"
			case .json: return "JSON:[" + self.stringValue + "]"
			case .data: return "[" + self.stringValue + "]"
				
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
