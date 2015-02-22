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
		
		func registerPersisitentConnection(connection: Plug.Connection) {
			
		}
		
		func unregisterPersisitentConnection(connection: Plug.Connection) {
			
		}
	}
}


extension Plug.Connection {
	public var JSONRepresentation: NSDictionary {
		return [
			"url": self.URL.absoluteString ?? "",
			"headers": self.headers?.dictionary ?? [:],
			"method": self.method.rawValue,
			"persistenceIdentifier": self.persistence.JSONValue,
			"parameters": self.parameters.JSONValue ?? [:],
		]
	}
	
	public convenience init?(JSONRepresentation info: NSDictionary) {
		var url = (info["url"] as? String) ?? ""
		var headers = (info["headers"] as? [String: String]) ?? [:]
		var method = Plug.Method(rawValue: (info["method"] as? String) ?? "GET")
		var persistance = Plug.PersistenceInfo(JSONValue: (info["persistenceIdentifier"] as? [String]) ?? [""])
		var parametersData = (info["parameters"] as? [String: NSDictionary])
		
		var parameters = Plug.Parameters.parametersFromJSON(parametersData ?? [:])
		
		self.init(method: method ?? .GET, URL: url, parameters: parameters, persistence: .Persistent(persistance))
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
		
		public init(JSONValue: [String]) {
			var oKey = JSONValue.count > 0 ? JSONValue[0] : ""
			var iKey: String? = JSONValue.count > 1 ? JSONValue[1] : nil
			
			self.init(objectKey: oKey, instanceKey: iKey)
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
