//
//  PlugConnection.swift
//  Plug
//
//  Created by Ben Gottlieb on 2/9/15.
//  Copyright (c) 2015 Stand Alone, inc. All rights reserved.
//

import Foundation

#if os(iOS)
	import Gulliver
#endif

extension Plug {
	public class Connection: NSObject {
		public enum Persistence { case Transient, PersistRequest, Persistent(PersistenceInfo)
			public var isPersistent: Bool {
				switch (self) {
				case .Transient: return false
				default: return true
				}
			}
			public var persistentDelegate: PlugPersistentDelegate? { return PersistenceManager.defaultManager.delegateForPersistenceInfo(self.persistentInfo) }
			
			public var persistentInfo: PersistenceInfo? {
				switch (self) {
				case .Persistent(let info): return info
				default: return nil
				}
			}
			
			public var JSONValue: AnyObject { return self.persistentInfo?.JSONValue ?? [] }
				
		}
		public let persistence: Persistence
		
		public enum State: String, CustomStringConvertible { case Waiting = "Waiting", Queued = "Queued", Running = "Running", Suspended = "Suspended", Completed = "Completed", Canceled = "Canceled", CompletedWithError = "Completed with Error"
			public var description: String { return self.rawValue }
			public var isRunning: Bool { return self == .Running }
			public var hasStarted: Bool { return self != .Waiting && self != .Queued }
		}
		public var state: State = .Waiting {
			didSet {
				if self.state == oldValue { return }
				#if os(iOS)
					if oldValue == .Running { NetworkActivityIndicator.decrement() }
					if self.state.isRunning { NetworkActivityIndicator.increment() }
				#endif
			}
		}
		
		public var expectedContentLength: Int64?
		public var cachingPolicy: NSURLRequestCachePolicy = .ReloadIgnoringLocalCacheData
		public var response: NSURLResponse? { didSet {
			if let resp = response as? NSHTTPURLResponse {
				self.responseHeaders = Headers(dictionary: resp.allHeaderFields)
				self.statusCode = resp.statusCode
			}
			if self.response?.expectedContentLength != -1 {
				self.expectedContentLength = self.response?.expectedContentLength
			}
			self.resultsError = self.response?.error
		}}
		public var statusCode: Int?
		public var completionQueue: NSOperationQueue?
		public var completionBlocks: [(Plug.Connection, NSData) -> Void] = []
		public var errorBlocks: [(Plug.Connection, NSError) -> Void] = []
		public var progressBlocks: [(Plug.Connection, Double) -> Void] = []
		
		public let method: Method
		public var URL: NSURL { get { return self.URLLike.URL ?? NSURL() } }
		public var downloadToFile = false
		public var request: NSURLRequest?
		public let requestQueue: NSOperationQueue
		public let parameters: Plug.Parameters
		public var headers: Plug.Headers?
		public var responseHeaders: Plug.Headers?
		public var startedAt: NSDate?
		public var completedAt: NSDate?
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
				}
			}
		}
		
		
		public init?(method meth: Method = .GET, URL url: NSURLLike, parameters params: Plug.Parameters? = nil, persistence persist: Persistence = .Transient, channel chn: Plug.Channel = Plug.Channel.defaultChannel) {
			requestQueue = NSOperationQueue()
			requestQueue.maxConcurrentOperationCount = 1
			
			persistence = persist
			parameters = params ?? .None
			channel = chn
			
			method = parameters.normalizeMethod(meth)
			URLLike = url
			
			super.init()
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
		
		var task: NSURLSessionTask?
		func generateTask() -> NSURLSessionTask? {
			if self.task != nil { return self.task }
			if self.downloadToFile {
				self.task = Plug.instance.session.downloadTaskWithRequest(self.request ?? self.defaultRequest, completionHandler: { url, response, error in })
			} else {
				self.task = Plug.instance.session.dataTaskWithRequest(self.request ?? self.defaultRequest)/*, completionHandler: { data, response, error in
					self.complete((error == nil) ? .Completed : .CompletedWithError)
				})*/
			}
			
			if let identifier = self.task?.taskIdentifier {
				Plug.instance.channels[identifier] = self.channel
			}
			return self.task
		}
				
		var resultsError: NSError?
		var resultsURL: NSURL? { didSet { if let url = self.resultsURL { self.resultsData = NSMutableData(contentsOfURL: url) } } }
		var resultsData: NSMutableData?
		
		func receivedData(data: NSData) {
			if self.resultsData == nil { self.resultsData = NSMutableData() }
			self.resultsData?.appendData(data)
			
			if let total = self.expectedContentLength, dataLength = self.resultsData?.length {
				self.percentComplete = Double(dataLength) / Double(total)
			}
		}
		
		func failedWithError(error: NSError?) {
			if error != nil && error!.code == -1005 {
				print("++++++++ Simulator comms issue, please restart the sim. ++++++++")
			}
			self.response = self.task?.response
			if let httpResponse = self.response as? NSHTTPURLResponse { self.statusCode = httpResponse.statusCode }
			self.resultsError = error ?? self.task?.response?.error
			self.complete(.CompletedWithError)
		}

		func completedDownloadingToURL(location: NSURL) {
			let filename = "Plug-temp-\(location.lastPathComponent!.hash).tmp"
			
			self.response = self.task?.response
			if let httpResponse = self.response as? NSHTTPURLResponse { self.statusCode = httpResponse.statusCode }
			self.resultsURL = Plug.instance.temporaryDirectoryURL.URLByAppendingPathComponent(filename)
			do {
				try NSFileManager.defaultManager().moveItemAtURL(location, toURL: self.resultsURL!)
			} catch let error as NSError {
				print("error while saving a moving a downloaded URL: \(error)")
			}
			
			self.complete(.Completed)
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
	}

	static var noopConnection: Plug.Connection { return Plug.Connection(URL: "about:blank")! }
}

