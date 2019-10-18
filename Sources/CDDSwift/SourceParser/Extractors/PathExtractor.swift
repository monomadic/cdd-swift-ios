//
//  PathExtractor.swift
//  Basic
//
//  Created by Rob Saunders on 20/04/2019.
//

import SwiftSyntax

class PathExtractor : SyntaxVisitor {
	var baseUrl: String? = nil

	override func visit(_ node: PatternBindingSyntax) -> SyntaxVisitorContinueKind {
		var key: String?
		var value: String?

		for child in node.children {
			switch type(of: child) {
			case is IdentifierPatternSyntax.Type:
				key = "\(child)".trimmingCharacters(in: .whitespaces)
			case is InitializerClauseSyntax.Type:
				for child in child.children {
					if type(of: child) == StringLiteralExprSyntax.self {
						value = "\(child)".trimmingCharacters(in: .whitespaces)
					}
				}
			default: ()
			}

		}
		
		if key == Optional("baseUrl") {
			if let baseUrl = value {
				self.baseUrl = baseUrl
			}
		}

		return .skipChildren
	}
}
