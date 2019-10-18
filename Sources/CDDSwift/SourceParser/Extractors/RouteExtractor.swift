//
//  FunctionExtractor.swift
//  Basic
//
//  Created by Rob Saunders on 20/04/2019.
//

import SwiftSyntax

struct FunctionExtract {
	var functionName: String?
}

class RouteExtractor : SyntaxVisitor {
	var method: String? = nil
	var operationId: String? = nil

	override func visit(_ node: FunctionDeclSyntax) -> SyntaxVisitorContinueKind {
		self.operationId = "\(node.identifier)"
		return .visitChildren
	}

	override func visit(_ node: MemberAccessExprSyntax) -> SyntaxVisitorContinueKind {
		if "\(node.description)".contains("JsonHttpClient") {
			method = "\(node.name)"
		}

		return .skipChildren
	}
}
