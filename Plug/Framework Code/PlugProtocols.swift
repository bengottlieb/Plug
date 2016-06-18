//
//  Protocols.swift
//  Plug
//
//  Created by Ben Gottlieb on 2/9/15.
//  Copyright (c) 2015 Stand Alone, inc. All rights reserved.
//

import Foundation

public protocol URLLike {
	var url: URL? { get }
	func isEqual(other: URLLike) -> Bool
}

public protocol URLRequestLike {
	var url: URLRequest? { get }
}

extension URL: URLLike {
	public var url: URL? { return self }
	public func isEqual(other object: URLLike) -> Bool {
		if let other = object as? URL { return other.absoluteString == self.absoluteString }
		return false
	}
}
extension String: URLLike {
	public var url: URL? { return URL(string: self) }
	public func isEqual(other object: URLLike) -> Bool {
		if let other = object as? String { return other == self }
		return false
	}
}

func ==(lhs: URLLike, rhs: URLLike) -> Bool {
	return lhs.isEqual(other: rhs)
}
