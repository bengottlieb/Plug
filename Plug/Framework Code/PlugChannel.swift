//
//  PlugChannel.swift
//  Plug
//
//  Created by Ben Gottlieb on 4/21/15.
//  Copyright (c) 2015 Stand Alone, inc. All rights reserved.
//

import Foundation
#if os(iOS)
	import UIKit
#endif

extension Plug {
	public class Channel {
		public var maximumActiveConnections = 0
		public var pausedReason: PauseReason? = .offline
		public let name: String
		public var count: Int { return self.waitingConnections.count + self.activeConnections.count }
		public var maxSimultaneousConnections = 1// { didSet { self.queue.maxConcurrentOperationCount = self.maxSimultaneousConnections }}
		
		public enum PauseReason: Int { case manual, offline, backgrounding }

		public static var defaultChannel: Channel = { return Channel(name: "default", maxSimultaneousConnections: 1) }()
		public static var resourceChannel: Channel = { return Channel(name: "resources", maxSimultaneousConnections: 50) }()

		static var allChannels: [String: Channel] = [:]
		
		init(name chName: String, maxSimultaneousConnections max: Int) {
			name = chName
			pausedReason = Plug.connectionType == .offline ? .offline : nil
			maxSimultaneousConnections = max
			queue = OperationQueue()
			queue.maxConcurrentOperationCount = 1//max
			Channel.allChannels[chName] = self
		}

		internal var unfinishedConnections: Set<Connection> = []
		internal var connections: [Int: Connection] = [:]
		private let queue: OperationQueue
		internal var waitingConnections: [Connection] = []
		internal var activeConnections: [Connection] = []
		
		public class func restartAllChannels(evenIfOffline: Bool = false) {
			if !evenIfOffline && Plug.connectionType == .offline { return }
			
			for channel in allChannels.values {
				if !channel.isRunning { channel.startQueue() }
			}
		}

		class func restartBackgroundedChannels() {
			if Plug.connectionType == .offline { return }
			for channel in allChannels.values where channel.pausedReason == .backgrounding {
				if !channel.isRunning { channel.startQueue() }
			}
		}

		var JSONRepresentation: [String: Codable] {
			return ["name": self.name, "max": self.maximumActiveConnections ]
		}
		
		class func channel(json: JSONDictionary?) -> Plug.Channel {
			let name = json?["name"] as? String ?? "default"
			if let channel = self.allChannels[name] { return channel }
			
			let max = json?["max"] as? Int ?? 1
			return Plug.Channel(name: name, maxSimultaneousConnections: max)
		}
		
		func startQueue() {
			self.serialize {
				self.pausedReason = nil
				self.updateQueue()
			}
		}
		
		func pauseQueue(reason: PauseReason = .manual) {
			self.pausedReason = reason
		}
		
		var allConnections: [Connection] {
			return self.activeConnections + self.waitingConnections
		}
		
		var serializerSemaphore = DispatchSemaphore(value: 1)
		func serialize(block: @escaping () -> Void) {
			self.serializerSemaphore.wait()
			defer { self.serializerSemaphore.signal() }
//			if OperationQueue.current == self.queue {
				block()
//			} else {
//				self.queue.addOperations([ BlockOperation(block: block) ], waitUntilFinished: true)
//			}
		}
		
		func enqueue(connection: Connection) {
			self.serialize {
				if connection.state == .queued { return }
				if let reason = self.pausedReason {
					if reason == .offline && Plug.online {
						self.pausedReason = nil
					} else {
						print("Queing connection on a non-running queue (\(self), reason: \(reason))")
					}
				}
				connection.state = .queuing
				
				if connection.coalescing == .coalesceSimilarConnections, let existing = self.existing(matching: connection) {
					existing.addSubconnection(connection)
				} else {
					self.waitingConnections.append(connection)
					self.updateQueue()
					connection.state = .queued
				}
				NotificationCenter.default.post(name: Plug.notifications.connectionQueued, object: connection)
			}
		}
		
