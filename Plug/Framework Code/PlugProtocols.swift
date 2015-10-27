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
	func isEqual(other: NSURLLike) -> Bool
}

public protocol NSURLRequestLike {
	var URL: NSURLRequest? { get }
}

extension NSURL: NSURLLike {
	public var URL: NSURL? { return self }
	public func isEqual(object: NSURLLike) -> Bool {
		if let other = object as? NSURL { return other.absoluteString == self.absoluteString }
		return false
	}
}
extension String: NSURLLike {
	public var URL: NSURL? { return NSURL(string: self) }
	public func isEqual(object: NSURLLike) -> Bool {
		if let other = object as? String { return other == self }
		return false
	}
}

func ==(lhs: NSURLLike, rhs: NSURLLike) -> Bool {
	return lhs.isEqual(rhs)
}