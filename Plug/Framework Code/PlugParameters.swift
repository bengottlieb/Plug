//
//  PlugParameters.swift
//  Plug
//
//  Created by Ben Gottlieb on 2/9/15.
//  Copyright (c) 2015 Stand Alone, inc. All rights reserved.
//

import Foundation

extension Plug {
	public enum Parameters: Printable {
		case None
		case URL([String:String])
		case Form([String:String])
		
		var stringValue: String {
			switch (self) {
			case .URL(let params):
				return (reduce(params.keys, "?") { $0 + "\($1)=\(params[$1]!)&" } as String).stringByAddingPercentEncodingWithAllowedCharacters(.URLHostAllowedCharacterSet())!
				
			case .Form(let params):
				return reduce(params.keys, "") { $0 + "\($1)=\(params[$1]!)&" }
				
			case .None:
				return ""
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
			case .Form: return self.stringValue.dataUsingEncoding(NSUTF8StringEncoding, allowLossyConversion: false)
			default: return nil
			}
		}
		
		func normalizeMethod(method: Plug.Method) -> Plug.Method {
			switch (self) {
			case .Form: return .POST
			default: return method
			}
		}
		
		public var description: String {
			switch (self) {
			case .URL(let params): return reduce(params.keys, "[") { $0 + "\($1): \(params[$1]!), " } + "]"
			case .Form(let params): return reduce(params.keys, "[") { $0 + "\($1): \(params[$1]!), " } + "]"
				
			default: return ""
			}
		}
	}
}