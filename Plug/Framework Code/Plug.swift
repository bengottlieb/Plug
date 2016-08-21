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

public class Plug: NSObject, URLSessionDelegate {
	public enum ConnectionType: Int { case offline, wifi, wan }
	public enum Method: String, CustomStringConvertible { case GET = "GET", POST = "POST", DELETE = "DELETE", PUT = "PUT", PATCH = "PATCH"
		public var description: String { return self.rawValue } 
	}
	
	public func setup(backgroundHandler: BackgroundActivityHandlerProtocol? = nil, networkActivityIndicator: ActivityIndicatorProtocol? = nil) {
		
		self.backgroundActivityHandler = backgroundHandler
		self.networkActivityIndicator = networkActivityIndicator
	}
	
	var backgroundActivityHandler: BackgroundActivityHandlerProtocol?
	var networkActivityIndicator: ActivityIndicatorProtocol?
	
	public enum Persistence { case transient, persistRequest, persistent(Plug.PersistenceInfo)
		public var isPersistent: Bool {
			switch (self) {
			case .transient: return false
			default: return true
			}
		}
		public var persistentDelegate: PlugPersistentDelegate? { return Plug.PersistenceManager.defaultManager.delegateForPersistenceInfo(info: self.persistentInfo) }
		
		public var persistentInfo: Plug.PersistenceInfo? {
			switch (self) {
			case .persistent(let info): return info
			default: return nil
			}
		}
		
		public var JSONValue: Any { return self.persistentInfo?.JSONValue ?? [] }
		
	}
	
	public static let instance = Plug()
	public static var connectionType = ConnectionType.offline
	public static var online: Bool { return self.connectionType != .offline }
	
	public struct notifications {
		public static let onlineStatusChanged = NSNotification.Name("onlineStatusChanged.com.standalone.plug")

		public static let connectionQueued = NSNotification.Name("connectionQueued.com.standalone.plug")
		public static let connectionStarted = NSNotification.Name("connectionStarted.com.standalone.plug")
		public static let connectionCompleted = NSNotification.Name("connectionCompleted.com.standalone.plug")
		public static let connectionCancelled = NSNotification.Name("connectionCancelled.com.standalone.plug")
		public static let connectionFailed = NSNotification.Name("connectionFailed.com.standalone.plug")
	}
	
	public var timeout: TimeInterval? { didSet {
		if timeout != oldValue {
			if self.areConnectionsInFlight {
				NSLog("Unable to set timeout, connections are in flight")
				return
			}
			self.rebuildSession()
		}
	}}
	public var autostartConnections = true
	public var temporaryDirectoryURL = URL(fileURLWithPath: NSTemporaryDirectory())
	public func generateTemporaryFileURL() -> URL {
		let filename = NSUUID().uuidString + ".temp"
		return self.temporaryDirectoryURL.appendingPathComponent(filename)
	}
	public var sessionQueue: OperationQueue = OperationQueue()
	var configuration: URLSessionConfiguration {
		let config = URLSessionConfiguration.default
		
		if let timeout = self.timeout { config.timeoutIntervalForRequest = timeout }
		return config
	}
	public var session: URLSession!
	public var defaultHeaders = Plug.Headers([
			.accept(["application/json"]),
			.acceptEncoding("gzip;q=1.0,compress;q=0.5"),
			.userAgent("plug-\(Bundle.main.bundleIdentifier ?? "")"),
	])
	
	class public var libraryDirectoryURL: URL {
		return URL(fileURLWithPath: NSSearchPathForDirectoriesInDomains(.libraryDirectory, [.userDomainMask], true).first!)
	}
	class public var plugDirectoryURL: URL { return self.libraryDirectoryURL.appendingPathComponent("Plug") }
	
