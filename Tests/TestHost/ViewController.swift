//
//  ViewController.swift
//  Plug
//
//  Created by Ben Gottlieb on 2/9/15.
//  Copyright (c) 2015 Stand Alone, inc. All rights reserved.
//

import UIKit
import Plug

class ViewController: UIViewController {
	@IBOutlet var statusLabel: UILabel!
	override func viewDidLoad() {
		super.viewDidLoad()
		
		NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(ViewController.onlineStatusChanged), name: Plug.notifications.onlineStatusChanged, object: nil)
		
		self.onlineStatusChanged()
		// Do any additional setup after loading the view, typically from a nib.
	}
	
	func onlineStatusChanged() {
		dispatch_async(dispatch_get_main_queue()) {
			switch (Plug.connectionType) {
			case .Offline: self.statusLabel.text = "Offline"
			case .Wifi: self.statusLabel.text = "WiFi"
			case .WAN: self.statusLabel.text = "WAN"
			}
		}
	}

	override func didReceiveMemoryWarning() {
		super.didReceiveMemoryWarning()
		// Dispose of any resources that can be recreated.
	}


}

