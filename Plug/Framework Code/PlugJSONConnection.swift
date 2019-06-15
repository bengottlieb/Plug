//
//  PlugJSONConnection.swift
//  Plug
//
//  Created by Ben Gottlieb on 5/20/16.
//  Copyright © 2016 Stand Alone, inc. All rights reserved.
//

import Foundation


extension Connection {
	public enum JSONConnectionError: Error { case noJSONReturned }
	
    public func fetchJSON(completion: @escaping (Result<JSONDictionary, Error>) -> Void) {
		self.completion { connection, data in
			if let json = data.json {
                completion(.success(json))
			} else {
                completion(.failure(JSONConnectionError.noJSONReturned))
			}
		}
		
		self.error { connection, error in
            completion(.failure(error))
		}
        
        self.start()
	}
	
}
