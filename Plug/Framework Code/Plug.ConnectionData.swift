//
//  Plug.ConnectionData.swift
//  Plug
//
//  Created by Ben Gottlieb on 5/20/16.
//  Copyright © 2016 Stand Alone, inc. All rights reserved.
//

import Foundation


public extension Plug {
	public class ConnectionData {
		public var data: Data {
			if let data = self.rawData { return data }
			
			if let url = self.URL {
				self.rawData = Data(contentsOfURL: url)
			}
			
			return self.rawData ?? Data()
		}
		public var URL: URL?
		private var rawData: Data?
		
		init?(data: Data?, size: UInt64) {
			length = size
			if data == nil { return nil }
			self.rawData = data
		}
		
		init?(URL: URL?, size: UInt64) {
			length = size
			if URL == nil { return nil }
			self.URL = URL
		}
		
		public var length: UInt64
		
		init() {
			length = 0
			self.rawData = nil
		}
		
		public var utf8: String { return String(data: self.data, encoding: NSUTF8StringEncoding) ?? "" }
		public var utf16: String { return String(data: self.data, encoding: NSUTF16StringEncoding) ?? "" }
		public var ascii: String { return String(data: self.data, encoding: NSASCIIStringEncoding) ?? "" }
	}
}
