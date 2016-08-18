//
//  PlugConnection.swift
//  Plug
//
//  Created by Ben Gottlieb on 2/9/15.
//  Copyright (c) 2015 Stand Alone, inc. All rights reserved.
//

import Foundation

public typealias PlugCompletionClosure = (Connection, Plug.ConnectionData) -> Void

public class Connection: Hashable, CustomStringConvertible {
	public var state: State = .Waiting {
		didSet {
			if self.state == oldValue { return }
			if oldValue == .Running { Plug.instance.networkActivityIndicator?.decrement() }
			if self.state.isRunning { Plug.instance.networkActivityIndicator?.increment() }
			self.subconnections.forEach { $0.state = self.state }
		}
	}
	
	// set at or immediately after instantiation
	public let method: Plug.Method
	public var URL: NSURL { get { return self.URLLike.URL ?? NSURL() } }
	public var destinationFileURL: NSURL?
	public let requestQueue: NSOperationQueue
	public let parameters: Plug.Parameters
	public var headers: Plug.Headers?
	public let persistence: Plug.Persistence
	public var completionQueue: NSOperationQueue?
	public var completionBlocks: [PlugCompletionClosure] = []
	public var errorBlocks: [(Connection, NSError) -> Void] = []
	public var progressBlocks: [(Connection, Double) -> Void] = []
	public var cachingPolicy: NSURLRequestCachePolicy = .ReloadIgnoringLocalCacheData
	public var coalescing = Coalescing.CoalesceSimilarConnections
	public var tag: Int = 0

	// pertaining to completion, cascaded down to subconnections
	private(set) var startedAt: NSDate? { didSet { self.subconnections.forEach { $0.startedAt = self.startedAt } } }
	private(set) var expectedContentLength: Int64? { didSet { self.subconnections.forEach { $0.expectedContentLength = self.expectedContentLength } } }
	public private(set) var statusCode: Int? { didSet { self.subconnections.forEach { $0.statusCode = self.statusCode } } }
	public private(set) var completedAt: NSDate? { didSet { self.subconnections.forEach { $0.completedAt = self.completedAt } } }
	var task: NSURLSessionTask? { didSet { self.subconnections.forEach { $0.task = self.task } } }
	public private(set) var resultsError: NSError?  { didSet { self.subconnections.forEach { $0.resultsError = self.resultsError } } }
	var resultsData: NSMutableData? { didSet { self.subconnections.forEach { $0.resultsData = self.resultsData } } }
	var bytesReceived: UInt64 = 0 { didSet { self.subconnections.forEach { $0.bytesReceived = self.bytesReceived } } }
	var fileHandle: NSFileHandle! { didSet { self.subconnections.forEach { $0.fileHandle = self.fileHandle } } }
	
	internal(set) var response: NSURLResponse? { didSet {
		if let resp = response as? NSHTTPURLResponse {
			self.responseHeaders = Plug.Headers(dictionary: resp.allHeaderFields)
			self.statusCode = resp.statusCode
		}
		if self.response?.expectedContentLength != -1 {
			self.expectedContentLength = self.response?.expectedContentLength
		}
		self.resultsError = self.response?.error
		self.subconnections.forEach { $0.response = self.response }
	}}

	public var request: NSURLRequest?
	public var responseHeaders: Plug.Headers?
	public let channel: Plug.Channel
	internal let URLLike: NSURLLike
	public var elapsedTime: NSTimeInterval {
		if let startedAt = self.startedAt {
			if let completedAt = self.completedAt {
				return abs(startedAt.timeIntervalSinceDate(completedAt))
			} else {
				return abs(startedAt.timeIntervalSinceNow)
			}
		}
		return 0
	}
	
	public var hashValue: Int {
		return self.URL.hash
	}

	public func addHeader(header: Plug.Header) {
		if self.headers == nil { self.headers = Plug.instance.defaultHeaders }
		self.headers?.append(header)
	}
	
	public var percentComplete: Double = 0.0 {
		didSet {
			if self.percentComplete != oldValue {
				for closure in self.progressBlocks {
					closure(self, self.percentComplete)
				}
				self.subconnections.forEach { $0.percentComplete = self.percentComplete }
			}
		}
	}
	
	var subconnections: [Connection] = []
	var superconnection: Connection?
	
