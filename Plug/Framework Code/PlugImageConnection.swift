//
//  PlugImageConnection.swift
//  Plug
//
//  Created by Ben Gottlieb on 4/11/17.
//  Copyright © 2017 Stand Alone, inc. All rights reserved.
//

import Foundation
import CrossPlatformKit
import SwearKit


extension Connection {
	public enum ImageConnectionError: Error { case noImageReturned }

	public func fetchImage() -> Promise<UXImage> {
		let promise = Promise<UXImage>()
		
		self.completion { connection, data in
			if let image = data.image {
				promise.fulfill(image)
			} else {
				promise.reject(ImageConnectionError.noImageReturned)
			}
		}
		
		self.error { connection, error in
			promise.reject(error)
		}
		
		self.start()
		return promise
	}
	
}
