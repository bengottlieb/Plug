//
//  PlugPersistence.swift
//  Plug
//
//  Created by Ben Gottlieb on 2/21/15.
//  Copyright (c) 2015 Stand Alone, inc. All rights reserved.
//

import Foundation

public extension Plug {
	class PersistenceManager {
        public static let instance = PersistenceManager()
		
		public func register(_ object: PlugPersistentDelegate) {
			self.persistentDelegates[object.persistenceInfo] = object
		}
		
		public func delegateForPersistenceInfo(info: PersistenceInfo?) -> PlugPersistentDelegate? {
			if let info = info { return self.persistentDelegates[info] }
			return nil
		}
		
        let queue: OperationQueue
		var persistentDelegates: [PersistenceInfo: PlugPersistentDelegate] = [:]
		var persistentConnections: [Connection] = []

        init() {
            self.queue = OperationQueue()
            self.queue.maxConcurrentOperationCount = 1
            self.queue.name = "Plug PersistenceManager Queue"
        }
        

		func register(_ connection: Connection) {
			self.queue.addOperation {
				if self.persistentConnections.firstIndex(of: connection) == nil {
					self.persistentConnections.append(connection)
					self.queuePersistentConnectionSave()
				}
			}
		}
		
		func unregister(_ connection: Connection) {
			self.queue.addOperation {
				if let index = self.persistentConnections.firstIndex(of: connection) {
					self.persistentConnections.remove(at: index)
					self.queuePersistentConnectionSave()
				}
			}
		}
		
		public func loadCachedURLs(fromURL: URL? = nil) {
			self.persistentCacheURL = fromURL ?? self.defaultPersistentCacheURL
			
			
			do {
				if let data = try? Data(contentsOf: self.persistentCacheURL!) {
					if let json = try JSONSerialization.jsonObject(with: data, options: []) as? [NSDictionary] {
						for dict in json {
							if let connection = Connection(JSONRepresentation: dict) {
								connection.channel.enqueue(connection: connection)
							}
						}
					}
				}
			} catch {}
		}
		
		
		
		var defaultPersistentCacheURL: URL { return Plug.plugDirectoryURL.appendingPathComponent("Pending_Connections.json") }
		
		var persistentCacheURL: URL? { didSet {
			if let url = self.persistentCacheURL {
				do {
					try FileManager.default.createDirectory(at: url.deletingLastPathComponent(), withIntermediateDirectories: true, attributes: nil)
				} catch let error {
					print("error while loading cached URLs: \(error)")
				}
			}
		}}
		
		var saveTimer: Timer?
		func queuePersistentConnectionSave() {
			self.saveTimer?.invalidate()
			
			self.saveTimer = Timer.scheduledTimer(timeInterval: 0.1, target: self, selector: #selector(savePersistentConnections), userInfo: nil, repeats: false)
		}
		
		@objc func savePersistentConnections() {
			self.saveTimer = nil
			guard let persistentURL = self.persistentCacheURL else { return }
			let dictionaries: [[String : Codable]] = self.persistentConnections.map { return $0.JSONRepresentation }
			do {
				let json = try JSONSerialization.data(withJSONObject: dictionaries, options: JSONSerialization.WritingOptions.prettyPrinted)
				try json.write(to: persistentURL, options: [.atomicWrite])
			} catch let error {
				print("error while saving a persistent connection: \(error)")
			}
		}
	}
}


extension Connection {
	public var JSONRepresentation: [String : Codable] {
		var json: [String : Codable] = [
			"url": self.url.absoluteString,
			"persistenceIdentifier": self.persistence.JSONValue,
			"method": self.method.rawValue,
		]
		if let channel = self.channel.JSONRepresentation as? Codable { json["channel"] = channel }

		if let headers = self.headers { json["headers"] = headers.dictionary }
		if self.parameters.type != "None", let params = self.parameters.JSONValue as? Codable { json["parameters"] = params }
		return json
	}
	
	public convenience init?(JSONRepresentation info: NSDictionary) {
		let url = (info["url"] as? String) ?? ""
		//var headers = (info["headers"] as? [String: String]) ?? [:]
		let method = Plug.Method(rawValue: (info["method"] as? String) ?? "GET")
		let persistance = Plug.PersistenceInfo(JSONValue: (info["persistenceIdentifier"] as? [String]) ?? [])
		let channelJSON = info["channel"] as? NSDictionary
		let channel = Plug.Channel.channel(json: channelJSON as? JSONDictionary) ?? Plug.Channel.defaultChannel
		let parametersData = (info["parameters"] as? [String: JSONDictionary])
		
		let parameters = Plug.Parameters(dictionary: parametersData ?? [:])
		
		self.init(method: method ?? .GET, url: url, parameters: parameters, persistence: (persistance == nil) ? .persistRequest : .persistent(persistance!), channel: channel)
	}
}

public extension Plug {
	struct PersistenceInfo: Hashable, Equatable {
		public var objectKey: String
		public var instanceKey: String?
		public func hash(into hasher: inout Hasher) {
			hasher.combine(self.hashValue)
		}
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
	
	func connectionCompleted(connection: Connection, info: Plug.PersistenceInfo?)
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

