//
//  Plug.ConnectionData.swift
//  Plug
//
//  Created by Ben Gottlieb on 5/20/16.
//  Copyright © 2016 Stand Alone, inc. All rights reserved.
//

import Foundation

#if canImport(UIKit)
import UIKit
#endif

#if canImport(AppKit)
import AppKit
#endif

public extension Plug {
	class ConnectionData: CustomStringConvertible {
		public enum JSONObjectType { case dictionary, array }
		
		public var data: Data {
			if let data = self.rawData { return data }
			
			if let url = self.url {
				do {
					try self.rawData = Data(contentsOf: url)
				} catch {}
			}
			
			return self.rawData ?? Data()
		}
		public var url: URL?
		private var rawData: Data?
		
		public var description: String { return "Data, \(ByteCountFormatter.string(fromByteCount: Int64(self.length), countStyle: .file)), \(self.data)" }
		
		public func decode<T>(_ type: T.Type) throws -> T where T : Decodable {
			return try JSONDecoder().decode(T.self, from: self.data)
		}
		
		init?(data: Data?, size: UInt64) {
			length = size
			if data == nil { return nil }
			self.rawData = data
		}
		
		init?(url: URL?, size: UInt64) {
			length = size
			if url == nil { return nil }
			self.url = url
		}
		
		public var length: UInt64
		
		init() {
			length = 0
			self.rawData = nil
		}
		
		public var json: JSONDictionary? {
			return self.rawData?.json
		}
        
        #if os(iOS)
            public var image: UIImage? {
                if let data = self.rawData { return UIImage(data: data) }
                return nil
            }
        #endif
        
        #if os(OSX)
            public var image: NSImage? {
                if let data = self.rawData { return NSImage(data: data) }
                return nil
            }
        #endif
		
		public func string(encoding: String.Encoding = .utf8) -> String? {
			guard let data = self.rawData else { return nil }
			return String(data: data, encoding: encoding)
		}
		
		public var jsonObjectType: JSONObjectType? {
			do {
				let object = try JSONSerialization.jsonObject(with: data, options: [])
				
				if object is JSONDictionary { return .dictionary }
				if object is JSONArray { return .array }
			} catch { }
			return nil
		}
	}
}
