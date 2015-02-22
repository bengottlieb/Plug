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
		
		public func delegateForPersistenceInfo(info: PersistenceInfo) -> PlugPersistentDelegate? {
			return self.persistentDelegates[info];
		}
		
		var persistentDelegates: [PersistenceInfo: PlugPersistentDelegate] = [:]
	}
}

public extension Plug {
	public struct PersistenceInfo: Hashable, Equatable {
		public var objectKey: String
		public var instanceKey: String?
		public var hashValue: Int { return self.objectKey.hash + (self.instanceKey?.hash ?? 0) }

	}
}

public protocol PlugPersistentDelegate {
	var persistenceInfo: Plug.PersistenceInfo { get }
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
