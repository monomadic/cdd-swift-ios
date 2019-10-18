//
//  MemberVariableExtractor

import SwiftSyntax

class MemberVariableExtractor : SyntaxVisitor {
	var memberVars: [String:String] = [:]

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
						value = "\(child)".trimmingCharacters(in: .whitespaces).replacingOccurrences(of: "\"", with: "")
					}
				}
			default: ()
			}

		}
		if let key = key, let value = value {
			self.memberVars[key] = value
		}

		return .skipChildren
	}
}