extension Plug.Connection {
	public func completion(completion: (Plug.Connection, NSData) -> Void) -> Self {
		self.requestQueue.addOperationWithBlock { self.completionBlocks.append(completion) }
		return self
	}

	public func error(completion: (Plug.Connection, NSError) -> Void) -> Self {
		self.requestQueue.addOperationWithBlock { self.errorBlocks.append(completion) }
		return self
	}
	
	public func progress(closure: (Plug.Connection, Double) -> Void) -> Self {
		self.requestQueue.addOperationWithBlock { self.progressBlocks.append(closure) }
		return self
	}
}



extension Plug.Connection {
	public override var description: String { return self.detailedDescription() }

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

			string += "\n╍╍╍╍╍╍╍╍╍╍╍╍╍╍╍╍╍╍╍╍╍╍╍╍ [Body] ╍╍╍╍╍╍╍╍╍╍╍╍╍╍╍╍╍╍╍╍╍╍╍╍\n"

			if let json = json as? NSObject {
				string += json.description
			} else {
				string += (NSString(data: data, encoding: NSUTF8StringEncoding)?.description ?? "--unable to parse data as! UTF8--")
			}
		}
		if !string.hasSuffix("\n") { string += "\n" }
		if includeDelimiters { string +=       "△△△△△△△△△△△△△△△△△△△△△△△△△△△△△△△△△△△△△△△△△△△△△△△△△△△△△△△△△△△△△△△△△△△\n" }
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

extension Plug.Connection {		//actions
	public func start() {
		if (state != .Waiting && state != .Queued) { return }
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
		self.task?.suspend()
	}
	
	public func resume() {
		if self.state != .Suspended { return }
		self.channel.connectionStarted(self)
		self.state = .Running
		self.task?.resume()
	}
	
	public func cancel() {
		self.channel.connectionStopped(self, totallyRemove: true)
		self.state = .Canceled
		self.task?.cancel()
		NSNotificationCenter.defaultCenter().postNotificationName(Plug.notifications.connectionCancelled, object: self)
	}
	
	func complete(state: State) {
		self.state = state
		self.completedAt = NSDate()
		Plug.instance.unregisterConnection(self)
		self.channel.connectionStopped(self)
		self.channel.dequeue(self)
		
		self.requestQueue.addOperationWithBlock {
			if let data = self.resultsData {
				let queue = self.completionQueue ?? NSOperationQueue.mainQueue()
				for block in self.completionBlocks {
					let op = NSBlockOperation(block: { block(self, data) })
					queue.addOperations([op], waitUntilFinished: true)
				}
			} else if let error = self.resultsError {
				let queue = self.completionQueue ?? NSOperationQueue.mainQueue()
				for block in self.errorBlocks {
					let op = NSBlockOperation(block: { block(self, error) })
					queue.addOperations([op], waitUntilFinished: true)
				}
			}
		}
		self.requestQueue.addOperationWithBlock({ self.notifyPersistentDelegateOfCompletion() })

		if self.state == .Completed {
			NSNotificationCenter.defaultCenter().postNotificationName(Plug.notifications.connectionCompleted, object: self)
		} else {
			NSNotificationCenter.defaultCenter().postNotificationName(Plug.notifications.connectionFailed, object: self, userInfo: (self.resultsError != nil) ? ["error": self.resultsError!] : nil)
		}
	}
}

extension NSURLRequest {
	public override var description: String {
		var str = (self.HTTPMethod ?? "[no method]") + " " + "\(self.URL)"
		
		if let fields = self.allHTTPHeaderFields {
			for (label, value) in fields {
				str += "\n\t" + label + ": " + value
			}
		}
		
		if let data = self.HTTPBody {
			let body = NSString(data: data, encoding: NSUTF8StringEncoding)
			str += "\n" + (body?.description ?? "[unconvertible body: \(data.length) bytes]")
		}
		
		return str
	}
}

public func ==(lhs: Plug.Connection, rhs: Plug.Connection) -> Bool {
	if !lhs.URLLike.isEqual(rhs.URLLike) { return false }
	return lhs.parameters == rhs.parameters && lhs.method == rhs.method
}

