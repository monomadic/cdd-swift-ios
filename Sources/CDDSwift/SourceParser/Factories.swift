//
//  Factories.swift
//  CYaml
//
//  Created by Rob Saunders on 7/18/19.
//

import Foundation
import SwiftSyntax

let STRUCT_TEMPLATE = """
struct $0 : $1 {
}
"""

extension SourceFileSyntax {
	static func fromString(_ source: String) throws -> SourceFileSyntax {
		// The “master” branch of SwiftSyntax can parse source strings directly,
		// but the current release still requires a file.
		let temporary = URL(fileURLWithPath: NSTemporaryDirectory())
			.appendingPathComponent(UUID().uuidString + ".swift")
		defer { try? FileManager.default.removeItem(at: temporary) }

		let directory = temporary.deletingLastPathComponent()
		try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true, attributes: nil)
		try source.data(using: .utf8)?.write(to: temporary, options: [.atomic])

		let sourceSyntax = try SyntaxTreeParser.parse(temporary)

		return sourceSyntax
	}
}

func makeStruct(name: String, type: String) -> SourceFileSyntax {
	return try! SourceFileSyntax.fromString(STRUCT_TEMPLATE.replacingOccurrences(of: "$0", with: name).replacingOccurrences(of: "$1", with: type))
}
