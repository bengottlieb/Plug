//
//  Incoming.swift
//  Plug
//
//  Created by Ben Gottlieb on 6/21/17.
//  Copyright © 2017 Stand Alone, inc. All rights reserved.
//

import Foundation

public class IncomingData {
	var incoming: Incoming<Data>
	public init(url: URL, method: Plug.Method = .GET, parameters: Plug.Parameters? = nil, deferredStart: Bool = false) {
		self.incoming = Incoming<Data>(url: url, method: method, parameters: parameters, deferredStart: deferredStart) { data in
			return data.data
		}
	}
	
	public func resolved(_ closure: @escaping (Data?) -> Void) { self.incoming.resolved(closure) }
	public func start() { self.incoming.start() }
	public var result: Data? { return self.incoming.result }
}

public class IncomingJSON {
	var incoming: Incoming<JSONDictionary>
	public init(url: URL, method: Plug.Method = .GET, parameters: Plug.Parameters? = nil, deferredStart: Bool = false) {
		self.incoming = Incoming<JSONDictionary>(url: url, method: method, parameters: parameters, deferredStart: deferredStart) { data in
			return data.json
		}
	}
	
	public func resolved(_ closure: @escaping (JSONDictionary?) -> Void) { self.incoming.resolved(closure) }
	public func start() { self.incoming.start() }
	public var result: JSONDictionary? { return self.incoming.result }
}

open class Incoming<Result> {
	let converter: ((Plug.ConnectionData) -> Result?)?
	public var result: Result?
	public let url: URL
	public let parameters: Plug.Parameters?
	public let method: Plug.Method
	public var isComplete = false
	var pendingClosures: [(Result?) -> Void] = []
	
	public init(url: URL, method: Plug.Method = .GET, parameters: Plug.Parameters? = nil, deferredStart: Bool = false, converter: @escaping (Plug.ConnectionData) -> Result?) {
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
			let bytes = data
			if let convert = self.converter, let result = convert(bytes) {
				self.callClosures(with: result)
			} else {
				self.callClosures(with: nil)
			}
		}.error { [weak self] connn, error in
			self?.callClosures(with: nil)
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
