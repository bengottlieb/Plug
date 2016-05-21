//
//  NSURLRequest+Plug.swift
//  Plug
//
//  Created by Ben Gottlieb on 5/20/16.
//  Copyright © 2016 Stand Alone, inc. All rights reserved.
//

import Foundation


extension NSURLRequest {
	public override var description: String {
		var str = (self.HTTPMethod ?? "[no method]") + " " + "\(self.URL)"
		
		if let fields = self.allHTTPHeaderFields {
			for (label, value) in fields {
				str += "\n\t" + label + ": " + value
			}
		}
		
		if let data = self.HTTPBody {
			let body = NSString(data: data, encoding: NSUTF8StringEncoding)
			str += "\n" + (body?.description ?? "[unconvertible body: \(data.length) bytes]")
		}
		
		return str
	}
}

extension NSURLComponents {
	public var queryDictionary: [String: String] {
		var results: [String: String] = [:]
		
		for pair in self.query?.componentsSeparatedByString("&") ?? [] {
			let values = pair.componentsSeparatedByString("=")
			
			if values.count == 2 {
				results[values[0]] = values[1]
			}
		}
		return results
	}
}

