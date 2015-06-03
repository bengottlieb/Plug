//
//  PlugChannel.swift
//  Plug
//
//  Created by Ben Gottlieb on 4/21/15.
//  Copyright (c) 2015 Stand Alone, inc. All rights reserved.
//

import Foundation


extension Plug {
	public class Channel {
		public var maximumActiveConnections = 0
		public var queueState: QueueState = .PausedDueToOffline
		public let name: String
		public var maxSimultaneousConnections = 1 { didSet { self.queue.maxConcurrentOperationCount = self.maxSimultaneousConnections }}
		
		public enum QueueState: Int { case Paused, PausedDueToOffline, Running }

		public static var defaultChannel: Channel = { return Channel(name: "default", maxSimultaneousConnections: 1) }()
		public static var resourceChannel: Channel = { return Channel(name: "resources", maxSimultaneousConnections: 50) }()

		static var allChannels: [String: Channel] = [:]
		
		init(name chName: String, maxSimultaneousConnections max: Int) {
			name = chName
			queueState = Plug.manager.connectionType == .Offline ? .PausedDueToOffline : .Running
			maxSimultaneousConnections = max
			queue = NSOperationQueue()
			queue.maxConcurrentOperationCount = max
			Channel.allChannels[chName] = self
		}


		internal var connections: [Int: Plug.Connection] = [:]
		private let queue: NSOperationQueue
		internal var waitingConnections: [Plug.Connection] = []
		internal var activeConnections: [Plug.Connection] = []
		
		var JSONRepresentation: NSDictionary {
			return ["name": self.name, "max": self.maximumActiveConnections ]
		}
		
		class func channelWithJSON(json: NSDictionary?) -> Plug.Channel {
			var name = json?["name"] as? String ?? "default"
			if let channel = self.allChannels[name] { return channel }
			
			var max = json?["max"] as? Int ?? 1
			return Plug.Channel(name: name, maxSimultaneousConnections: max)
		}
		
		func startQueue() {
			self.queueState = .Running
			self.updateQueue()
		}
		
		func pauseQueue() {
			self.queueState = .Paused
		}
		
		func enqueue(connection: Plug.Connection) {
			self.queue.addOperationWithBlock {
				self.waitingConnections.append(connection)
				self.updateQueue()
				NSNotificationCenter.defaultCenter().postNotificationName(Plug.notifications.connectionQueued, object: connection)
			}
		}
		
		func dequeue(connection: Plug.Connection) {
			self.queue.addOperationWithBlock {
				if let index = find(self.waitingConnections, connection) {
					self.waitingConnections.removeAtIndex(index)
				}
				self.updateQueue()
			}
		}
		
		func connectionStarted(connection: Plug.Connection) {
			self.queue.addOperationWithBlock {
				if let index = find(self.waitingConnections, connection) { self.waitingConnections.removeAtIndex(index) }
				if find(self.activeConnections, connection) == -1 { self.activeConnections.append(connection) }
				NSNotificationCenter.defaultCenter().postNotificationName(Plug.notifications.connectionStarted, object: connection)
			}
		}
		
		func connectionStopped(connection: Plug.Connection) {
			self.queue.addOperationWithBlock {
				if let index = find(self.activeConnections, connection) {
					self.activeConnections.removeAtIndex(index)
				}
				self.updateQueue()
			}
		}
		
		var isRunning: Bool {
			return self.queueState == .Running
//			if self.queueState == .Running { return true }
//			if self.queueState == .PausedDueToOffline {
//				if Plug.manager.connectionType == .Offline { return false }
//				Plug.manager.updateChannelStates()
//				return true
//			}
//			return false
		}
		
		func updateQueue() {
			self.queue.addOperationWithBlock {
				if !self.isRunning { return }
				
				if self.waitingConnections.count > 0 && (self.maximumActiveConnections == 0 || self.activeConnections.count < self.maximumActiveConnections) {
					var connection = self.waitingConnections[0]
					self.waitingConnections.removeAtIndex(0)
					self.activeConnections.append(connection)
					connection.start()
				}
			}
		}


		subscript(task: NSURLSessionTask) -> Plug.Connection? {
			get { var connection: Plug.Connection?; self.queue.addOperations( [ NSBlockOperation(block: { connection = self.connections[task.taskIdentifier] } )], waitUntilFinished: true); return connection  }
			set { self.queue.addOperationWithBlock { self.connections[task.taskIdentifier] = newValue } }
		}
	}
}