	public init?(method meth: Plug.Method = .GET, URL url: NSURLLike, parameters params: Plug.Parameters? = nil, persistence persist: Plug.Persistence = .Transient, channel chn: Plug.Channel = Plug.Channel.defaultChannel) {
		requestQueue = NSOperationQueue()
		requestQueue.maxConcurrentOperationCount = 1
		
		persistence = persist
		parameters = params ?? .None
		channel = chn
		
		method = parameters.normalizeMethod(meth)
		URLLike = url
		
		//super.init()
		channel.addConnectionToChannel(self)
		if url.URL == nil {
			print("Unable to create a connection with URL: \(url)")

			return nil
		}
		if let header = self.parameters.contentTypeHeader { self.addHeader(header) }

		if Plug.instance.autostartConnections {
			dispatch_after(dispatch_time(DISPATCH_TIME_NOW, Int64(0.5 * Double(NSEC_PER_SEC))), dispatch_get_main_queue()) {
				self.start()
			}
		}
	}
	
	func generateTask() -> NSURLSessionTask? {
		if self.task != nil { return self.task }
		self.task = Plug.instance.session.dataTaskWithRequest(self.request ?? self.defaultRequest)
		
		if let identifier = self.task?.taskIdentifier {
			Plug.instance.channels[identifier] = self.channel
		}
		return self.task
	}
			
	func receivedData(data: NSData) {
		self.bytesReceived += UInt64(data.length)
		if let destURL = self.destinationFileURL, path = destURL.path {
			if self.fileHandle == nil {
				do {
					try NSFileManager.defaultManager().createDirectoryAtURL(destURL.URLByDeletingLastPathComponent!, withIntermediateDirectories: true, attributes: nil)
				} catch let error {
					print("Error while creating directory for file: \(error)")
				}
				
				if !NSFileManager.defaultManager().fileExistsAtPath(path) {
					if !NSFileManager.defaultManager().createFileAtPath(path, contents: nil, attributes: nil) {
						print("Unable to create a file at: \(path)")
					}
				}
				do {
					self.fileHandle = try NSFileHandle(forWritingToURL: destURL)
				} catch let error {
					print("Error while opening file: \(error)")
				}
			}
			self.fileHandle.writeData(data)
		} else {
			if self.resultsData == nil { self.resultsData = NSMutableData() }
			self.resultsData?.appendData(data)
		}
		
		if let total = self.expectedContentLength {
			self.percentComplete = Double(self.bytesReceived) / Double(total)
		}
	}
	
	func succeeded() {
		self.response = self.task?.response
		if let httpResponse = self.response as? NSHTTPURLResponse { self.statusCode = httpResponse.statusCode }
		self.resultsError = self.task?.response?.error
		self.complete(.Completed)
	}
	
	func failedWithError(error: NSError?) {
		if error != nil && error!.code == -1005 && self.superconnection == nil {
			print("++++++++ Simulator comms issue, please restart the sim. ++++++++")
		}
		self.response = self.task?.response
		if let httpResponse = self.response as? NSHTTPURLResponse { self.statusCode = httpResponse.statusCode }
		self.resultsError = error ?? self.task?.response?.error
		self.complete(.CompletedWithError)
	}

	var defaultRequest: NSURLRequest {
		let urlString = self.URL.absoluteString + self.parameters.URLString
		let request = NSMutableURLRequest(URL: NSURL(string: urlString)!)
		let headers = (self.headers ?? Plug.instance.defaultHeaders)
		
		request.allHTTPHeaderFields = headers.dictionary
		request.HTTPMethod = self.method.rawValue
		request.HTTPBody = self.parameters.bodyData
		request.cachePolicy = self.cachingPolicy
		
		return request
	}
	
	public func notifyPersistentDelegateOfCompletion() {
		self.persistence.persistentDelegate?.connectionCompleted(self, info: self.persistence.persistentInfo)
	}

	static var noopConnection: Connection { return Connection(URL: "about:blank")! }

	func handleDownloadedData(data: Plug.ConnectionData) {
		let queue = self.completionQueue ?? NSOperationQueue.mainQueue()
		
		for block in self.completionBlocks {
			let op = NSBlockOperation(block: { block(self, data) })
			queue.addOperations([op], waitUntilFinished: true)
		}
	}
	
}

