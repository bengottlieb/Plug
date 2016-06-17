//
//  URLRequest+Plug.swift
//  Plug
//
//  Created by Ben Gottlieb on 5/20/16.
//  Copyright © 2016 Stand Alone, inc. All rights reserved.
//

import Foundation


extension URLRequest {
	public var description: String {
		var str = (self.httpMethod ?? "[no method]") + " " + "\(self.url)"
		
		if let fields = self.allHTTPHeaderFields {
			for (label, value) in fields {
				str += "\n\t" + label + ": " + value
			}
		}
		
		if let data = self.httpBody {
			let body = String(data: data, encoding: String.Encoding.utf8)
			str += "\n" + (body ?? "[unconvertible body: \(data.count) bytes]")
		}
		
		return str
	}
}

extension URLComponents {
	public var queryDictionary: [String: String] {
		var results: [String: String] = [:]
		
		for pair in self.query?.components(separatedBy: "&") ?? [] {
			let values = pair.components(separatedBy: "=")
			
			if values.count == 2 {
				results[values[0]] = values[1]
			}
		}
		return results
	}
}

