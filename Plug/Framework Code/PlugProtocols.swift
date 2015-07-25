//
//  Protocols.swift
//  Plug
//
//  Created by Ben Gottlieb on 2/9/15.
//  Copyright (c) 2015 Stand Alone, inc. All rights reserved.
//

import Foundation

public protocol NSURLConvertible {
	var URL: NSURL? { get }
}

public protocol NSURLRequestConvertible {
	var URL: NSURLRequest? { get }
}

extension NSURL: NSURLConvertible { public var URL: NSURL? { return self } }
extension String: NSURLConvertible { public var URL: NSURL? { return NSURL(string: self) } }
