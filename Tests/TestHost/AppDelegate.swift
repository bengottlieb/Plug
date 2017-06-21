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
	let pendingData = IncomingData(url: URL(string: "http://stackoverflow.com/questions/34182482/nsurlsessiondatadelegate-not-called")!)

//	let incoming = Incoming<Data>(url: URL(string: "http://stackoverflow.com/questions/34182482/nsurlsessiondatadelegate-not-called")!) { data in
//		print("Data: \(data)")
//		return data.data
//	}

	func testLargeDownloads() {
		let largeURL = URL(string: "https://dl.dropboxusercontent.com/u/85235/Stereotypies%20Therapy.mp4")!
		Plug.instance.timeout = 5.0
		
		let d1: JSONDictionary = ["h": "y"]
		let d2: JSONDictionary = ["h": "y"]
		
		print(d1 == d2)
		
		
		let connection = Plug.request(method: .GET, url: largeURL).completion { request, data in
			print("Completed")
		}.error { request, error in
			print("Failed with error: \(error)")
		}.progress {conn, percent in
			print("Completed \(percent * 100.0)%")
		}
		
		connection.start()
	}
	
	func testSmallDownloads() {
		let smallURL = URL(string: "http://stackoverflow.com/questions/34182482/nsurlsessiondatadelegate-not-called")!
		
		
		let connection = Plug.request(method: .GET, url: smallURL).completion { request, data in
			print("Completed, got \(data.length) bytes")
		}.error { request, error in
			print("Failed with error: \(error)")
		} 
		
		connection.start()
	}
	
	func testMimeUpload() {
		let fileURL = Bundle.main.url(forResource: "sample_image", withExtension: "png")
		let url = "http://posttestserver.com/post.php"
		let payloadDict = ["Sample_Item": ["embedded": "data goes here", "Test": "Field 1", "one-level-more": ["name": "Bonzai", "career": "Buckaroo"]]]
		
		let components = Plug.FormComponents(fields: payloadDict)
		components.addFile(url: fileURL, name: "test file", mimeType: "image/png")
		
		let payload = Plug.Parameters.form(components)
		
		
		
		Plug.request(method: .POST, url: url, parameters: payload).completion { request, data in
			print("Request: \(request)")
		}.error { request, error in
				
		}.start()
	}
	
	func testJSONDownload() {
		let url = "http://jsonview.com/example.json"
		
		Connection(url: url)?.fetchJSON().then { json in
			print("Request: \(json)")
		}
	}
	
	func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplicationLaunchOptionsKey : Any]? = nil) -> Bool {
		Plug.instance.setup()
		
		let jsonD = ["A": "B"]
		let jrep = jsonD.jsonRepresentation
		let jsonA = ["A", "B"]
		let jrep2 = jsonA.jsonRepresentation
		
		print("\(jrep!), \(jrep2!)")
		
//		self.testLargeDownloads()
//		self.testLargeDownloads()
		for _ in 0...10 {
			self.testJSONDownload()
		}
		return true
	}

	func applicationWillResignActive(_ application: UIApplication) {
	}

	func timeoutTests() {
		Plug.instance.timeout = 35.0
		
		//let largeURL = URL(string: "https://developer.apple.com/services-account/download?path=/iOS/iAd_Producer_5.1/iAd_Producer_5.1.dmg")!
		
		let url = URL(string: "https://192.168.1.62")!
		let request = Plug.request(method: .GET, url: url)
		
		_ = request.completion { req, data in
			print("complete")
		}
		
		_ = request.error { req, error in
			print("Error: \(error)")
		}
		
		request.start()
	}
	
	func applicationDidEnterBackground(_ application: UIApplication) {
		let url = "https://serenitynow.herokuapp.com/devices/online"
		let args: JSONDictionary = ["device": ["udid": UIDevice.current.identifierForVendor!.uuidString]]
	
		Plug.request(method: .DELETE, url: url, parameters: Plug.Parameters.json(args)).completion { conn, data in
			print("got it \(NSString(data: data.data, encoding: String.Encoding.utf8.rawValue) ?? "??")")
		}.start()
	}

	func applicationWillEnterForeground(_ application: UIApplication) {
	}

	func applicationDidBecomeActive(_ application: UIApplication) {
	}

	func applicationWillTerminate(_ application: UIApplication) {
	}


}

