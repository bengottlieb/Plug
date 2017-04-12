//
//  PlugImageConnection.swift
//  Plug
//
//  Created by Ben Gottlieb on 4/11/17.
//  Copyright © 2017 Stand Alone, inc. All rights reserved.
//

import Foundation
import CrossPlatformKit


public typealias PlugImageCompletionClosure = (Connection, UXImage) -> Void

public class ImageConnection: Connection {
	public enum ImageConnectionError: Error { case noImageReturned }
	
	public var imageCompletionBlocks: [PlugImageCompletionClosure] = []
	
	override func handleDownload(data: Plug.ConnectionData) {
		let queue = self.completionQueue ?? OperationQueue.main
		if let image = data.image {
			for block in self.imageCompletionBlocks {
				let op = BlockOperation(block: { block(self, image) })
				queue.addOperations([op], waitUntilFinished: true)
			}
			return
		}
		self.reportError(error: ImageConnectionError.noImageReturned)
	}
	
	
	public func completion(completion: @escaping PlugImageCompletionClosure) -> Self {
		self.requestQueue.addOperation { self.imageCompletionBlocks.append(completion) }
		return self
	}
	
}
