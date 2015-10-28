//
//  PlugChannel.swift
//  Plug
//
//  Created by Ben Gottlieb on 4/21/15.
//  Copyright (c) 2015 Stand Alone, inc. All rights reserved.
//

import Foundation
import UIKit

extension Plug {
	public class Channel {
		public var maximumActiveConnections = 0
		public var queueState: QueueState = .PausedDueToOffline
		public let name: String
		public var maxSimultaneousConnections = 1// { didSet { self.queue.maxConcurrentOperationCount = self.maxSimultaneousConnections }}
		
		public enum QueueState: Int { case Paused, PausedDueToOffline, Running }

		public static var defaultChannel: Channel = { return Channel(name: "default", maxSimultaneousConnections: 1) }()
		public static var resourceChannel: Channel = { return Channel(name: "resources", maxSimultaneousConnections: 50) }()

		static var allChannels: [String: Channel] = [:]
		
		init(name chName: String, maxSimultaneousConnections max: Int) {
			name = chName
			queueState = Plug.manager.connectionType == .Offline ? .PausedDueToOffline : .Running
			maxSimultaneousConnections = max
			queue = NSOperationQueue()
			queue.maxConcurrentOperationCount = 1//max
			Channel.allChannels[chName] = self
		}

		internal var unfinishedConnections: Set<Plug.Connection> = []
		internal var connections: [Int: Plug.Connection] = [:]
		private let queue: NSOperationQueue
		internal var waitingConnections: [Plug.Connection] = []
		internal var activeConnections: [Plug.Connection] = []
		
		var JSONRepresentation: NSDictionary {
			return ["name": self.name, "max": self.maximumActiveConnections ]
		}
		
		class func channelWithJSON(json: NSDictionary?) -> Plug.Channel {
			let name = json?["name"] as? String ?? "default"
			if let channel = self.allChannels[name] { return channel }
			
			let max = json?["max"] as? Int ?? 1
			return Plug.Channel(name: name, maxSimultaneousConnections: max)
		}
		
		func startQueue() {
			self.queueState = .Running
			self.updateQueue()
		}
		
		func pauseQueue() {
			self.queueState = .Paused
		}
		
		var allConnections: [Plug.Connection] {
			return self.activeConnections + self.waitingConnections
		}
		
		func serialize(block: () -> Void) {
			if NSOperationQueue.currentQueue() == self.queue {
				block()
			} else {
				self.queue.addOperations([ NSBlockOperation(block: block) ], waitUntilFinished: true)
			}
		}
		
		func enqueue(connection: Plug.Connection) {
			self.serialize {
				self.waitingConnections.append(connection)
				self.updateQueue()
				NSNotificationCenter.defaultCenter().postNotificationName(Plug.notifications.connectionQueued, object: connection)
			}
		}
		
		func addConnectionToChannel(connection: Plug.Connection) {
			self.serialize {
				self.unfinishedConnections.insert(connection)
			}
		}
		
		func dequeue(connection: Plug.Connection) {
			self.serialize {
				self.unfinishedConnections.remove(connection)
				if let index = self.waitingConnections.indexOf(connection) {
					self.waitingConnections.removeAtIndex(index)
				}
				self.updateQueue()
			}
		}
		
		func connectionStarted(connection: Plug.Connection) {
			self.startBackgroundTask()
			self.serialize {
				if let index = self.waitingConnections.indexOf(connection) { self.waitingConnections.removeAtIndex(index) }
				if self.activeConnections.indexOf(connection) == -1 { self.activeConnections.append(connection) }
				NSNotificationCenter.defaultCenter().postNotificationName(Plug.notifications.connectionStarted, object: connection)
			}
		}
		
		func connectionStopped(connection: Plug.Connection) {
			self.serialize {
				if let index = self.activeConnections.indexOf(connection) {
					self.activeConnections.removeAtIndex(index)
				}
				self.updateQueue()
			}
		}
		
		var isRunning: Bool {
			return self.queueState == .Running
		}
		
		#if os(iOS)
			var backgroundTaskID: UIBackgroundTaskIdentifier?
			
			func startBackgroundTask() {
				if self.backgroundTaskID == nil {
					self.serialize {
						self.backgroundTaskID = UIApplication.sharedApplication().beginBackgroundTaskWithName("plug.queue.\(self.name)", expirationHandler: {
							self.endBackgroundTask(true)
							self.pauseQueue()
						})
					}
				}
			}
			
			func endBackgroundTask(onlyClearTaskID: Bool) {
				self.serialize {
					if let taskID = self.backgroundTaskID where !self.isRunning {
						dispatch_async(dispatch_get_main_queue(), {
							if (!onlyClearTaskID) { UIApplication.sharedApplication().endBackgroundTask(taskID) }
						})
						self.backgroundTaskID = nil
					}
				}
			}
		#else
			func startBackgroundTask() {}
			func endBackgroundTask(onlyClearTaskID: Bool) {}
		#endif
		
		func updateQueue() {
			self.serialize {
				if !self.isRunning {
					self.endBackgroundTask(false)
					return
				}
				
				if self.waitingConnections.count > 0 && (self.maximumActiveConnections == 0 || self.activeConnections.count < self.maximumActiveConnections) {
					let connection = self.waitingConnections[0]
					self.waitingConnections.removeAtIndex(0)
					self.activeConnections.append(connection)
					connection.run()
				}
			}
		}


		subscript(task: NSURLSessionTask) -> Plug.Connection? {
			get { var connection: Plug.Connection?; self.queue.addOperations( [ NSBlockOperation(block: { connection = self.connections[task.taskIdentifier] } )], waitUntilFinished: true); return connection  }
			set { self.serialize { self.connections[task.taskIdentifier] = newValue } }
		}
		
		func existingConnectionWithMethod(method: Method, URL: NSURLLike, parameters: Plug.Parameters?) -> Connection? {
			for connection in self.unfinishedConnections {
				if connection.URLLike == URL && connection.method == method { return connection }
			}
			return nil
		}
	}
}