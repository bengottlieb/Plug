//
//  Plug.Headers.swift
//  Plug
//
//  Created by Ben Gottlieb on 2/12/15.
//  Copyright (c) 2015 Stand Alone, inc. All rights reserved.
//

import Foundation

extension Plug {
	public enum Header: Codable {
		enum CodableKeys: CodingKey { case label, value, secondValue }
		
		public init(from decoder: Decoder) throws {
			let container = try decoder.container(keyedBy: CodableKeys.self)
			
			let label = try container.decode(String.self, forKey: .label)
			
			switch label {
			case "Accept": self = .accept(try container.decode([String].self, forKey: .value))
				
			default:
				self = .custom(label, try container.decode(String.self, forKey: .value))
			}
		}
		
		public func encode(to encoder: Encoder) throws {
			var container = encoder.container(keyedBy: CodableKeys.self)
			try container.encode(self.label, forKey: .label)
			
			switch (self) {
			case .accept(let types): try container.encode(types, forKey: .value)
			case .acceptEncoding(let encoding): try container.encode(encoding, forKey: .value)
			case .contentType(let type): try container.encode(type, forKey: .value)
			case .tokenAuthorization(let token): try container.encode(token, forKey: .value)
			case .basicAuthorization(let user, let pass):
				try container.encode(user, forKey: .value)
				try container.encode(pass, forKey: .secondValue)
			case .userAgent(let agent): try container.encode(agent, forKey: .value)
			case .setCookie(let cookie): try container.encode(cookie, forKey: .value)
			case .cookie(let cookies): try container.encode(cookies, forKey: .value)

			case .custom(_, let content): try container.encode(content, forKey: .value)
			}

		}
		
		case accept([String])
		case acceptEncoding(String)
		case contentType(String)
		case basicAuthorization(String, String)
		case tokenAuthorization(String)
		case userAgent(String)
		case cookie(String)
		case setCookie(String)

		case custom(String, String)
		
		public var label: String {
			switch (self) {
			case .accept: return "Accept"
			case .acceptEncoding: return "Accept-Encoding"
			case .contentType: return "Content-Type"
			case .basicAuthorization: return "Authorization"
			case .tokenAuthorization: return "Authorization"
			case .userAgent: return "User-Agent"
			case .setCookie(_): return "Set-Cookie"
			case .cookie(_): return "Cookie"

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
			case .tokenAuthorization(let token): return "Bearer \(token)"
			case .basicAuthorization(let user, let pass):
				return "Basic " + ("\(user):\(pass)".data(using: .utf8)?.base64EncodedString() ?? "")
			case .userAgent(let agent): return agent
			case .setCookie(let cookie): return cookie
			case .cookie(let cookie): return cookie

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
			case "Set-Cookie": self = .setCookie(content)
			case "Cookie": self = .cookie(content)

			default: self = .custom(label, content)
			}
		}
	}
	
	public struct Headers: CustomStringConvertible, Codable {
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
		public init(_ headerList: [Header] = []) {
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

