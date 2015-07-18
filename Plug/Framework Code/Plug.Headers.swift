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
		case Accept([String])
		case AcceptEncoding(String)
		case ContentType(String)
		case BasicAuthorization(String, String)
		case UserAgent(String)
		
		case Custom(String, String)
		
		var label: String {
			switch (self) {
			case .Accept: return "Accept"
			case .AcceptEncoding: return "Accept-Encoding"
			case .ContentType: return "Content-Type"
			case .BasicAuthorization: return "Authorization"
			case .UserAgent: return "User-Agent"
				
			case .Custom(let label,  _): return label
			}
		}
		
		var content: String {
			switch (self) {
			case .Accept(let types):
				let content = types.reduce("") { "\($0)\($1);" }
				return content.stringByTrimmingCharactersInSet(NSCharacterSet(charactersInString: ";"))
				
			case .AcceptEncoding(let encoding): return encoding
			case .ContentType(let type): return type
			case .BasicAuthorization(let user, let pass):
				return "Basic " + ("\(user):\(pass)".dataUsingEncoding(NSUTF8StringEncoding)?.base64EncodedStringWithOptions([]) ?? "")
			case .UserAgent(let agent): return agent
				
			case .Custom(_, let content): return content
			}
		}
		
		func isSameHeaderAs(header: Header) -> Bool {
			return self.label == header.label
		}
	}
	
	public struct Headers: CustomStringConvertible {
		var headers: [Header] = []
		public mutating func append(header: Header) {
			for (index, existing) in self.headers.enumerate() {
				if existing.isSameHeaderAs(header) {
					self.headers[index] = header
					return
				}
			}
			self.headers.append(header)
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
	}
}

