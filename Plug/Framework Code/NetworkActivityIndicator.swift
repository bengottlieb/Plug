//
//  NetworkActivityIndicator.swift
//  Plug
//
//  Created by Ben Gottlieb on 2/13/15.
//  Copyright (c) 2015 Stand Alone, inc. All rights reserved.
//

import Foundation

public class NetworkActivityIndicator {
	public class var sharedIndicator: NetworkActivityIndicator { struct s { static let indicator = NetworkActivityIndicator() }; return s.indicator }
	
	var usageCount = 0
	
	public func increment() {
		if self.usageCount == 0 {
			dispatch_async(dispatch_get_main_queue()) {
				UIApplication.sharedApplication().networkActivityIndicatorVisible = true
			}
		}
		self.usageCount++
	}

	public func decrement() {
		self.usageCount--
		if self.usageCount < 0 {
			println("******** Activity indicator underrun ********")
			self.usageCount = 0
		}
		
		if self.usageCount == 0 {
			dispatch_async(dispatch_get_main_queue()) {
				UIApplication.sharedApplication().networkActivityIndicatorVisible = false
			}
		}
	}
}