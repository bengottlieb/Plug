//
//  PlugConnection.swift
//  Plug
//
//  Created by Ben Gottlieb on 2/9/15.
//  Copyright (c) 2015 Stand Alone, inc. All rights reserved.
//

import Foundation

extension Plug {
	public class Connection: NSObject {
		public enum ResponseRelevance { case Transient, Ignored, Persistent(PersistenceInfo)
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
		}
		public let responseRelevance: ResponseRelevance
		
		public enum State: String, Printable { case NotStarted = "Not Started", Running = "Running", Suspended = "Suspended", Completed = "Completed", Canceled = "Canceled", CompletedWithError = "Error"
			public var description: String { return self.rawValue }
			public var isRunning: Bool { return self == .Running }
			public var hasStarted: Bool { return self != .NotStarted }
		}
		public var state: State = .NotStarted {
			didSet {
				if self.state == oldValue { return }
				#if TARGET_OS_IPHONE
					if oldValue == .Running { NetworkActivityIndicator.decrement() }
					if self.state.isRunning { NetworkActivityIndicator.increment() }
				#endif
			}
		}
		
		public var cachingPolicy: NSURLRequestCachePolicy = .ReloadIgnoringLocalCacheData
		public var response: NSURLResponse?
		
		public let method: Method
		public let URL: NSURL
		public var downloadToFile = false
		public var request: NSURLRequest?
		public let completionQueue: NSOperationQueue
		public let parameters: Plug.Parameters
		public var headers: Plug.Headers?
		public func addHeader(header: Plug.Header) {
			if self.headers == nil { self.headers = Plug.defaultManager.defaultHeaders }
			self.headers?.append(header)
		}
		
		
		public init?(method meth: Method = .GET, URL url: NSURLConvertible, parameters params: Plug.Parameters? = nil, relevance: ResponseRelevance = .Transient) {
			completionQueue = NSOperationQueue()
			completionQueue.maxConcurrentOperationCount = 1
			completionQueue.suspended = true
			
			responseRelevance = relevance
			parameters = params ?? .None
			
			method = parameters.normalizeMethod(meth)
			URL = url.URL ?? NSURL()
			
			super.init()
			if url.URL == nil {
				println("Unable to create a connection with URL: \(url)")

				return nil
			}
			if let header = self.parameters.contentTypeHeader { self.addHeader(header) }

			if Plug.defaultManager.autostartConnections {
				dispatch_after(dispatch_time(DISPATCH_TIME_NOW, Int64(1.0 * Double(NSEC_PER_SEC))), dispatch_get_main_queue()) {
					self.start()
				}
			}
		}
		
		lazy var task: NSURLSessionTask = {
			if self.downloadToFile {
				self.task = Plug.defaultManager.session.downloadTaskWithRequest(self.request ?? self.defaultRequest, completionHandler: nil)
			} else {
				self.task = Plug.defaultManager.session.dataTaskWithRequest(self.request ?? self.defaultRequest, completionHandler: { data, response, error in
					self.state = (error == nil) ? .Completed : .CompletedWithError
					self.response = response
					self.resultsError = error ?? response.error
					if error == nil || data.length > 0 {
						self.resultsData = data
					}
					self.completionQueue.suspended = false
				})
			}
			Plug.defaultManager.registerConnection(self)
			return self.task
			}()
		
		var resultsError: NSError?
		var resultsURL: NSURL? { didSet { if let url = self.resultsURL { self.resultsData = NSData(contentsOfURL: url) } } }
		var resultsData: NSData?
		
		func failedWithError(error: NSError?) {
			self.state = .CompletedWithError
			self.response = self.task.response
			self.resultsError = error ?? self.task.response?.error
			self.completionQueue.suspended = false
		}

		func completedDownloadingToURL(location: NSURL) {
			self.state = .Completed
			var filename = "Plug-temp-\(location.lastPathComponent!.hash).tmp"
			var error: NSError?
			
			self.resultsURL = Plug.defaultManager.temporaryDirectoryURL.URLByAppendingPathComponent(filename)
			NSFileManager.defaultManager().moveItemAtURL(location, toURL: self.resultsURL!, error: &error)
			
			self.completionQueue.suspended = false
		}
		
		var defaultRequest: NSURLRequest {
			var urlString = self.URL.absoluteString! + self.parameters.URLString
			var request = NSMutableURLRequest(URL: NSURL(string: urlString)!)
			
			request.allHTTPHeaderFields = (self.headers ?? Plug.defaultManager.defaultHeaders).dictionary
			request.HTTPMethod = self.method.rawValue
			request.HTTPBody = self.parameters.bodyData
			request.cachePolicy = self.cachingPolicy
			
			return request
		}
	}
	
	var noopConnection: Plug.Connection { return Plug.Connection(URL: "about:blank")! }
}

extension Plug.Connection {
	public func completion(completion: (NSData) -> Void, queue: NSOperationQueue? = nil) -> Self {
		self.completionQueue.addOperationWithBlock {
			(queue ?? NSOperationQueue.mainQueue()).addOperationWithBlock {
				if let data = self.resultsData { completion(data) }
			}
		}
		return self
	}

	public func error(completion: (NSError) -> Void, queue: NSOperationQueue? = nil) -> Self {
		self.completionQueue.addOperationWithBlock {
			(queue ?? NSOperationQueue.mainQueue()).addOperationWithBlock {
				if let error = self.resultsError { completion(error) }
			}
		}
		return self
	}
}

extension Plug.Connection: Printable {
	public override var description: String {
		var request = self.task.originalRequest
		var noURL = "[no URL]"
		var string = "\(self.method) \(request.URL) \(self.parameters): \(self.state)"
		if let response = self.response {
			string += "\n\n" + response.description
		}
		if let data = self.resultsData {
			string += "\n\n" + (NSString(data: data, encoding: NSUTF8StringEncoding)?.description ?? "--unable to parse data as UTF8--")
		}
		
		return string
	}
	
	public func log() {
		NSLog("\(self.description)")
	}
}

extension Plug.Connection {		//actions
	public func start() {
		assert(state == .NotStarted, "Trying to start an already started connection")
		self.state = .Running
		self.task.resume()
		self.completionQueue.addOperationWithBlock({ self.notifyPersistentDelegateOfCompletion() })
	}
	
	public func suspend() {
		self.state = .Suspended
		self.task.suspend()
	}
	
	public func resume() {
		self.state = .Running
		self.task.resume()
	}
	
	public func cancel() {
		self.state = .Canceled
		self.task.cancel()
	}
}

extension NSURLRequest: Printable {
	public override var description: String {
		var str = (self.HTTPMethod ?? "[no method]") + " " + "\(self.URL)"
		
		for (label, value) in (self.allHTTPHeaderFields as [String: String]) {
			str += "\n\t" + label + ": " + value
		}
		
		if let data = self.HTTPBody {
			var body = NSString(data: data, encoding: NSUTF8StringEncoding)
			str += "\n" + (body?.description ?? "[unconvertible body: \(data.length) bytes]")
		}
		
		return str
	}
}

public func ==(lhs: Plug.Connection.ResponseRelevance, rhs: Plug.Connection.ResponseRelevance) -> Bool {
	return true
}