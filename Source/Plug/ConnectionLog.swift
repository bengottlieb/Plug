//
//  ConnectionLog.swift
//  Plug
//
//  Created by Ben Gottlieb on 1/13/18.
//  Copyright © 2018 Stand Alone, inc. All rights reserved.
//

import Foundation

public class ConnectionLog {
	struct Notifications {
		static let didLogConnection = Notification.Name("Plug:ConnectionLog.didLogConnection")
	}
	
	internal let queue = DispatchQueue(label: "ConnectionLogQueue", attributes: [])

	public var logged: [Connection] = []
	
	func clear() {
		self.logged = []
	}
	
	func log(connection: Connection) {
		connection.completionQueue = nil
		connection.completionQueue = nil
		connection.completionBlocks = []
		connection.errorBlocks = []
		connection.progressBlocks = []
		connection.jsonBlocks = []
		connection.subconnections = []
		
		self.queue.async {
			self.logged.append(connection)
			DispatchQueue.main.async {
				NotificationCenter.default.post(name: Notifications.didLogConnection, object: connection)
			}
		}
	}
}
