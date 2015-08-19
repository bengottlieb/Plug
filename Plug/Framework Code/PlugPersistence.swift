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
				if self.persistentConnections.indexOf(connection) == nil {
					self.persistentConnections.append(connection)
					self.queuePersistentConnectionSave()
				}
			}
		}
		
		func unregisterPersisitentConnection(connection: Plug.Connection) {
			self.queue.addOperationWithBlock {
				if let index = self.persistentConnections.indexOf(connection) {
					self.persistentConnections.removeAtIndex(index)
					self.queuePersistentConnectionSave()
				}
			}
		}
		
		public func loadCachedURLs(fromURL: NSURL? = nil) {
			self.persistentCacheURL = fromURL ?? self.defaultPersistentCacheURL
			
			if let data = NSData(contentsOfURL: self.persistentCacheURL!) {
				do {
					if let json = try NSJSONSerialization.JSONObjectWithData(data, options: []) as? [NSDictionary] {
						for dict in json {
							if let connection = Plug.Connection(JSONRepresentation: dict) {
								connection.channel.enqueue(connection)
							}
						}
					}
				} catch {}
			}
		}
		
		var defaultPersistentCacheURL = NSURL(fileURLWithPath: ("~/Library/Communications/Pending_Connections.json" as NSString).stringByExpandingTildeInPath)
		var persistentCacheURL: NSURL? { didSet {
			if let url = self.persistentCacheURL {
				do {
					try NSFileManager.defaultManager().createDirectoryAtURL(url.URLByDeletingLastPathComponent!, withIntermediateDirectories: true, attributes: nil)
				} catch let error as NSError {
					print("error while loading cached URLs: \(error)")
				}
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
			let dictionaries: [NSDictionary] = self.persistentConnections.map { return $0.JSONRepresentation }
			do {
				let json = try NSJSONSerialization.dataWithJSONObject(dictionaries, options: NSJSONWritingOptions.PrettyPrinted)
				json.writeToURL(self.persistentCacheURL!, atomically: true)
			} catch let error as NSError {
				print("error while saving a persistent connection: \(error)")
			}
		}
	}
}


extension Plug.Connection {
	public var JSONRepresentation: NSDictionary {
		var json = [
			"url": self.URL.absoluteString ?? "",
			"persistenceIdentifier": self.persistence.JSONValue,
			"method": self.method.rawValue,
			"channel": self.channel.JSONRepresentation
		]

		if let headers = self.headers { json["headers"] = headers.dictionary }
		if self.parameters.type != "None" { json["parameters"] = self.parameters.JSONValue! }
		return json
	}
	
	public convenience init?(JSONRepresentation info: NSDictionary) {
		let url = (info["url"] as? String) ?? ""
		//var headers = (info["headers"] as? [String: String]) ?? [:]
		let method = Plug.Method(rawValue: (info["method"] as? String) ?? "GET")
		let persistance = Plug.PersistenceInfo(JSONValue: (info["persistenceIdentifier"] as? [String]) ?? [])
		let channelJSON = info["channel"] as? NSDictionary
		let channel = Plug.Channel.channelWithJSON(channelJSON)
		let parametersData = (info["parameters"] as? [String: NSDictionary])
		
		let parameters = Plug.Parameters(dictionary: parametersData ?? [:])
		
		self.init(method: method ?? .GET, URL: url, parameters: parameters, persistence: (persistance == nil) ? .PersistRequest : .Persistent(persistance!), channel: channel)
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

