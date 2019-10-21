//
//  SourceParser.swift
//  Basic
//
//  Created by Rob Saunders on 7/6/19.
//

import Foundation
import SwiftSyntax

let MODEL_PROTOCOL = "APIModel"
let REQUEST_PROTOCOL = "APIRequest"

/// count occurances of valid models
func modelCount(sourceFile: SourceFile) -> Int {
	var count: Int = 0

	let visitor = ClassVisitor()
	sourceFile.syntax.walk(visitor)

	for klass in visitor.klasses {
		if klass.interfaces.contains(MODEL_PROTOCOL) {
			count += 1
		}
	}

	return count
}

/// parse models from source
func parseModels(sourceFiles: [SourceFile]) -> [Model] {
	var models: [String:Model] = [:]

	for sourceFile in sourceFiles {
		let visitor = ClassVisitor()
		sourceFile.syntax.walk(visitor)

		for klass in visitor.klasses {
			if klass.interfaces.contains(MODEL_PROTOCOL) {
				models[klass.name] = Model(name: klass.name,
										   vars: klass.vars)
			}
		}
	}

	return Array(models.values)
}

// todo: simplify / remove
func parse(sourceFiles: [SourceFile]) -> ([Model],[Request]) {
    var models: [String:Model] = [:]
    var requests:[String:Request] = [:]
	for sourceFile in sourceFiles {
        let visitor = ClassVisitor()
		sourceFile.syntax.walk(visitor)
        
        for klass in visitor.klasses {
            if klass.interfaces.contains(MODEL_PROTOCOL) {
				models[klass.name] = Model(name: klass.name, vars: klass.vars)
            }
        }
        
        for klass in visitor.klasses {
            if klass.interfaces.contains(REQUEST_PROTOCOL) {
                if let responseType = klass.typeAliases["ResponseType"],
                    let errorType = klass.typeAliases["ErrorType"],
                    let path = klass.vars.first(where: {$0.name == "path"})?.value,
                    let methodRaw = klass.vars.first(where: {$0.name == "method"})?.value,
                    let method = Method(rawValue:methodRaw.components(separatedBy: ".").last?.uppercased() ?? ""){
                    var vars = klass.vars
                    vars.removeAll(where: {$0.name == "path" || $0.name == "method"})
                    requests[klass.name] = Request(name:klass.name, method: method, path: path, responseType: responseType, errorType: errorType, vars: vars)
                }
            }
        }
        
	}

	return (Array(models.values),Array(requests.values))
}

func parseProjectInfo(_ source: SourceFile) throws -> ProjectInfo {
	let visitor = ExtractVariables()
	source.syntax.walk(visitor)

    let host = visitor.variables.first(where: {$0.name == "HOST"})?.value ?? ""
    let endpoint = visitor.variables.first(where: {$0.name == "ENDPOINT"})?.value ?? ""
	
	return ProjectInfo(modificationDate: source.modificationDate, host: host, endpoint: endpoint)
}
