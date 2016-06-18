//
//  PlugJSONConnection.swift
//  Plug
//
//  Created by Ben Gottlieb on 5/20/16.
//  Copyright © 2016 Stand Alone, inc. All rights reserved.
//

import Foundation

public typealias PlugJSONDictionaryCompletionClosure = (Connection, JSONDictionary) -> Void
public typealias PlugJSONArrayCompletionClosure = (Connection, JSONArray) -> Void

public class JSONConnection: Connection {
	
	public var jsonDictionaryCompletionBlocks: [PlugJSONDictionaryCompletionClosure] = []
	public var jsonArrayCompletionBlocks: [PlugJSONArrayCompletionClosure] = []
	
	override func handleDownload(data: Plug.ConnectionData) {
		let queue = self.completionQueue ?? OperationQueue.main()
		if let json = data.data.jsonContainer() {
			if let dict = json as? JSONDictionary {
				if self.jsonDictionaryCompletionBlocks.count == 0 {	//we got a dictionary, but weren't expecting it
					print("Unexpected Dictionary from \(self).")
					self.reportError(error: NSError(domain: NSError.PlugJSONErrorDomain, code: NSError.JSONErrors.UnexpectedJSONDictionary.rawValue, userInfo: ["connection": self]))
				}
				for block in self.jsonDictionaryCompletionBlocks {
					let op = BlockOperation(block: { block(self, dict) })
					queue.addOperations([op], waitUntilFinished: true)
				}
				return
			} else if let array = json as? JSONArray {
				if self.jsonArrayCompletionBlocks.count == 0 {	//we got a dictionary, but weren't expecting it
					print("Unexpected Array from \(self).")
					self.reportError(error: NSError(domain: NSError.PlugJSONErrorDomain, code: NSError.JSONErrors.UnexpectedJSONArray.rawValue, userInfo: ["connection": self]))
				}
				for block in self.jsonArrayCompletionBlocks {
					let op = BlockOperation(block: { block(self, array) })
					queue.addOperations([op], waitUntilFinished: true)
				}
				return
			}
		}
		self.reportError(error: NSError(domain: NSError.PlugJSONErrorDomain, code: NSError.JSONErrors.UnableToFindJSONContainer.rawValue, userInfo: nil))
	}

	public func completion(completion: PlugJSONDictionaryCompletionClosure) -> Self {
		self.requestQueue.addOperation { self.jsonDictionaryCompletionBlocks.append(completion) }
		return self
	}
	
	public func completion(completion: PlugJSONArrayCompletionClosure) -> Self {
		self.requestQueue.addOperation { self.jsonArrayCompletionBlocks.append(completion) }
		return self
	}
	

}
