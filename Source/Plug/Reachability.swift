//
//  Reachability.swift
//  Plug
//
//  Created by Ben Gottlieb on 6/15/19.
//  Copyright © 2019 Stand Alone, inc. All rights reserved.
//

import SystemConfiguration
import Foundation

public enum ReachabilityError: Error { case unableToSetCallback, unableToSetDispatchQueue, unableToGetInitialFlags }

public class Reachability {
    public static let instance = Reachability()
    
    static let reachabilityChanged = Notification.Name("reachabilityChanged")

    public let reachableOnWWAN: Bool = true
    public var allowsCellularConnection = true
    
    public var connection: Plug.ConnectionType {
        if self.flags == nil || !self.setReachabilityFlags() { return .offline }
        
        switch self.flags?.connection ?? .offline {
        case .offline: return .offline
        case .cellular: return self.allowsCellularConnection ? .cellular : .offline
        case .wifi: return .wifi
        }
    }

    var running = false
    let reachabilityRef: SCNetworkReachability!
    let reachabilitySerialQueue = DispatchQueue(label: "plug.reachability", qos: .default)
    fileprivate(set) var flags: SCNetworkReachabilityFlags? {
        didSet {
            guard self.flags != oldValue else { return }
            self.reachabilityChanged()
        }
    }

    public init?() {
        var zeroAddress = sockaddr()
        zeroAddress.sa_len = UInt8(MemoryLayout<sockaddr>.size)
        zeroAddress.sa_family = sa_family_t(AF_INET)
        
        if let ref = SCNetworkReachabilityCreateWithAddress(nil, &zeroAddress) {
            self.reachabilityRef = ref
        } else if let ref = SCNetworkReachabilityCreateWithName(nil, "google.com") {
            self.reachabilityRef = ref
        } else {
            self.reachabilityRef = nil
            return nil
        }
    }
    
    deinit {
        stop()
    }
}

public extension Reachability {
    @discardableResult func start() -> Bool {
        guard !self.running else { return true }
        
        let callback: SCNetworkReachabilityCallBack = { (reachability, flags, info) in
            guard let info = info else { return }
            
            let reachability = Unmanaged<Reachability>.fromOpaque(info).takeUnretainedValue()
            reachability.flags = flags
        }
        
        var context = SCNetworkReachabilityContext(version: 0, info: nil, retain: nil, release: nil, copyDescription: nil)
        context.info = UnsafeMutableRawPointer(Unmanaged<Reachability>.passUnretained(self).toOpaque())
        if !SCNetworkReachabilitySetCallback(self.reachabilityRef, callback, &context) {
            stop()
            return false
        }
        
        if !SCNetworkReachabilitySetDispatchQueue(self.reachabilityRef, reachabilitySerialQueue) {
            stop()
            return false
        }
        
        self.running = self.setReachabilityFlags()
        return self.running
    }
    
    func stop() {
        SCNetworkReachabilitySetCallback(self.reachabilityRef, nil, nil)
        SCNetworkReachabilitySetDispatchQueue(self.reachabilityRef, nil)
        self.running = false
    }
}

extension Reachability {
    func setReachabilityFlags() -> Bool {
        var result = false
        
        self.reachabilitySerialQueue.sync { [unowned self] in
            var flags = SCNetworkReachabilityFlags()
            if !SCNetworkReachabilityGetFlags(self.reachabilityRef, &flags) {
                self.stop()
            } else {
                self.flags = flags
                result = true
            }
        }
        return result
    }
    
    func reachabilityChanged() {
        DispatchQueue.main.async {
            NotificationCenter.default.post(name: Reachability.reachabilityChanged, object: nil)
        }
    }
}

extension SCNetworkReachabilityFlags {
    var connection: Plug.ConnectionType {
        guard self.isReachable else { return .offline }
        
        #if targetEnvironment(simulator)
            return .wifi
        #else
            var connection = Plug.ConnectionType.offline
        
            if !self.contains(.connectionRequired) {
                connection = .wifi
            }
        
            if self.contains(.connectionOnTraffic), !self.contains(.interventionRequired) { connection = .wifi }
		
				#if os(iOS)
            	if self.contains(.isWWAN) { connection = .cellular }
				#endif
            return connection
        #endif
    }
    
    var isReachable: Bool {
        return self.contains(.reachable)
    }
}
