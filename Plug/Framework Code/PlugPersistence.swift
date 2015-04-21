//
//  PlugPersistence.swift
//  Plug
//
//  Created by Ben Gottlieb on 2/21/15.
//  Copyright (c) 2015 Stand Alone, inc. All rights reserved.
//

import Foundation

public extension Plug {
	public class PersistenceManager {
		public class var defaultManager: PersistenceManager { struct s { static let mgr = PersistenceManager() }; return s.mgr }
		
		public func registerObject(object: PlugPersistentDelegate) {
			self.persistentDelegates[object.persistenceInfo] = object
		}
		
		public func delegateForPersistenceInfo(info: PersistenceInfo?) -> PlugPersistentDelegate? {
			if let info = info { return self.persistentDelegates[info] }
			return nil
		}
		
		var persistentDelegates: [PersistenceInfo: PlugPersistentDelegate] = [:]
		var persistentConnections: [Plug.Connection] = []
		var queue: NSOperationQueue = { var q = NSOperationQueue(); q.maxConcurrentOperationCount = 1; return q }()
		
		func registerPersisitentConnection(connection: Plug.Connection) {
			self.queue.addOperationWithBlock {
				if find(self.persistentConnections, connection) == nil {
					self.persistentConnections.append(connection)
					self.queuePersistentConnectionSave()
				}
			}
		}
		
		func unregisterPersisitentConnection(connection: Plug.Connection) {
			self.queue.addOperationWithBlock {
				if let index = find(self.persistentConnections, connection) {
					self.persistentConnections.removeAtIndex(index)
					self.queuePersistentConnectionSave()
				}
			}
		}
		
		public func loadCachedURLs(fromURL: NSURL? = nil) {
			self.persistentCacheURL = fromURL ?? self.defaultPersistentCacheURL
			
			if let data = NSData(contentsOfURL: self.persistentCacheURL!) {
				var error: NSError?
				if let json = NSJSONSerialization.JSONObjectWithData(data, options: nil, error: &error) as? [NSDictionary] {
					for dict in json {
						if let connection = Plug.Connection(JSONRepresentation: dict) {
							connection.channel.enqueue(connection)
						}
					}
				}
			}
		}
		
		var defaultPersistentCacheURL = NSURL(fileURLWithPath: "~/Library/Communications/Pending_Connections.json".stringByExpandingTildeInPath)
		var persistentCacheURL: NSURL? { didSet {
			if let url = self.persistentCacheURL {
				NSFileManager.defaultManager().createDirectoryAtURL(url.URLByDeletingLastPathComponent!, withIntermediateDirectories: true, attributes: nil, error: nil)
			}
		}}
		
		var saveTimer: NSTimer?
		func queuePersistentConnectionSave() {
			self.saveTimer?.invalidate()
			
			self.saveTimer = NSTimer.scheduledTimerWithTimeInterval(0.1, target: self, selector: "savePersistentConnections", userInfo: nil, repeats: false)
		}
		
		func savePersistentConnections() {
			self.saveTimer = nil
			if self.persistentCacheURL == nil { return }
			var dictionaries: [NSDictionary] = self.persistentConnections.map { return $0.JSONRepresentation }
			var error: NSError?
			if let json = NSJSONSerialization.dataWithJSONObject(dictionaries, options: NSJSONWritingOptions.PrettyPrinted, error: &error) {
				json.writeToURL(self.persistentCacheURL!, atomically: true)
			}
		}
	}
}


extension Plug.Connection {
	public var JSONRepresentation: NSDictionary {
		var json = [
			"url": self.URL.absoluteString ?? "",
			"persistenceIdentifier": self.persistence.JSONValue,
			"method": self.method.rawValue
		]

		if let headers = self.headers { json["headers"] = headers.dictionary }
		if self.parameters.type != "None" { json["parameters"] = self.parameters.JSONValue! }
		return json
	}
	
	public convenience init?(JSONRepresentation info: NSDictionary) {
		var url = (info["url"] as? String) ?? ""
		var headers = (info["headers"] as? [String: String]) ?? [:]
		var method = Plug.Method(rawValue: (info["method"] as? String) ?? "GET")
		var persistance = Plug.PersistenceInfo(JSONValue: (info["persistenceIdentifier"] as? [String]) ?? [])
		var parametersData = (info["parameters"] as? [String: NSDictionary])
		
		var parameters = Plug.Parameters(dictionary: parametersData ?? [:])
		
		self.init(method: method ?? .GET, URL: url, parameters: parameters, persistence: (persistance == nil) ? .PersistRequest : .Persistent(persistance!))
	}
}

public extension Plug {
	public struct PersistenceInfo: Hashable, Equatable {
		public var objectKey: String
		public var instanceKey: String?
		public var hashValue: Int { return self.objectKey.hash + (self.instanceKey?.hash ?? 0) }
		
		public init(objectKey oKey: String, instanceKey iKey: String? = nil) {
			objectKey = oKey
			instanceKey = iKey
		}
		
		public var JSONValue: [String] {
			var value = [self.objectKey]
			if let instanceKey = self.instanceKey { value.append(instanceKey) }
			return value
		}
		
		public init?(JSONValue: [String]) {
			if JSONValue.count == 0 { return nil }
			
			self.init(objectKey: JSONValue[0], instanceKey: JSONValue.count > 1 ? JSONValue[1] : nil)
		}
	}
}

public protocol PlugPersistentDelegate {
	var persistenceInfo: Plug.PersistenceInfo { get }
	
	func connectionCompleted(connection: Plug.Connection, info: Plug.PersistenceInfo?)
}

public func ==(lhs: Plug.PersistenceInfo, rhs: Plug.PersistenceInfo) -> Bool {
	if rhs.objectKey != lhs.objectKey { return false }
	
	if rhs.instanceKey == nil && lhs.instanceKey == nil { return true }
	
	if let lInstance = lhs.instanceKey {
		if let rInstance = rhs.instanceKey {
			return lInstance == rInstance
		}
	}
	return false
}

