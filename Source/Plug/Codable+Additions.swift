//
//  Encoding+Additions.swift
//  Plug
//
//  Created by Ben Gottlieb on 2/2/18.
//  Copyright © 2018 Stand Alone, inc. All rights reserved.
//

import Foundation

public struct JSONCodingKey: CodingKey {
	public var stringValue: String
	public init?(stringValue: String) {
		self.stringValue = stringValue
	}
	
	public var intValue: Int?
	
	public init?(intValue: Int) {
		self.init(stringValue: "\(intValue)")
		self.intValue = intValue
	}
	
	public init(_ string: String) {
		self.stringValue = string
	}
	
}


extension Encodable {
	public var encodedJSONData: Data? {
		let encoder = JSONEncoder()
		
		if #available(iOS 11.0, iOSApplicationExtension 11.0, OSX 10.13, OSXApplicationExtension 10.13, *) {
			encoder.outputFormatting = [.sortedKeys]
		} else {
			encoder.outputFormatting = []
		}
		
		return try? encoder.encode(self)
	}
	
	public var encodedJSONDictionary: JSONDictionary? {
		return self.encodedJSONObject as? JSONDictionary
	}
	
	public var encodedJSONObject: JSONConvertible? {
		guard let data = self.encodedJSONData else { return nil }
		do {
			return try JSONSerialization.jsonObject(with: data, options: []) as? JSONConvertible
		} catch {}
		
		return nil
	}
	
	public var encodedJSONString: String? {
		guard let json = self.encodedJSONDictionary else { return nil }
		return json.toString()
	}
}

extension JSONDecoder {
	public enum Error: Swift.Error { case failedToConvertToJSON }
	public func decode<T>(_ type: T.Type, from dict: JSONDictionary) throws -> T where T : Decodable {
		guard let data = dict.jsonData else { throw Error.failedToConvertToJSON }
		
		return try self.decode(type, from: data)
	}
}
