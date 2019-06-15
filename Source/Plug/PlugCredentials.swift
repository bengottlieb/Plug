//
//  PlugCredentials.swift
//  Plug
//
//  Created by Ben Gottlieb on 5/17/18.
//  Copyright © 2018 Stand Alone, inc. All rights reserved.
//

import Foundation

public class Credentials {
	public static let instance = Credentials()
	var trustedDomains: [String] = []
	
	public var trustAllDomains = false
	
	public func addTrustedDomain(_ domain: String) {
		if !self.trustedDomains.contains(domain) {
			self.trustedDomains.append(domain)
		}
	}
	
	func isDomainTrusted(_ domain: String?) -> Bool {
		guard let domain = domain else { return true }
		if self.trustAllDomains { return true }
		
		return self.trustedDomains.contains(domain)
	}
}
