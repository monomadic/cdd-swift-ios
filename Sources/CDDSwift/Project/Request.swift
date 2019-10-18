//
//  Request.swift
//  CYaml
//
//  Created by Rob Saunders on 7/16/19.
//

import Foundation
struct Request: ProjectObject, Codable {
	let name: String
	let method: Method
	let urlPath: String
	let responseType: String
	let errorType: String
	let vars: [Variable]
    var modificationDate: Date
    
    var swaggerResponseType: String {
        var type = responseType
        if responseType.prefix(1) == "[" {
            type = responseType.replacingOccurrences(of: "[", with: "").replacingOccurrences(of: "]", with: "") + "s"
        }
        return type
    }
}

enum Method: String, Codable {
	case get
	case put
	case post
    case delete
}
