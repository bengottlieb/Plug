//
//  ConnectionLogViewController.swift
//  Plug_iOS
//
//  Created by Ben Gottlieb on 1/13/18.
//  Copyright © 2018 Stand Alone, inc. All rights reserved.
//

import UIKit


public class ConnectionLogViewController: UITableViewController {
	var log: ConnectionLog!
	var viewConnection: ((Connection) -> Void)?
	
	public static func show(in parent: UIViewController, viewConnection: ((Connection) -> Void)? = nil) {
		guard let log = Plug.log else { return }
		let controller = ConnectionLogViewController(log: log)
		
		controller.navigationItem.rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: .done, target: controller, action: #selector(ConnectionLogViewController.dismissController))
		
		controller.viewConnection = viewConnection
		let nav = UINavigationController(rootViewController: controller)
		parent.present(nav, animated: true, completion: nil)
	}
	
	public convenience init(log: ConnectionLog) {
		self.init(style: .plain)
		self.log = log
		
		self.navigationItem.leftBarButtonItem = UIBarButtonItem(title: "Clear", style: .plain, target: self, action: #selector(clearLog))
		
		NotificationCenter.default.addObserver(self, selector: #selector(reloadTable), name: ConnectionLog.Notifications.didLogConnection, object: nil)
	}
	
	@objc func dismissController() {
		self.dismiss(animated: true, completion: nil)
	}
	
	@objc func reloadTable() {
		DispatchQueue.main.async {
			self.tableView.reloadData()
		}
	}
	
	@objc func clearLog() {
		self.log.clear()
		self.tableView.reloadData()
	}
	
	public override func numberOfSections(in tableView: UITableView) -> Int { return 1 }
	public override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
		return self.log.logged.count
	}
	
	public override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
		let cell = tableView.dequeueReusableCell(withIdentifier: "cell") ?? UITableViewCell(style: .subtitle, reuseIdentifier: "cell")
		
		let connection = self.log.logged[indexPath.row]
		cell.textLabel?.text = connection.url.absoluteString
		cell.detailTextLabel?.text = connection.url.absoluteString
		
		cell.textLabel?.lineBreakMode = .byTruncatingTail
		cell.detailTextLabel?.lineBreakMode = .byTruncatingHead
		return cell
	}
	
	public override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
		print("\(self.log.logged[indexPath.row])")
		tableView.deselectRow(at: indexPath, animated: true)
		self.viewConnection?(self.log.logged[indexPath.row])
	}
}
