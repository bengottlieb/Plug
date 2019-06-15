//
//  PlugImageConnection.swift
//  Plug
//
//  Created by Ben Gottlieb on 4/11/17.
//  Copyright © 2017 Stand Alone, inc. All rights reserved.
//

import Foundation

#if canImport(UIKit)
    import UIKit
#endif

#if canImport(AppKit)
    import AppKit
#endif


extension Connection {
	public enum ImageConnectionError: Error { case noImageReturned }

    public func fetchImage(completion: @escaping (Result<UIImage, Error>) -> Void) {
		self.completion { connection, data in
			if let image = data.image {
				completion(.success(image))
			} else {
				completion(.failure(ImageConnectionError.noImageReturned))
			}
		}
		
		self.error { connection, error in
			completion(.failure(error))
		}
		
		self.start()
	}
	
}

extension Connection.ImageConnectionError: LocalizedError {
	public var errorDescription: String? {
		switch self {
		case .noImageReturned:
			return NSLocalizedString("No image found", comment: "No image found")
		}
	}
}