extension Connection {
	public enum State: String, CustomStringConvertible { case Waiting = "Waiting", Queuing = "Queuing", Queued = "Queued", Running = "Running", Suspended = "Suspended", Completed = "Completed", Canceled = "Canceled", CompletedWithError = "Completed with Error"
		public var description: String { return self.rawValue }
		public var isRunning: Bool { return self == .Running }
		public var hasStarted: Bool { return self != .Waiting && self != .Queued && self != .Queuing }
	}
	
	public enum Coalescing: Int { case CoalesceSimilarConnections, DoNotCoalesceConnections }
}

extension Connection {
	public func completion(completion: PlugCompletionClosure) -> Self {
		self.requestQueue.addOperationWithBlock { self.completionBlocks.append(completion) }
		return self
	}

	public func error(completion: (Connection, NSError) -> Void) -> Self {
		self.requestQueue.addOperationWithBlock { self.errorBlocks.append(completion) }
		return self
	}
	
	public func progress(closure: (Connection, Double) -> Void) -> Self {
		self.requestQueue.addOperationWithBlock { self.progressBlocks.append(closure) }
		return self
	}
}



extension Connection {
	public var description: String { return self.detailedDescription() }

	public func detailedDescription(includeDelimiters: Bool = true) -> String {
		guard let request = self.generateTask()?.originalRequest else { return "--empty connectionu--" }
		var URL = "[no URL]"
		if let url = request.URL { URL = url.description }
		var string = includeDelimiters ? "\n▽▽▽▽▽▽▽▽▽▽▽▽▽▽▽▽▽▽▽▽▽▽▽▽▽▽▽▽▽▽▽▽▽▽▽▽▽▽▽▽▽▽▽▽▽▽▽▽▽▽▽▽▽▽▽▽▽▽▽▽▽▽▽▽▽▽▽\n" : ""
		let durationString = self.elapsedTime > 0.0 ? String(format: "%.2f", self.elapsedTime) + " sec elapsed" : ""
		
		string += "\(self.method) \(URL) \(self.parameters) \(durationString) 〘\(self.state) on \(self.channel.name)〙"
		if let status = self.statusCode { string += " -> \(status)" }

		
		for (label, header) in (self.headers?.dictionary ?? [:]) {
			string += "\n   \(label): \(header)"
		}
		
		if !self.parameters.description.isEmpty {
			string += "\n Parameters: " + self.parameters.description
		}
		
		if self.response != nil {
			string += "\n╍╍╍╍╍╍╍╍╍╍╍╍╍╍╍╍╍╍╍╍╍╍╍╍ [Response] ╍╍╍╍╍╍╍╍╍╍╍╍╍╍╍╍╍╍╍╍╍╍╍╍"
			
			for (label, header) in self.responseHeaders?.dictionary ?? [:] {
				string += "\n   \(label): \(header)"
			}
		}
		if let data = self.resultsData {
			var json: AnyObject?
			do {
				json = try NSJSONSerialization.JSONObjectWithData(data, options: [])
			} catch {
				json = nil
			}

			string += "\n╍╍╍╍╍╍╍╍╍╍╍╍╍╍╍╍╍╍╍╍╍╍╍╍ [Body] ╍╍╍╍╍╍╍╍╍╍╍╍╍╍╍╍╍╍╍╍╍╍╍╍➡︎\n"

			if let json = json as? JSONObject, jString = json.JSONString {
				string += jString
			} else {
				string += (NSString(data: data, encoding: NSUTF8StringEncoding)?.description ?? "--unable to parse data as! UTF8--")
			}
		}
		if !string.hasSuffix("\n") { string += "\n" }
		if includeDelimiters { string +=       "⬅︎△△△△△△△△△△△△△△△△△△△△△△△△△△△△△△△△△△△△△△△△△△△△△△△△△△△△△△△△△△△△△△△△△△△\n" }
		return string
	}
	
	public func logErrorToFile(label: String = "") {
		let errorsDir = Plug.plugDirectoryURL.URLByAppendingPathComponent("Errors")
		let code = self.statusCode ?? 0
		let seconds = Int(NSDate().timeIntervalSinceReferenceDate)
		var host = ""
		if let url = request?.URL { host = url.host ?? "" }
		var filename = "\(code) \(host) \(seconds).txt".stringByReplacingOccurrencesOfString(":", withString: "").stringByReplacingOccurrencesOfString("/", withString: "_")
		if label != "" { filename = label + "- " + filename }
		let filepath = errorsDir.URLByAppendingPathComponent(filename)
		
		do {
			try NSFileManager.defaultManager().createDirectoryAtURL(errorsDir, withIntermediateDirectories: true, attributes: nil)
		} catch _ {
		}
		
		let contents = self.detailedDescription(false)
		
		do {
			try contents.writeToURL(filepath, atomically: true, encoding: NSUTF8StringEncoding)
		} catch _ {
		}
		
	}

