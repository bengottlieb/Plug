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
		enum State: String, Printable { case NotStarted = "Not Started", Running = "Running", Suspended = "Suspended", Completed = "Completed", Canceled = "Canceled"
			var description: String { return self.rawValue }
		}
		
		public var cachingPolicy: NSURLRequestCachePolicy = .ReloadIgnoringLocalCacheData
		
		let method: Method
		let URL: NSURL
		var state: State = .NotStarted
		var request: NSURLRequest?
		let completionQueue: NSOperationQueue
		let parameters: Plug.Parameters
		var headers: Plug.Headers?
		var active: Bool = false {
			didSet {
				if (oldValue && !self.active) {
					NetworkActivityIndicator.sharedIndicator.decrement()
				} else if (!oldValue && self.active) {
					NetworkActivityIndicator.sharedIndicator.increment()
				}
			}
		}
		
		lazy var task: NSURLSessionTask = {
			self.task = Plug.defaultManager.session.downloadTaskWithRequest(self.request ?? self.defaultRequest, completionHandler: nil)
			
			Plug.defaultManager.registerConnection(self)
			return self.task
		}()
		
		init?(method meth: Method = .GET, URL url: NSURLConvertible, parameters params: Plug.Parameters? = nil) {
			completionQueue = NSOperationQueue()
			completionQueue.suspended = true
			
			parameters = params ?? .None
			
			method = parameters.normalizeMethod(meth)
			URL = url.URL ?? NSURL()
			
			super.init()
			if url.URL == nil {
				println("Unable to create a connection with URL: \(url)")

				return nil
			}
			if let header = self.parameters.contentTypeHeader { self.addHeader(header) }

			if Plug.defaultManager.autostartConnections { self.start() }
		}
		
		var resultsError: NSError?
		var resultsURL: NSURL?
		var resultsData: NSData? { return (self.resultsURL == nil) ? nil : NSData(contentsOfURL: self.resultsURL!) }
		
		func failedWithError(error: NSError?) {
			self.active = false
			self.resultsError = error
			self.completionQueue.suspended = false
		}

		public func addHeader(header: Plug.Header) {
			if self.headers == nil { self.headers = Plug.defaultManager.defaultHeaders }
			self.headers?.addHeader(header)
		}
		
		func completedDownloadingToURL(location: NSURL) {
			self.active = false
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
			
			println("Generated request: \n\(request)")
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
		var string = "\(self.method) \(request.URL.absoluteString!) \(self.parameters): \(self.state)"
		
		return string
	}
}

extension Plug.Connection {		//actions
	public func start() {
		assert(state == .NotStarted, "Trying to start an already started connection")
		self.state = .Running
		self.task.resume()
		self.active = true
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
		var str = (self.HTTPMethod ?? "[no method]") + " " + (self.URL.absoluteString ?? "[no URL]")
		
		for (label, value) in (self.allHTTPHeaderFields as [String: String]) {
			str += "\n\t" + label + ": " + value
		}
		
		if let data = self.HTTPBody {
			str += "\n" + (NSString(data: data, encoding: NSUTF8StringEncoding) ?? "[unconvertible body: \(data.length) bytes]")
		}
		
		return str
	}
}