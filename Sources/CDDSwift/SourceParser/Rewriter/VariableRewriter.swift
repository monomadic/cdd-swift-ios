//
//  VariableRewriter.swift
//  CYaml
//
//  Created by Rob Saunders on 7/12/19.
//

import Foundation
import SwiftSyntax

extension SourceFileSyntax {
	mutating func renameVariable(_ varName: String, _ varValue: String) {
		let rewriter = VariableValueRewriter()
		rewriter.varName = varName
		rewriter.varValue = varValue
		self = rewriter.visit(self) as! SourceFileSyntax
	}

	mutating func addVariable(_ varName: String, _ varValue: String) {
		let rewriter = StructContentRewriter {
			return $0.appending(
				variableDecl(variableName: varName, variableType: varValue))
		}

		if let syntax = rewriter.visit(self) as? SourceFileSyntax {
			self = syntax
		} else {
			log.errorMessage("could not add variable \(varName)")
		}
	}
}

extension SourceFile {
	mutating func renameVariable(_ varName: String, _ varValue: String) -> Result<(), Swift.Error> {
		let rewriter = VariableValueRewriter()
		rewriter.varName = varName
		rewriter.varValue = varValue
		guard let syntax = rewriter.visit(self.syntax) as? SourceFileSyntax else {
			return .failure(ProjectError.SourceFileParser("error converting source syntax"))
		}
		self.syntax = syntax
		return .success(())
	}

	mutating func renameClassVariable(className: String, variable: Variable) -> Result<(), Swift.Error> {
		let rewriter = ClassVariableRewriter()
		guard let syntax = rewriter.visit(self.syntax) as? SourceFileSyntax else {
			return .failure(ProjectError.SourceFileParser("error converting source syntax"))
		}
		self.syntax = syntax
		return .success(())
	}
}
//
//class StructContentRewriter: SyntaxRewriter {
//	let rewriter: (TokenSyntax) -> TokenSyntax
//	init(rewriter: @escaping (TokenSyntax) -> TokenSyntax)
//	{
//		self.rewriter = rewriter
//	}
//
//	override func visit(_ token: TokenSyntax) -> Syntax {
//		let token2 = self.rewriter(token)
//		return super.visit(token2)
//	}
//}


//class StructRewriter: SyntaxRewriter {
//	let rewriter: (StructDeclSyntax) -> DeclSyntax
//
//	init(rewriter: @escaping (StructDeclSyntax) -> DeclSyntax) {
//		self.rewriter = rewriter
//	}
//
//	override func visit(_ node: StructDeclSyntax) -> DeclSyntax {
//		let node2 = self.rewriter(node)
//		return super.visit(node2) as! DeclSyntax
//	}
//}


class StructContentRewriter: SyntaxRewriter {
	let rewriter: (MemberDeclListSyntax) -> MemberDeclListSyntax

	init(rewriter: @escaping (MemberDeclListSyntax) -> MemberDeclListSyntax) {
		self.rewriter = rewriter
	}

	override func visit(_ node: MemberDeclListSyntax) -> Syntax {
		let node2 = self.rewriter(node)
		return super.visit(node2)
	}
}

class StructInserter: SyntaxRewriter {
    let rewriter: (StructDeclSyntax) -> DeclSyntax
    
    init(rewriter: @escaping (StructDeclSyntax) -> StructDeclSyntax) {
        self.rewriter = rewriter
    }
    
    
    override func visit(_ node: StructDeclSyntax) -> DeclSyntax {
        let node2 = self.rewriter(node)
        node
        return super.visit(node2) as! DeclSyntax
    }
}

open class AppendVariableRewriter: SyntaxRewriter {
	var varName: String
	var varValue: String

	init(varName: String, varValue: String) {
		self.varName = varName
		self.varValue = varValue
	}

	open override func visit(_ syntax: CodeBlockItemListSyntax) -> Syntax {
		let varItem = variableCodeBlock(variableName: self.varName, variableType: self.varValue)
		return super.visit(syntax.appending(varItem))
	}

//	open override func visit(_ node: Syntax) -> Syntax {
//		print("--\(type(of: node))")
//		return super.visit(node)
//	}

//	override open func visit(_ token: TokenSyntax) -> Syntax {
//		print(">>\(token.tokenKind)<<")
//		return super.visit(token)
//	}


//	public override func visit(_ node: StructDeclSyntax) -> DeclSyntax {
//		let structCode = variableCodeBlock(variableName: "aaaa", variableType: "Int")
//		node.add
//		return super.visit(structCode)
//	}

//	public override func visit(_ node: Syntax) -> Syntax {
//		let structCode = variableCodeBlock(variableName: "aaaa", variableType: "Int")
//
//		return super.visit(structCode)
//	}

//	public override func visit(_ node: CodeBlockSyntax) -> Syntax {
//		let returnNode = node.addCodeBlockItem(variableCodeBlock(variableName: "aaaa", variableType: "Int"))
//		return super.visit(returnNode)
//	}

//	public override func visit(_ syntax: SourceFileSyntax) -> Syntax {
//		var itemList = syntax.statements
//		let newItem = SyntaxFactory.makeCodeBlockItem(
//			item: variableCodeBlock(variableName: "thing", variableType: "Int"),
//			semicolon: nil,
//			errorTokens: nil)
//		itemList = itemList.appending(newItem)
//
//		print(newItem)
//		print(syntax.withStatements(itemList))
//
//
//
//		for child in syntax.children {
//			print("--\(child)")
//		}
//
//		return super.visit(syntax.withStatements(itemList))
//	}
}

public class ClassVariableRewriter: SyntaxRewriter {
	public override func visit(_ node: StructDeclSyntax) -> DeclSyntax {
		let rewriter = StringLiteralRewriter()
		log.errorMessage("UNFINISHED: ClassVariableRewriter()")
		return rewriter.visit(node)
	}
}

public class VariableValueRewriter: SyntaxRewriter {
	var varName: String? = nil
	var varValue: String? = nil
	var node: Syntax?

	public override func visit(_ node: PatternBindingSyntax) -> Syntax {
		let rewriter = StringLiteralRewriter()

		for child in node.children {
			if type(of: child) == IdentifierPatternSyntax.self {
				if trim("\(child)") == self.varName {
					rewriter.varValue = self.varValue
				}
			}
		}

		return rewriter.visit(node)
	}
}

public class StringLiteralRewriter: SyntaxRewriter {
	var varValue: String? = nil

	public override func visit(_ token: TokenSyntax) -> Syntax {
		switch token.tokenKind {
		case .stringLiteral(_):
			if case let .some(vv) = varValue {
				return token.withKind(.stringLiteral(vv))
			}
		default:
			()
		}

		return token
	}
}
