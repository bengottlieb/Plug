//
//  NetworkActivityIndicator.swift
//  Plug
//
//  Created by Ben Gottlieb on 2/13/15.
//  Copyright (c) 2015 Stand Alone, inc. All rights reserved.
//

import Foundation

var s_NetworkActivityIndicator = NetworkActivityIndicator()

public class NetworkActivityIndicator {
	var usageCount = 0
	
	public class func increment() {
		if s_NetworkActivityIndicator.usageCount == 0 {
			dispatch_async(dispatch_get_main_queue()) {
				UIApplication.sharedApplication().networkActivityIndicatorVisible = true
			}
		}
		s_NetworkActivityIndicator.usageCount++
	}

	public class func decrement() {
		s_NetworkActivityIndicator.usageCount--
		if s_NetworkActivityIndicator.usageCount < 0 {
			println("******** Activity indicator underrun ********")
			s_NetworkActivityIndicator.usageCount = 0
		}
		
		if s_NetworkActivityIndicator.usageCount == 0 {
			dispatch_async(dispatch_get_main_queue()) {
				UIApplication.sharedApplication().networkActivityIndicatorVisible = false
			}
		}
	}
	
	public class var isVisible: Bool {
		return s_NetworkActivityIndicator.usageCount > 0
	}
}