		func addToChannel(connection: Connection) {
			self.serialize {
				self.unfinishedConnections.insert(connection)
			}
		}
		
		func dequeue(connection: Connection) {
			self.serialize {
				self.removeWaiting(connection)
				self.updateQueue()
			}
		}
		
		func removeWaiting(_ connection: Connection) {
			self.unfinishedConnections.remove(connection)
			if let index = self.waitingConnections.index(of: connection) {
				self.waitingConnections.remove(at: index)
			}
		}
		
		func removeActive(_ connection: Connection) {
			if let index = self.activeConnections.index(of: connection) {
				self.activeConnections.remove(at: index)
			}
		}
		
		func connectionStarted(connection: Connection) {
			self.startBackgroundTask()
			self.serialize {
				if let index = self.waitingConnections.index(of: connection) { self.waitingConnections.remove(at: index) }
				if self.activeConnections.index(of: connection) == -1 { self.activeConnections.append(connection) }
				NotificationCenter.default.post(name: Plug.notifications.connectionStarted, object: connection)
			}
		}
		
		func connectionStopped(connection: Connection, totallyRemove: Bool = false) {
			self.serialize {
				if totallyRemove { self.unfinishedConnections.remove(connection) }
				self.removeActive(connection)
				self.updateQueue()
			}
		}
		
		var isRunning: Bool {
			return self.pausedReason == nil
		}
		
		#if os(iOS)
			var backgroundTaskID: UIBackgroundTaskIdentifier?
			
			func startBackgroundTask() {
				if self.backgroundTaskID == nil {
					self.serialize {
						self.backgroundTaskID = Plug.instance.backgroundActivityHandler?.beginBackgroundTaskWithName("plug.queue.\(self.name)", expirationHandler: {
							self.endBackgroundTask(onlyClearTaskID: true)
							self.pauseQueue(reason: .backgrounding)
						})
					}
				}
			}
			
			func endBackgroundTask(onlyClearTaskID: Bool) {
				self.serialize {
					if let taskID = self.backgroundTaskID , !self.isRunning {
						DispatchQueue.main.async {
							if (!onlyClearTaskID) { Plug.instance.backgroundActivityHandler?.endBackgroundTask(taskID) }
						}
						self.backgroundTaskID = nil
					}
				}
			}
		#else
			func startBackgroundTask() {}
			func endBackgroundTask(onlyClearTaskID: Bool) {}
		#endif
		
		private func updateQueue() {
			if !self.isRunning {
				self.endBackgroundTask(onlyClearTaskID: false)
				return
			}
			
			if self.waitingConnections.count > 0 && (self.maximumActiveConnections == 0 || self.activeConnections.count < self.maximumActiveConnections) {
				let connection = self.waitingConnections[0]
				self.waitingConnections.remove(at: 0)
				self.activeConnections.append(connection)
				self.queue.addOperation {
					connection.run()
				}
			}
		}


		subscript(task: URLSessionTask) -> Connection? {
			get {
				var connection: Connection?;
				
				self.serialize {
					connection = self.connections[task.taskIdentifier]
				}
			//	self.queue.addOperations( [ BlockOperation(block: { connection = self.connections[task.taskIdentifier] } )], waitUntilFinished: true);
				return connection
			}
			set { self.serialize {
				if newValue == nil, let existing = self.connections[task.taskIdentifier] {
					self.removeWaiting(existing)
					self.removeActive(existing)
				}
				self.connections[task.taskIdentifier] = newValue
			} }
		}
		
		func existing(matching connection: Connection) -> Connection? {
			for existing in self.activeConnections {
				if existing === connection { continue }
				if existing == connection { return existing }
			}

			for existing in self.waitingConnections {
				if existing === connection { continue }
				if existing == connection { return existing }
			}

			return nil
		}
	}
}
