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
	public var url: URL { get { return self.urlLike.url ?? URL(string: "about:blank")! } }
	public var destinationFileURL: URL?
	public let requestQueue: OperationQueue
	public let parameters: Plug.Parameters
	public var headers: Plug.Headers?
	public let persistence: Plug.Persistence
	public var completionQueue: OperationQueue?
	public var completionBlocks: [PlugCompletionClosure] = []
	public var errorBlocks: [(Connection, NSError) -> Void] = []
	public var progressBlocks: [(Connection, Double) -> Void] = []
	public var cachingPolicy: URLRequest.CachePolicy = .reloadIgnoringLocalCacheData
	public var coalescing = Coalescing.CoalesceSimilarConnections
	public var tag: Int = 0

	// pertaining to completion, cascaded down to subconnections
	private(set) var startedAt: Date? { didSet { self.subconnections.forEach { $0.startedAt = self.startedAt } } }
	private(set) var expectedContentLength: Int64? { didSet { self.subconnections.forEach { $0.expectedContentLength = self.expectedContentLength } } }
	public private(set) var statusCode: Int? { didSet { self.subconnections.forEach { $0.statusCode = self.statusCode } } }
	public private(set) var completedAt: Date? { didSet { self.subconnections.forEach { $0.completedAt = self.completedAt } } }
	var task: URLSessionTask? { didSet { self.subconnections.forEach { $0.task = self.task } } }
	public private(set) var resultsError: NSError?  { didSet { self.subconnections.forEach { $0.resultsError = self.resultsError } } }
	var resultsData: Data? { didSet { self.subconnections.forEach { $0.resultsData = self.resultsData } } }
	var bytesReceived: UInt64 = 0 { didSet { self.subconnections.forEach { $0.bytesReceived = self.bytesReceived } } }
	var fileHandle: FileHandle! { didSet { self.subconnections.forEach { $0.fileHandle = self.fileHandle } } }
	
	internal(set) var response: URLResponse? { didSet {
		if let resp = response as? HTTPURLResponse {
			self.responseHeaders = Plug.Headers(dictionary: resp.allHeaderFields)
			self.statusCode = resp.statusCode
		}
		if self.response?.expectedContentLength != -1 {
			self.expectedContentLength = self.response?.expectedContentLength
		}
		self.resultsError = self.response?.error
		self.subconnections.forEach { $0.response = self.response }
	}}

	public var request: URLRequest?
	public var responseHeaders: Plug.Headers?
	public let channel: Plug.Channel
	internal let urlLike: URLLike
	public var elapsedTime: TimeInterval {
		if let startedAt = self.startedAt {
			if let completedAt = self.completedAt {
				return abs(startedAt.timeIntervalSince(completedAt))
			} else {
				return abs(startedAt.timeIntervalSinceNow)
			}
		}
		return 0
	}
	
	public var hashValue: Int {
		return self.url.absoluteString!.hash
	}

	public func addHeader(header: Plug.Header) {
		if self.headers == nil { self.headers = Plug.instance.defaultHeaders }
		self.headers?.append(header: header)
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
	
	public init?(method meth: Plug.Method = .GET, url: URLLike, parameters params: Plug.Parameters? = nil, persistence persist: Plug.Persistence = .Transient, channel chn: Plug.Channel = Plug.Channel.defaultChannel) {
		requestQueue = OperationQueue()
		requestQueue.maxConcurrentOperationCount = 1
		
		persistence = persist
		parameters = params ?? .None
		channel = chn
		
		method = parameters.normalizeMethod(method: meth)
		urlLike = url
		
		//super.init()
		channel.addToChannel(connection: self)
		if url.url == nil {
			print("Unable to create a connection with URL: \(url)")

			return nil
		}
		if let header = self.parameters.contentTypeHeader { self.addHeader(header: header) }

		if Plug.instance.autostartConnections {
			DispatchQueue.main.after(when: DispatchTime.now() + 0.5) {
				self.start()
			}
		}
	}
	
	func generateTask() -> URLSessionTask? {
		if self.task != nil { return self.task }
		self.task = Plug.instance.session.dataTask(with: self.request ?? self.defaultRequest)
		
		if let identifier = self.task?.taskIdentifier {
			Plug.instance.channels[identifier] = self.channel
		}
		return self.task
	}
			
	func received(_ data: Data) {
		self.bytesReceived += UInt64(data.count)
		if let destURL = self.destinationFileURL, let path = destURL.path {
			if self.fileHandle == nil {
				do {
					try FileManager.default.createDirectory(at: destURL.deletingLastPathComponent(), withIntermediateDirectories: true, attributes: nil)
				} catch let error {
					print("Error while creating directory for file: \(error)")
				}
				
				if !FileManager.default.fileExists(atPath: path) {
					if !FileManager.default.createFile(atPath: path, contents: nil, attributes: nil) {
						print("Unable to create a file at: \(path)")
					}
				}
				do {
					self.fileHandle = try FileHandle(forWritingTo: destURL)
				} catch let error {
					print("Error while opening file: \(error)")
				}
			}
			self.fileHandle.write(data)
		} else {
			if self.resultsData == nil { self.resultsData = Data() }
			self.resultsData?.append(data)
		}
		
		if let total = self.expectedContentLength {
			self.percentComplete = Double(self.bytesReceived) / Double(total)
		}
	}
	
	func succeeded() {
		self.response = self.task?.response
		if let httpResponse = self.response as? HTTPURLResponse { self.statusCode = httpResponse.statusCode }
		self.resultsError = self.task?.response?.error
		self.complete(state: .Completed)
	}
	
	func failedWithError(error: NSError?) {
		if error != nil && error!.code == -1005 && self.superconnection == nil {
			print("++++++++ Simulator comms issue, please restart the sim. ++++++++")
		}
		self.response = self.task?.response
		if let httpResponse = self.response as? HTTPURLResponse { self.statusCode = httpResponse.statusCode }
		self.resultsError = error ?? self.task?.response?.error
		self.complete(state: .CompletedWithError)
	}

	var defaultRequest: URLRequest {
		let urlString = self.url.absoluteString! + self.parameters.URLString
		var request = URLRequest(url: URL(string: urlString)!)
		let headers = (self.headers ?? Plug.instance.defaultHeaders)
		
		request.allHTTPHeaderFields = headers.dictionary
		request.httpMethod = self.method.rawValue
		request.httpBody = self.parameters.bodyData
		request.cachePolicy = self.cachingPolicy
		
		return request
	}
	
	public func notifyPersistentDelegateOfCompletion() {
		self.persistence.persistentDelegate?.connectionCompleted(connection: self, info: self.persistence.persistentInfo)
	}

	static var noopConnection: Connection { return Connection(JSONRepresentation: ["url": "about:blank"])! }

	func handleDownload(data: Plug.ConnectionData) {
		let queue = self.completionQueue ?? OperationQueue.main
		
		for block in self.completionBlocks {
			let op = BlockOperation(block: { block(self, data) })
			queue.addOperations([op], waitUntilFinished: true)
		}
	}
	
}

