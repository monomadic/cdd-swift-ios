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
	let path: String
	let responseType: String
	let errorType: String
	let vars: [Variable]
    
    var swaggerResponseType: String {
        var type = responseType
        if responseType.prefix(1) == "[" {
            type = responseType.replacingOccurrences(of: "[", with: "").replacingOccurrences(of: "]", with: "") + "s"
        }
        return type
    }
    
    enum CodingKeys: String, CodingKey {
        case name
        case method
        case path
        case responseType = "response_type"
        case errorType = "error_type"
        case vars
    }
    
}

enum Method: String, Codable {
	case get = "GET"
	case put = "PUT"
	case post = "POST"
    case delete = "DELETE"
}

///Users/alexei/.cdd/services/cdd-swift insert-request ./iOS/cddTemplate/Source/API/APIRequests.swift '{"name":"randomName","path":"/pets","vars":[{"name":"limit","type":"Int","optional":true,"value":null}],"method":"GET","response_type":"Pets","error_type":"Error"}'
