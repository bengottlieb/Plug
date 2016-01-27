//
//  Plug.swift
//  Plug
//
//  Created by Ben Gottlieb on 2/9/15.
//  Copyright (c) 2015 Stand Alone, inc. All rights reserved.
//

import Foundation

public class Plug: NSObject {
	public enum ConnectionType: Int { case Offline, Wifi, WAN }
	public enum Method: String, CustomStringConvertible { case GET = "GET", POST = "POST", DELETE = "DELETE", PUT = "PUT", PATCH = "PATCH"
		public var description: String { return self.rawValue } 
	}
	
	public static let instance = Plug()
	public static var connectionType = ConnectionType.Offline
	public static var online: Bool { return self.connectionType != .Offline }
	
	public struct notifications {
		public static let onlineStatusChanged = "onlineStatusChanged.com.standalone.plug"

		public static let connectionQueued = "connectionQueued.com.standalone.plug"
		public static let connectionStarted = "connectionStarted.com.standalone.plug"
		public static let connectionCompleted = "connectionCompleted.com.standalone.plug"
		public static let connectionCancelled = "connectionCancelled.com.standalone.plug"
		public static let connectionFailed = "connectionFailed.com.standalone.plug"
	}
	
	public var timeout: NSTimeInterval? { didSet {
		self.rebuildSession()
	}}
	public var autostartConnections = true
	public var temporaryDirectoryURL = NSURL(fileURLWithPath: NSTemporaryDirectory())
	public var sessionQueue: NSOperationQueue = NSOperationQueue()
	var configuration: NSURLSessionConfiguration {
		let config = NSURLSessionConfiguration.defaultSessionConfiguration()
		
		if let timeout = self.timeout { config.timeoutIntervalForRequest = timeout }
		return config
	}
	public var session: NSURLSession!
	public var defaultHeaders = Plug.Headers([
			.Accept(["application/json"]),
			.AcceptEncoding("gzip;q=1.0,compress;q=0.5"),
			.UserAgent("plug-\(NSBundle.mainBundle().bundleIdentifier ?? String())"),
	])
	
	class public var libraryDirectoryURL: NSURL {
		return NSURL(fileURLWithPath: NSSearchPathForDirectoriesInDomains(.LibraryDirectory, [.UserDomainMask], true).first!)
	}
	class public var plugDirectoryURL: NSURL { return self.libraryDirectoryURL.URLByAppendingPathComponent("Plug") }
	
	public override init() {
		let reachabilityClassReference : AnyObject.Type = NSClassFromString("Plug_Reachability")!
		let reachabilityClass : NSObject.Type = reachabilityClassReference as! NSObject.Type
		self.reachability = reachabilityClass.init()

		super.init()
		self.reachability.setValue(self, forKey: "delegate");
		self.rebuildSession()
	}
	
	public func rebuildSession() {
		NSLog("Building session, timeout: \(self.timeout)")
		self.session = NSURLSession(configuration: self.configuration, delegate: self, delegateQueue: self.sessionQueue)
	}
	
	
	public func setup() {}

	private var reachability: AnyObject
	func setOnlineViaWifi(wifi: Bool, orWAN wan: Bool) {
		var newState = ConnectionType.Offline
		
		if wifi {
			newState = .Wifi
		} else if wan {
			newState = .WAN
		} else {
			newState = .Offline
		}
		
		self.updateChannelStates()
		//print("online via WAN: \(wan), wifi: \(wifi)")
		if newState == Plug.connectionType { return }
		
		Plug.connectionType = newState
		dispatch_async(dispatch_get_main_queue()) {
			NSNotificationCenter.defaultCenter().postNotificationName(Plug.notifications.onlineStatusChanged, object: nil)
		}
	}
	
	func updateChannelStates() {
		dispatch_async(dispatch_get_main_queue()) {
			for channel in Plug.Channel.allChannels.values {
				if Plug.connectionType == .Offline {
					if channel.queueState == .Running { channel.pauseQueue(); channel.queueState = .PausedDueToOffline }
				} else {
					if channel.queueState == .PausedDueToOffline { channel.startQueue() }
				}
			}
		}
	}
	
	internal var channels: [Int: Plug.Channel] = [:]
	internal var serialQueue: NSOperationQueue = { var q = NSOperationQueue(); q.maxConcurrentOperationCount = 1; return q }()
}

public extension Plug {
	public class func request(method: Method = .GET, URL: NSURLLike, parameters: Plug.Parameters? = nil, persistence: Plug.Connection.Persistence = .Transient, channel: Plug.Channel = Plug.Channel.defaultChannel) -> Plug.Connection {
		if let connection = channel.existingConnectionWithMethod(method, URL: URL, parameters: parameters) {
			return connection
		}
		
		if let connection = Plug.Connection(method: method, URL: URL, parameters: parameters, persistence: persistence, channel: channel) {
			return connection
		}
		
		return self.noopConnection
	}
}

extension Plug: NSURLSessionDataDelegate {
	
}

extension Plug: NSURLSessionTaskDelegate, NSURLSessionDownloadDelegate {
	
	subscript(task: NSURLSessionTask) -> Plug.Channel? {
		get {
			var channel: Plug.Channel?
			self.serialQueue.addOperations( [ NSBlockOperation(block: {
				channel = Plug.instance.channels[task.taskIdentifier]
			} )], waitUntilFinished: true)
			return channel  }
		
		set { self.serialQueue.addOperationWithBlock { [unowned self] in self.channels[task.taskIdentifier] = newValue } }
	}
	
	public func URLSession(session: NSURLSession, downloadTask: NSURLSessionDownloadTask, didFinishDownloadingToURL location: NSURL) {
		self[downloadTask]?[downloadTask]?.completedDownloadingToURL(location)
	}

	public func URLSession(session: NSURLSession, task: NSURLSessionTask, didCompleteWithError error: NSError?) {
		self[task]?[task]?.failedWithError(error)
	}
	
	public func URLSession(session: NSURLSession, task: NSURLSessionTask, willPerformHTTPRedirection response: NSHTTPURLResponse, newRequest request: NSURLRequest, completionHandler: (NSURLRequest?) -> Void) {
		print("Received redirect request from \(task.originalRequest)")
		completionHandler(request)
	}


}

extension Plug {
	func registerConnection(connection: Plug.Connection) {
		if let task = connection.task {
			connection.channel.connections[task.taskIdentifier] = connection
			if connection.persistence.isPersistent { PersistenceManager.defaultManager.registerPersisitentConnection(connection) }
		}
	}
	
	func unregisterConnection(connection: Plug.Connection) {
		if let task = connection.task {
			connection.channel.connections.removeValueForKey(task.taskIdentifier)
			if connection.persistence.isPersistent { PersistenceManager.defaultManager.unregisterPersisitentConnection(connection) }
		}
	}
	
	
	
}