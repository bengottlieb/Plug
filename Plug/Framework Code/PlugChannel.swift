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

		static var defaultChannel: Channel = { return Channel(name: "default", maxSimultaneousConnections: 1) }()
		static var allChannels: [Channel] = []
		
		init(name chName: String, maxSimultaneousConnections max: Int) {
			name = chName
			maxSimultaneousConnections = max
			queue = NSOperationQueue()
			queue.maxConcurrentOperationCount = max
			Channel.allChannels.append(self)
		}


		internal var connections: [Int: Plug.Connection] = [:]
		private let queue: NSOperationQueue
		internal var waitingConnections: [Plug.Connection] = []
		internal var activeConnections: [Plug.Connection] = []
		
		
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
		
		func updateQueue() {
			self.queue.addOperationWithBlock {
				if self.queueState != .Running { return }
				
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