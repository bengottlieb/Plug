//
//  Plug+iOS.swift
//  Plug
//
//  Created by Ben Gottlieb on 1/8/17.
//  Copyright © 2017 Stand Alone, inc. All rights reserved.
//

#if canImport(UIKit)
import UIKit

extension Plug {
    public static func warnIfOffline(in parent: UIViewController, title: String? = nil, message: String? = nil, execute: @escaping () -> Void) {
        if Plug.connectionType == .offline {
            let alert = UIAlertController(title: title ?? NSLocalizedString("You must be online to add pages", comment: "must be online to add pages title"),
                                          message: message ?? NSLocalizedString("Your internet connection appears to be offline.", comment: "must be online to add pages title"),
                                          preferredStyle: .alert)
            
            alert.addAction(UIAlertAction(title: NSLocalizedString("OK", comment: "OK"), style: .default, handler: { action in
            }))

            alert.addAction(UIAlertAction(title: NSLocalizedString("Retry", comment: "Retry"), style: .default, handler: { action in
                
                Plug.attemptReconnection() {
					DispatchQueue.main.async {
						execute()
					}
                }
            }))

            
            parent.present(alert, animated: true, completion: nil)
        } else {
            execute()
        }
    }
    

}
#endif