extension Connection {
	public enum State: String, CustomStringConvertible { case Waiting = "Waiting", Queued = "Queued", Running = "Running", Suspended = "Suspended", Completed = "Completed", Canceled = "Canceled", CompletedWithError = "Completed with Error"
		public var description: String { return self.rawValue }
		public var isRunning: Bool { return self == .Running }
		public var hasStarted: Bool { return self != .Waiting && self != .Queued }
	}
	
	public enum Coalescing: Int { case CoalesceSimilarConnections, DoNotCoalesceConnections }
}

extension Connection {
	public func completion(completion: PlugCompletionClosure) -> Self {
		self.requestQueue.addOperation { self.completionBlocks.append(completion) }
		return self
	}

	public func error(completion: (Connection, NSError) -> Void) -> Self {
		self.requestQueue.addOperation { self.errorBlocks.append(completion) }
		return self
	}
	
	public func progress(closure: (Connection, Double) -> Void) -> Self {
		self.requestQueue.addOperation { self.progressBlocks.append(closure) }
		return self
	}
}



extension Connection {
	public var description: String { return self.detailedDescription() }

	public func detailedDescription(includeDelimiters: Bool = true) -> String {
		guard let request = self.generateTask()?.originalRequest else { return "--empty connectionu--" }
		var url = "[no URL]"
		if let requestURL = request.url { url = requestURL.description }
		var string = includeDelimiters ? "\n▽▽▽▽▽▽▽▽▽▽▽▽▽▽▽▽▽▽▽▽▽▽▽▽▽▽▽▽▽▽▽▽▽▽▽▽▽▽▽▽▽▽▽▽▽▽▽▽▽▽▽▽▽▽▽▽▽▽▽▽▽▽▽▽▽▽▽\n" : ""
		let durationString = self.elapsedTime > 0.0 ? String(format: "%.2f", self.elapsedTime) + " sec elapsed" : ""
		
		string += "\(self.method) \(url) \(self.parameters) \(durationString) 〘\(self.state) on \(self.channel.name)〙"
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
				json = try JSONSerialization.jsonObject(with: data, options: [])
			} catch {
				json = nil
			}

