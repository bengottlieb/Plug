//
//  HTTPCookie+Plug.swift
//  Plug
//
//  Created by Ben Gottlieb on 5/17/18.
//  Copyright © 2018 Stand Alone, inc. All rights reserved.
//

import Foundation

extension HTTPCookieStorage {
	func finished(connection: Connection) {
		self.cookieAcceptPolicy = .always
		for cookie in connection.responseCookies {
			self.setCookie(cookie)
		}
	}
	
	func cookiesHeader(for connection: Connection) -> Plug.Header? {
		guard Plug.instance.addCookies, let cookies = self.cookies(for: connection.url) else { return nil }
		let dict = HTTPCookie.requestHeaderFields(with: cookies)
		if let header = dict["Cookie"] ?? dict["Cookies"] {
			return .cookie(header)
		}
		return nil
	}
	
}
