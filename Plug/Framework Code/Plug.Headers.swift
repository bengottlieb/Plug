//
//  Plug.Headers.swift
//  Plug
//
//  Created by Ben Gottlieb on 2/12/15.
//  Copyright (c) 2015 Stand Alone, inc. All rights reserved.
//

import Foundation

extension Plug {
	public enum Header {
		case accept([String])
		case acceptEncoding(String)
		case contentType(String)
		case basicAuthorization(String, String)
		case userAgent(String)
		
		case custom(String, String)
		
		public var label: String {
			switch (self) {
			case .accept: return "Accept"
			case .acceptEncoding: return "Accept-Encoding"
			case .contentType: return "Content-Type"
			case .basicAuthorization: return "Authorization"
			case .userAgent: return "User-Agent"
				
			case .custom(let label,  _): return label
			}
		}
		
		public var content: String {
			switch (self) {
			case .accept(let types):
				let content = types.reduce("") { "\($0)\($1);" }
				return content.trimmingCharacters(in: CharacterSet(charactersIn: ";"))
				
			case .acceptEncoding(let encoding): return encoding
			case .contentType(let type): return type
			case .basicAuthorization(let user, let pass):
				return "Basic " + ("\(user):\(pass)".data(using: String.Encoding.utf8)?.base64EncodedString() ?? "")
			case .userAgent(let agent): return agent
				
			case .custom(_, let content): return content
			}
		}
		
		public func isSameHeaderAs(header: Header) -> Bool {
			return self.label.lowercased() == header.label.lowercased()
		}
		
		public init(label: String, content: String) {
			switch label {
			case "Accept": self = .accept(content.components(separatedBy: ","))
			case "Accept-Encoding": self = .acceptEncoding(content)
			case "Content-Type": self = .contentType(content)
			case "User-Agent": self = .acceptEncoding(content)
				
			default: self = .custom(label, content)
			}
		}
	}
	
	public struct Headers: CustomStringConvertible {
		var headers: [Header] = []
		public mutating func append(header: Header) {
			for (index, existing) in self.headers.enumerated() {
				if existing.isSameHeaderAs(header: header) {
					self.headers[index] = header
					return
				}
			}
			self.headers.append(header)
		}
		
		init(dictionary: NSDictionary?) {
			if let dict = dictionary as? [String: String] {
				for (key, value) in dict {
					self.headers.append(Header(label: key, content: value))
				}
			}
		}
		
		public var dictionary: [String: String] {
			var dict: [String: String] = [:]
			
			for header in self.headers { dict[header.label] = header.content }
			return dict
		}
		public init(_ headerList: [Header]) {
			headers = headerList
		}
		
		public var description: String {
			return self.dictionary.description
		}
		
		public subscript(key: String) -> Header? {
			get {
				let lowerKey = key.lowercased()
				for header in self.headers {
					if header.label.lowercased() == lowerKey {
						return header
					}
				}
				return nil
			}
		}
	}
}