			string += "\n╍╍╍╍╍╍╍╍╍╍╍╍╍╍╍╍╍╍╍╍╍╍╍╍ [Body] ╍╍╍╍╍╍╍╍╍╍╍╍╍╍╍╍╍╍╍╍╍╍╍╍\n"

			if let json = json as? NSObject {
				string += json.description
			} else {
				string += (NSString(data: data as Data, encoding: String.Encoding.utf8.rawValue)?.description ?? "--unable to parse data as! UTF8--")
			}
		}
		if !string.hasSuffix("\n") { string += "\n" }
		if includeDelimiters { string +=       "△△△△△△△△△△△△△△△△△△△△△△△△△△△△△△△△△△△△△△△△△△△△△△△△△△△△△△△△△△△△△△△△△△△\n" }
		return string
	}
	
	public func logErrorToFile(label: String = "") {
		guard let errorsDir = try? Plug.plugDirectoryURL.appendingPathComponent("Errors") else { return }
		let code = self.statusCode ?? 0
		let seconds = Int(Date().timeIntervalSinceReferenceDate)
		var host = ""
		if let url = request?.url { host = url.host ?? "" }
		var filename = "\(code) \(host) \(seconds).txt"
		filename = filename.replacingOccurrences(of: ":", with: "").replacingOccurrences(of: "/", with: "_")
		if label != "" { filename = label + "- " + filename }
		guard let filepath = try? errorsDir.appendingPathComponent(filename) else { return }
		
		do {
			try FileManager.default.createDirectory(at: errorsDir, withIntermediateDirectories: true, attributes: nil)
		} catch _ {
		}
		
		let contents = self.detailedDescription(includeDelimiters: false)
		
		do {
			try contents.data(using: String.Encoding.utf8)?.write(to: filepath, options: [.atomicWrite])
		} catch _ {
		}
		
	}

	public func log() {
		NSLog("\(self.description)")
	}
	
}

extension Connection {		//actions
	public func start() {
		if (state != .Waiting && state != .Queued) { return }
		self.channel.enqueue(connection: self)
	}
	
	public func run() {
		self.channel.connectionStarted(connection: self)
		self.state = .Running
		self.task = self.generateTask()
		Plug.instance.register(connection: self)
		self.task!.resume()
		self.startedAt = Date()
	}
	
	public func suspend() {
		if self.state != .Running { return }
		self.channel.connectionStopped(connection: self)
		self.state = .Suspended
		if self.superconnection == nil { self.task?.suspend() }
	}
	
	public func resume() {
		if self.state != .Suspended { return }
		self.channel.connectionStarted(connection: self)
		self.state = .Running
		if self.superconnection == nil { self.task?.resume() }
	}
	
	public func cancel() {
		self.channel.connectionStopped(connection: self, totallyRemove: true)
		self.state = .Canceled
		if self.superconnection == nil { self.task?.cancel() }
		NotificationCenter.default.post(name: Plug.notifications.connectionCancelled, object: self)
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
			self.completedAt = Date()
		}
		Plug.instance.unregister(connection: self)
		self.channel.connectionStopped(connection: self)
		self.channel.dequeue(connection: self)
		self.fileHandle?.closeFile()
		
		let data = Plug.ConnectionData(data: self.resultsData, size: self.bytesReceived) ?? Plug.ConnectionData(url: self.destinationFileURL, size: self.bytesReceived)
		
		self.requestQueue.addOperation {
			if data != nil || self.resultsError == nil {
				self.handleDownload(data: data ?? Plug.ConnectionData())
			} else {
				if let error = self.resultsError { self.reportError(error: error) }
			}
		}
		
		self.subconnections.forEach { $0.complete(state: state, parent: self) }
		self.requestQueue.addOperation({ self.notifyPersistentDelegateOfCompletion() })

		if self.state == .Completed {
			NotificationCenter.default.post(name: Plug.notifications.connectionCompleted, object: self)
		} else {
			NotificationCenter.default.post(name: Plug.notifications.connectionFailed, object: self, userInfo: (self.resultsError != nil) ? ["error": self.resultsError!] : nil)
		}
	}
	
	func reportError(error: NSError) {
		let queue = self.completionQueue ?? OperationQueue.main
		
		for block in self.errorBlocks {
			let op = BlockOperation(block: { block(self, error) })
			queue.addOperations([op], waitUntilFinished: true)
		}
	}
}

extension Connection {
	func addSubconnection(_ connection: Connection) {
		self.propagate(connection: connection)
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
	if !lhs.urlLike.isEqual(other: rhs.urlLike) { return false }
	return lhs.parameters == rhs.parameters && lhs.method == rhs.method
}

