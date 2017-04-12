//
//  PlugJSONConnection.swift
//  Plug
//
//  Created by Ben Gottlieb on 5/20/16.
//  Copyright © 2016 Stand Alone, inc. All rights reserved.
//

import Foundation
import SwearKit


extension Connection {
	public enum JSONConnectionError: Error { case noJSONReturned }
	
	public func fetchJSON() -> Promise<JSONDictionary> {
		let promise = Promise<JSONDictionary>()
		
		self.completion { connection, data in
			if let json = data.json {
				promise.fulfill(json)
			} else {
				promise.reject(JSONConnectionError.noJSONReturned)
			}
		}
		
		self.error { connection, error in
			promise.reject(error)
		}
		
		self.start()
		return promise
	}
	
}
