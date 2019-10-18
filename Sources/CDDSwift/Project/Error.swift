//
//  Error.swift
//  CYaml
//
//  Created by Rob Saunders on 7/11/19.
//

import Foundation

enum ProjectError : Error {
	case InvalidSettingsFile(String)
	case InvalidHostname(String)
	case OpenAPIFile(String)
	case SourceFileParser(String)
	case NoSuchFile(String)

	var localizedDescription: String {
		switch self {
		case .InvalidHostname(let msg):
			return NSLocalizedString("Invalid hostname: \(msg)", comment: "")
		case .InvalidSettingsFile(let msg):
			return "Invalid settings file: \(msg)"
		case .OpenAPIFile(let msg):
			return "OpenAPI file: \(msg)"
		case .SourceFileParser(let msg):
			return "Source parser: \(msg)"
		case .NoSuchFile(let msg):
			return "No such file: \(msg)"
		}
	}
}
