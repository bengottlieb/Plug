//
//  Incoming.swift
//  Plug
//
//  Created by Ben Gottlieb on 6/21/17.
//  Copyright © 2017 Stand Alone, inc. All rights reserved.
//

import Foundation

public class IncomingData: Incoming<Data> {
	convenience public init(url: URL, method: Plug.Method = .GET, parameters: Plug.Parameters? = nil, deferredStart: Bool = false) {
		self.init(url: url, method: method, parameters: parameters, deferredStart: deferredStart) { data in return data }
	}
}

public class IncomingJSON: Incoming<JSONDictionary> {
	convenience public init(url: URL, method: Plug.Method = .GET, parameters: Plug.Parameters? = nil, deferredStart: Bool = false) {
		self.init(url: url, method: method, parameters: parameters, deferredStart: deferredStart) { data in return data.jsonDictionary() }
	}
}

open class Incoming<Result> {
	let converter: ((Data) -> Result?)
	public var result: Result?
	public let url: URL
	public let parameters: Plug.Parameters?
	public let method: Plug.Method
	public var isComplete = false
	var pendingClosures: [(Result?) -> Void] = []
	
	public init(url: URL, method: Plug.Method = .GET, parameters: Plug.Parameters? = nil, deferredStart: Bool = false, converter: @escaping (Data) -> Result?) {
		self.url = url
		self.method = method
		self.parameters = parameters
		self.converter = converter
		
		if !deferredStart { self.start() }
	}
	
	public func resolved(_ closure: @escaping (Result?) -> Void) {
		if self.isComplete {
			closure(self.result)
		} else {
			self.pendingClosures.append(closure)
		}
	}
	
	public func start() {
		let conn = Connection(method: self.method, url: self.url, parameters: self.parameters)
		
		conn?.completion { conn, data in
			let result = self.converter(data.data)
			self.callClosures(with: result)
		}.error { connn, error in
			self.callClosures(with: nil)
		}.start()
	}
	
	func callClosures(with: Result?) {
		self.result = with
		self.isComplete = true
		let closures = self.pendingClosures
		self.pendingClosures = []
		
		closures.forEach { $0(with) }
	}
}
