//
//  Plug.swift
//  Plug
//
//  Created by Ben Gottlieb on 2/9/15.
//  Copyright (c) 2015 Stand Alone, inc. All rights reserved.
//

import Foundation

public class Plug: NSObject {
	public enum Method: String, Printable { case GET = "GET", POST = "POST", DELETE = "DELETE", PUT = "PUT", PATCH = "PATCH"
		public var description: String { return self.rawValue } 
	}
	
	public class var defaultManager: Plug { struct s { static let plug = Plug() }; return s.plug }
	
	public var autostartConnections = true
	public var temporaryDirectoryURL = NSURL(fileURLWithPath: NSTemporaryDirectory())!
	public var sessionQueue: NSOperationQueue = NSOperationQueue()
	public var configuration = NSURLSessionConfiguration.defaultSessionConfiguration()
	public var session: NSURLSession!
	public var defaultHeaders = Plug.Headers([
			.Accept(["application/json"]),
			.AcceptEncoding("gzip;q=1.0,compress;q=0.5"),
			.UserAgent("Plug-\(NSBundle.mainBundle().bundleIdentifier!)"),
	])
	
	public override init() {
		super.init()

		self.session = NSURLSession(configuration: self.configuration, delegate: self, delegateQueue: self.sessionQueue)
	
	}
	
	private var connections: [Int: Plug.Connection] = [:]
	private var serialQueue: NSOperationQueue = { var q = NSOperationQueue(); q.maxConcurrentOperationCount = 1; return q }()
}

public extension Plug {
	public class func request(method: Method = .GET, URL: NSURLConvertible, parameters: Plug.Parameters? = nil, relevance: Plug.Connection.ResponseRelevance = .Transient) -> Plug.Connection {
		var connection = Plug.Connection(method: method, URL: URL, parameters: parameters, relevance: relevance)
		
		return connection ?? self.defaultManager.noopConnection
	}
}

extension Plug: NSURLSessionDataDelegate {
	
}

extension Plug: NSURLSessionDownloadDelegate {
	public func URLSession(session: NSURLSession, downloadTask: NSURLSessionDownloadTask, didFinishDownloadingToURL location: NSURL) {
		self[downloadTask]?.completedDownloadingToURL(location)
	}

	public func URLSession(session: NSURLSession, task: NSURLSessionTask, didCompleteWithError error: NSError?) {
		self[task]?.failedWithError(error)
	}
	
	public func URLSession(session: NSURLSession, task: NSURLSessionTask, willPerformHTTPRedirection response: NSHTTPURLResponse, newRequest request: NSURLRequest, completionHandler: (NSURLRequest!) -> Void) {
		println("Received redirect request from \(task.originalRequest)")
		completionHandler(request)
	}


}

extension Plug {
	
	func registerConnection(connection: Plug.Connection) {
		self.connections[connection.task.taskIdentifier] = connection
	}
	
	subscript(task: NSURLSessionTask) -> Plug.Connection? {
		get { var connection: Plug.Connection?; self.serialQueue.addOperations( [ NSBlockOperation(block: { connection = self.connections[task.taskIdentifier] } )], waitUntilFinished: true); return connection  }
		set { self.serialQueue.addOperationWithBlock { self.connections[task.taskIdentifier] = newValue } }
	}
	
	
}