	public func log() {
		NSLog("\(self.description)")
	}
	
}

extension Connection {		//actions
	public func start() {
		if (state != .Waiting && state != .Queued && state != .Queuing) { return }
		self.channel.enqueue(self)
	}
	
	public func run() {
		self.channel.connectionStarted(self)
		self.state = .Running
		self.task = self.generateTask()
		Plug.instance.registerConnection(self)
		self.task!.resume()
		self.startedAt = NSDate()
	}
	
	public func suspend() {
		if self.state != .Running { return }
		self.channel.connectionStopped(self)
		self.state = .Suspended
		if self.superconnection == nil { self.task?.suspend() }
	}
	
	public func resume() {
		if self.state != .Suspended { return }
		self.channel.connectionStarted(self)
		self.state = .Running
		if self.superconnection == nil { self.task?.resume() }
	}
	
	public func cancel() {
		self.channel.connectionStopped(self, totallyRemove: true)
		self.state = .Canceled
		if self.superconnection == nil { self.task?.cancel() }
		NSNotificationCenter.defaultCenter().postNotificationName(Plug.notifications.connectionCancelled, object: self)
		self.resultsError = NSError(domain: NSURLErrorDomain, code: Int(CFNetworkErrors.CFURLErrorCancelled.rawValue), userInfo: nil)
		self.complete(.Canceled)
	}
	
	func complete(state: State, parent: Connection? = nil) {
		self.state = state

		if let parent = parent {
			self.completedAt = parent.completedAt
			self.fileHandle = parent.fileHandle
			self.resultsError = parent.resultsError
			self.resultsData = parent.resultsData
			self.bytesReceived = parent.bytesReceived
			self.task = parent.task
			self.fileHandle = parent.fileHandle
		} else {
			self.completedAt = NSDate()
		}
		Plug.instance.unregisterConnection(self)
		self.channel.connectionStopped(self)
		self.channel.dequeue(self)
		self.fileHandle?.closeFile()
		
		let data = Plug.ConnectionData(data: self.resultsData, size: self.bytesReceived) ?? Plug.ConnectionData(URL: self.destinationFileURL, size: self.bytesReceived)
		
		self.requestQueue.addOperationWithBlock {
			if data != nil || self.resultsError == nil {
				self.handleDownloadedData(data ?? Plug.ConnectionData())
			} else {
				if let error = self.resultsError { self.reportError(error) }
			}
		}
		
		self.subconnections.forEach { $0.complete(state, parent: self) }
		self.requestQueue.addOperationWithBlock({ self.notifyPersistentDelegateOfCompletion() })

		if self.state == .Completed {
			NSNotificationCenter.defaultCenter().postNotificationName(Plug.notifications.connectionCompleted, object: self)
		} else {
			NSNotificationCenter.defaultCenter().postNotificationName(Plug.notifications.connectionFailed, object: self, userInfo: (self.resultsError != nil) ? ["error": self.resultsError!] : nil)
		}
	}
	
	func reportError(error: NSError) {
		let queue = self.completionQueue ?? NSOperationQueue.mainQueue()
		
		for block in self.errorBlocks {
			let op = NSBlockOperation(block: { block(self, error) })
			queue.addOperations([op], waitUntilFinished: true)
		}
	}
}

extension Connection {
	func addSubconnection(connection: Connection) {
		self.propagate(connection)
		connection.superconnection = self
		self.subconnections.append(connection)
	}
	
	func propagate(connection: Connection) {
		connection.startedAt = self.startedAt
		connection.expectedContentLength = self.expectedContentLength
		connection.statusCode = self.statusCode
		connection.completedAt = self.completedAt
		connection.resultsError = self.resultsError
		connection.bytesReceived = self.bytesReceived
		connection.fileHandle = self.fileHandle
		connection.task = self.task
	}
}

public func ==(lhs: Connection, rhs: Connection) -> Bool {
	if !lhs.URLLike.isEqual(rhs.URLLike) { return false }
	return lhs.parameters == rhs.parameters && lhs.method == rhs.method
}

