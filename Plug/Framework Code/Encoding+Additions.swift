//
//  Encoding+Additions.swift
//  Plug
//
//  Created by Ben Gottlieb on 2/2/18.
//  Copyright © 2018 Stand Alone, inc. All rights reserved.
//

import Foundation

extension Encodable {
	public var encodedJSONData: Data? {
		let encoder = JSONEncoder()
		
		if #available(iOSApplicationExtension 11.0, OSXApplicationExtension 10.13, *) {
			encoder.outputFormatting = [.sortedKeys]
		} else {
			encoder.outputFormatting = []
		}
		
		return try? encoder.encode(self)
	}
	
	public var encodedJSONDictionary: JSONDictionary? {
		guard let data = self.encodedJSONData else { return nil }
		do {
			return try JSONSerialization.jsonObject(with: data, options: []) as? JSONDictionary
		} catch {}
		
		return nil
	}
	
	public var encodedJSONString: String? {
		guard let json = self.encodedJSONDictionary else { return nil }
		return json.toString()
	}
}
