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

	func testMimeUpload() {
		let fileURL = NSBundle.mainBundle().URLForResource("sample_image", withExtension: "png")
		let url = "http://posttestserver.com/post.php"
		let payloadDict = ["Sample_Item": ["embedded": "data goes here", "Test": "Field 1", "one-level-more": ["name": "Bonzai", "career": "Buckaroo"]]]
		
		let components = Plug.FormComponents(fields: payloadDict)
		components.addFile(fileURL, name: "test file", mimeType: "image/png")
		
		let payload = Plug.Parameters.Form(components)
		
		
		
		Plug.request(.POST, URL: url, parameters: payload).completion { request, data in
			print("Request: \(request)")
		}.error { request, error in
				
		}.start()
	}

	func application(application: UIApplication, didFinishLaunchingWithOptions launchOptions: [NSObject: AnyObject]?) -> Bool {
		Plug.instance.setup()
		
//		self.timeoutTests()
		self.testMimeUpload()
		
		return true
	}

	func applicationWillResignActive(application: UIApplication) {
	}

	func timeoutTests() {
		Plug.instance.timeout = 5.0
		
		//let largeURL = NSURL(string: "https://developer.apple.com/services-account/download?path=/iOS/iAd_Producer_5.1/iAd_Producer_5.1.dmg")!
		
		let url = NSURL(string: "https://192.168.1.62")!
		let request = Plug.request(.GET, URL: url)
		
		request.completion { req, data in
			print("complete")
		}
		
		request.error { req, error in
			print("Error: \(error)")
		}
		
		request.start()
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

