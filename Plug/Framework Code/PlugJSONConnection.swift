//
//  PlugJSONConnection.swift
//  Plug
//
//  Created by Ben Gottlieb on 5/20/16.
//  Copyright © 2016 Stand Alone, inc. All rights reserved.
//

import Foundation

public typealias PlugJSONCompletionClosure = (Connection, JSONDictionary) -> Void
public typealias PlugJSONArrayCompletionClosure = (Connection, JSONArray) -> Void

public class JSONConnection: Connection {
	
	public var jsonCompletionBlocks: [PlugJSONCompletionClosure] = []
	public var jsonArrayCompletionBlocks: [PlugJSONArrayCompletionClosure] = []
	
	override func handleDownloadedData(data: Plug.ConnectionData) {
		let queue = self.completionQueue ?? NSOperationQueue.mainQueue()
		if let json = data.data.jsonContainer() {
			if let dict = json as? JSONDictionary {
				for block in self.jsonCompletionBlocks {
					let op = NSBlockOperation(block: { block(self, dict) })
					queue.addOperations([op], waitUntilFinished: true)
				}
				return
			} else if let array = json as? JSONArray {
				for block in self.jsonArrayCompletionBlocks {
					let op = NSBlockOperation(block: { block(self, array) })
					queue.addOperations([op], waitUntilFinished: true)
				}
				return
			}
		}
		let error = NSError(domain: NSError.PlugJSONErrorDomain, code: NSError.JSONErrors.UnableToFindJSONContainer.rawValue, userInfo: nil)
		
		for block in self.errorBlocks {
			let op = NSBlockOperation(block: { block(self, error) })
			queue.addOperations([op], waitUntilFinished: true)
		}
	}

	public func completion(completion: PlugJSONCompletionClosure) -> Self {
		self.requestQueue.addOperationWithBlock { self.jsonCompletionBlocks.append(completion) }
		return self
	}
	
	public func completion(completion: PlugJSONArrayCompletionClosure) -> Self {
		self.requestQueue.addOperationWithBlock { self.jsonArrayCompletionBlocks.append(completion) }
		return self
	}
	

}