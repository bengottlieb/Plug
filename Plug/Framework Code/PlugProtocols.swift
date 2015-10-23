//
//  Protocols.swift
//  Plug
//
//  Created by Ben Gottlieb on 2/9/15.
//  Copyright (c) 2015 Stand Alone, inc. All rights reserved.
//

import Foundation

public protocol NSURLLike {
	var URL: NSURL? { get }
}

public protocol NSURLRequestLike {
	var URL: NSURLRequest? { get }
}

extension NSURL: NSURLLike { public var URL: NSURL? { return self } }
extension String: NSURLLike { public var URL: NSURL? { return NSURL(string: self) } }
