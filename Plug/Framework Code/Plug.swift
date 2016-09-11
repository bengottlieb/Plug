//
//  Plug.swift
//  Plug
//
//  Created by Ben Gottlieb on 2/9/15.
//  Copyright (c) 2015 Stand Alone, inc. All rights reserved.
//

import Foundation

#if os(iOS)
	import UIKit
#endif


public protocol ActivityIndicatorProtocol {
	func decrement()
	func increment()
}

#if os(OSX)
	public typealias UIBackgroundTaskIdentifier = Int
#endif

public protocol BackgroundActivityHandlerProtocol {
	func beginBackgroundTaskWithName(taskName: String?, expirationHandler handler: (() -> Void)?) -> UIBackgroundTaskIdentifier
	func endBackgroundTask(identifier: UIBackgroundTaskIdentifier)
}

public class Plug: NSObject, NSURLSessionDelegate {
	public enum ConnectionType: Int { case Offline, Wifi, WAN }
	public enum Method: String, CustomStringConvertible { case GET = "GET", POST = "POST", DELETE = "DELETE", PUT = "PUT", PATCH = "PATCH"
		public var description: String { return self.rawValue } 
	}
	
	public func setup(backgroundHandler: BackgroundActivityHandlerProtocol? = nil, networkActivityIndicator: ActivityIndicatorProtocol?) {
		
		self.backgroundActivityHandler = backgroundHandler
		self.networkActivityIndicator = networkActivityIndicator
	}
	
	var backgroundActivityHandler: BackgroundActivityHandlerProtocol?
	var networkActivityIndicator: ActivityIndicatorProtocol?
	
	public enum Persistence { case Transient, PersistRequest, Persistent(Plug.PersistenceInfo)
		public var isPersistent: Bool {
			switch (self) {
			case .Transient: return false
			default: return true
			}
		}
		public var persistentDelegate: PlugPersistentDelegate? { return Plug.PersistenceManager.defaultManager.delegateForPersistenceInfo(self.persistentInfo) }
		
		public var persistentInfo: Plug.PersistenceInfo? {
			switch (self) {
			case .Persistent(let info): return info
			default: return nil
			}
		}
		
		public var JSONValue: AnyObject { return self.persistentInfo?.JSONValue ?? [] }
		
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
		if timeout != oldValue {
			if self.areConnectionsInFlight {
				NSLog("Unable to set timeout, connections are in flight")
				return
			}
			self.rebuildSession()
		}
	}}
	public var autostartConnections = true
	public var temporaryDirectoryURL = NSURL(fileURLWithPath: NSTemporaryDirectory())
	public func generateTemporaryFileURL() -> NSURL {
		let filename = NSUUID().UUIDString + ".temp"
		return self.temporaryDirectoryURL.URLByAppendingPathComponent(filename)!
	}
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
	class public var plugDirectoryURL: NSURL { return self.libraryDirectoryURL.URLByAppendingPathComponent("Plug")! }
	
	public override init() {
		let reachabilityClassReference : AnyObject.Type = NSClassFromString("Plug_Reachability")!
		let reachabilityClass : NSObject.Type = reachabilityClassReference as! NSObject.Type
		self.reachability = reachabilityClass.init()

		super.init()
		self.reachability.setValue(self, forKey: "delegate");
		self.rebuildSession()
		
		#if os(iOS)
			NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(didBecomeActive), name: UIApplicationDidBecomeActiveNotification, object: nil)
		#endif
	}
	
	public func didBecomeActive() {
		Channel.restartAllChannels()
	}
	
	public var areConnectionsInFlight: Bool {
		for (_, channel) in Plug.Channel.allChannels {
			if channel.activeConnections.count > 0 {
				return true
			}
		}
		return false
	}
	
	public func rebuildSession() {
		self.session = NSURLSession(configuration: self.configuration, delegate: self, delegateQueue: self.sessionQueue)
	}
	
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
	public class func request(method: Method = .GET, URL: NSURLLike, parameters: Plug.Parameters? = nil, persistence: Plug.Persistence = .Transient, channel: Plug.Channel = Plug.Channel.defaultChannel) -> Connection {
		return Connection(method: method, URL: URL, parameters: parameters, persistence: persistence, channel: channel) ?? Connection.noopConnection
	}
}

extension Plug: NSURLSessionTaskDelegate, NSURLSessionDownloadDelegate, NSURLSessionDataDelegate {
//	public func URLSession(session: NSURLSession, dataTask task: NSURLSessionDataTask, didReceiveResponse response: NSURLResponse, completionHandler: (NSURLSessionResponseDisposition) -> Void) {
//		self[task]?.response = response
//	}

	public func URLSession(session: NSURLSession, dataTask: NSURLSessionDataTask, didReceiveData data: NSData) {
		guard let task = self[dataTask] else { return }
		
		if task.response == nil { task.response = dataTask.response }
		
		task.receivedData(data)
	}
	
	subscript(toChannel task: NSURLSessionTask) -> Plug.Channel? {
		get {
			var channel: Plug.Channel?
			self.serialQueue.addOperations( [ NSBlockOperation(block: {
				channel = Plug.instance.channels[task.taskIdentifier]
			} )], waitUntilFinished: true)
			return channel  }
		
		set { self.serialQueue.addOperationWithBlock { [unowned self] in self.channels[task.taskIdentifier] = newValue } }
	}

	subscript(task: NSURLSessionTask) -> Connection? {
		get {
			var channel: Plug.Channel?
			self.serialQueue.addOperations( [ NSBlockOperation(block: {
				channel = Plug.instance.channels[task.taskIdentifier]
			} )], waitUntilFinished: true)
			return channel?[task]  }
		}

	public func URLSession(session: NSURLSession, downloadTask: NSURLSessionDownloadTask, didFinishDownloadingToURL location: NSURL) {
		
	}

	public func URLSession(session: NSURLSession, task: NSURLSessionTask, didCompleteWithError error: NSError?) {
		if let err = error where err.code == -1005 {
			print("++++++++ Simulator comms issue, please restart the sim. ++++++++")
		}
		if let error = error {
			self[task]?.failedWithError(error)
		} else {
			self[task]?.succeeded()
		}
	}
	
	public func URLSession(session: NSURLSession, task: NSURLSessionTask, willPerformHTTPRedirection response: NSHTTPURLResponse, newRequest request: NSURLRequest, completionHandler: (NSURLRequest?) -> Void) {
		print("Received redirect request from \(task.originalRequest)")
		completionHandler(request)
	}


}

extension Plug {
	func registerConnection(connection: Connection) {
		if let task = connection.task {
			connection.channel.connections[task.taskIdentifier] = connection
			if connection.persistence.isPersistent { PersistenceManager.defaultManager.registerPersisitentConnection(connection) }
		}
	}
	
	func unregisterConnection(connection: Connection) {
		if let task = connection.task {
			connection.channel.connections.removeValueForKey(task.taskIdentifier)
			if connection.persistence.isPersistent { PersistenceManager.defaultManager.unregisterPersisitentConnection(connection) }
		}
	}
	
	
	
}