	public override init() {
		let reachabilityClassReference : AnyObject.Type = NSClassFromString("Plug_Reachability")!
		let reachabilityClass : NSObject.Type = reachabilityClassReference as! NSObject.Type
		self.reachability = reachabilityClass.init()

		super.init()
		self.reachability.setValue(self, forKey: "delegate");
		self.rebuildSession()
		
		#if os(iOS)
			NotificationCenter.default.addObserver(self, selector: #selector(didBecomeActive), name: .UIApplicationDidBecomeActive, object: nil)
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
		self.session = URLSession(configuration: self.configuration, delegate: self, delegateQueue: self.sessionQueue)
	}
	
	private var reachability: AnyObject
	func setOnlineViaWifi(_ wifi: Bool, orWAN wan: Bool) {
		var newState = ConnectionType.offline
		
		if wifi {
			newState = .wifi
		} else if wan {
			newState = .wan
		} else {
			newState = .offline
		}
		
		self.updateChannelStates()
		//print("online via WAN: \(wan), wifi: \(wifi)")
		if newState == Plug.connectionType { return }
		
		Plug.connectionType = newState
		DispatchQueue.main.async {
			NotificationCenter.default.post(name: Plug.notifications.onlineStatusChanged, object: nil)
		}
	}
	
	func updateChannelStates() {
		DispatchQueue.main.async {
			for channel in Plug.Channel.allChannels.values {
				if Plug.connectionType == .offline {
					if channel.isRunning { channel.pauseQueue(); channel.pausedReason = .offline }
				} else {
					if channel.pausedReason == .offline || channel.pausedReason == .backgrounding { channel.startQueue() }
				}
			}
		}
	}
	
	internal var channels: [Int: Channel] = [:]
	internal var serialQueue: OperationQueue = { var q = OperationQueue(); q.maxConcurrentOperationCount = 1; return q }()
}

public extension Plug {
	public class func request(method: Method = .GET, url: URLLike, parameters: Plug.Parameters? = nil, persistence: Plug.Persistence = .transient, channel: Plug.Channel = Plug.Channel.defaultChannel) -> Connection {
		return Connection(method: method, url: url, parameters: parameters, persistence: persistence, channel: channel) ?? Connection.noopConnection
	}
}

extension Plug: URLSessionTaskDelegate, URLSessionDownloadDelegate, URLSessionDataDelegate {
//	public func URLSession(session: URLSession, dataTask task: URLSessionDataTask, didReceiveResponse response: URLResponse, completionHandler: (URLSessionResponseDisposition) -> Void) {
//		self[task]?.response = response
//	}

	public func urlSession(_ session: URLSession, dataTask: URLSessionDataTask, didReceive data: Data) {
		guard let task = self[dataTask] else { return }
		
		if task.response == nil { task.response = dataTask.response }
		
		task.received(data)
	}
	
	subscript(toChannel task: URLSessionTask) -> Channel? {
		get {
			var channel: Plug.Channel?
			self.serialQueue.addOperations( [ BlockOperation(block: {
				channel = Plug.instance.channels[task.taskIdentifier]
			} )], waitUntilFinished: true)
			return channel  }
		
		set { self.serialQueue.addOperation { [unowned self] in self.channels[task.taskIdentifier] = newValue } }
	}

	subscript(task: URLSessionTask) -> Connection? {
		get {
			var channel: Plug.Channel?
			self.serialQueue.addOperations( [ BlockOperation(block: {
				channel = Plug.instance.channels[task.taskIdentifier]
			} )], waitUntilFinished: true)
			return channel?[task]  }
		}

	public func urlSession(_ session: URLSession, downloadTask: URLSessionDownloadTask, didFinishDownloadingTo location: URL) {
		
	}

	public func urlSession(_ session: URLSession, task: URLSessionTask, didCompleteWithError error: Error?) {
		if let err = error as? NSError , err.code == -1005 {
			print("++++++++ Simulator comms issue, please restart the sim. ++++++++")
		}
		if let error = error {
			self[task]?.failedWithError(error: error as NSError?)
		} else {
			self[task]?.succeeded()
		}
	}
	
	public func urlSession(_ session: URLSession, task: URLSessionTask, willPerformHTTPRedirection response: HTTPURLResponse, newRequest request: URLRequest, completionHandler: @escaping (URLRequest?) -> Void) {
		print("Received redirect request from \(task.originalRequest)")
		completionHandler(request)
	}


}

extension Plug {
	func register(connection: Connection) {
		if let task = connection.task {
			connection.channel.connections[task.taskIdentifier] = connection
			if connection.persistence.isPersistent { PersistenceManager.defaultManager.register(connection) }
		}
	}
	
	func unregister(connection: Connection) {
		if let task = connection.task {
			connection.channel.connections.removeValue(forKey: task.taskIdentifier)
			if connection.persistence.isPersistent { PersistenceManager.defaultManager.unregister(connection) }
		}
	}
	
	
	
}
