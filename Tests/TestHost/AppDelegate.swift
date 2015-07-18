//
//  AppDelegate.swift
//  Plug
//
//  Created by Ben Gottlieb on 2/9/15.
//  Copyright (c) 2015 Stand Alone, inc. All rights reserved.
//

import UIKit
import Plug

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

	var window: UIWindow?


	func application(application: UIApplication, didFinishLaunchingWithOptions launchOptions: [NSObject: AnyObject]?) -> Bool {
		Plug.manager.setup()
		return true
	}

	func applicationWillResignActive(application: UIApplication) {
	}

	func applicationDidEnterBackground(application: UIApplication) {
		let url = "https://serenitynow.herokuapp.com/devices/online"
		let args = ["device": ["udid": UIDevice.currentDevice().identifierForVendor!.UUIDString]]
	
		Plug.request(.DELETE, URL: url, parameters: Plug.Parameters.JSON(args)).completion { conn, data in
			print("got it \(NSString(data: data, encoding: NSUTF8StringEncoding))")
		}.start()
	}

	func applicationWillEnterForeground(application: UIApplication) {
	}

	func applicationDidBecomeActive(application: UIApplication) {
	}

	func applicationWillTerminate(application: UIApplication) {
	}


}

