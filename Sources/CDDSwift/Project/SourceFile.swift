//
//  SourceFile.swift
//  CYaml
//
//  Created by Rob Saunders on 7/16/19.
//

import Foundation
import SwiftSyntax

protocol ProjectSource {
    mutating func remove(name: String)
    mutating func insert(model:Model) throws
    mutating func update(model:Model)
    mutating func insert(request:Request) throws
    mutating func update(request:Request)
}

struct SourceFile: ProjectSource {
	let url: URL
	let modificationDate: Date
	var syntax: SourceFileSyntax

	init(path: String) throws {
		do {
			let url = URL(fileURLWithPath: path)
			self.url = url
			self.modificationDate = try fileLastModifiedDate(url: url)
			self.syntax = try SyntaxTreeParser.parse(url)

			log.eventMessage("File read: \(path)")
		}
	}

	private init(url: URL, modificationDate: Date, syntax: SourceFileSyntax) {
		self.url = url
		self.modificationDate = modificationDate
		self.syntax = syntax
	}

	mutating func update(projectInfo: ProjectInfo) {
		let _ = self.renameVariable("HOST", projectInfo.host)
		let _ = self.renameVariable("ENDPOINT", projectInfo.endpoint)
	}

    mutating func remove(name: String) {
        self.syntax = ClassRemover.remove(name: name, in: self.syntax)
    }
    
    mutating func insert(model: Model) throws {
        let structTemplate = STRUCT_TEMPLATE.replacingOccurrences(of: "$0", with: model.name).replacingOccurrences(of: "$1", with: "APIModel")
        
        let text = "\(syntax)"
        try (text + "\n" + structTemplate + "\n").write(to: url, atomically: true, encoding: .utf8)
        
        self = try SourceFile(path: url.path)
        
        update(vars:model.vars,oldVars:[],inClass:model.name)
    }
    
    mutating func update(model: Model) {
        let result = parse(sourceFiles: [self])
        guard let oldModel = result.0.first(where: {$0.name == model.name}) else { return }
        update(vars: model.vars,oldVars: oldModel.vars, inClass: model.name)
    }
    
    mutating func update(vars: [Variable], oldVars: [Variable], inClass name:String) {
        let changes = vars.compare(to: oldVars)
        
        for change in changes {
            guard let classSyntax = findClass(name: name) else { return }
            
            var newClassSyntax: Syntax!
            switch change {
            case .deletion(let variable):
                newClassSyntax = VariableRemover.remove(name: variable.name, in: classSyntax)
            case .insertion(let variable):
                let rewriter = StructContentRewriter {
                    return $0.appending(variable.syntax())
                }
                newClassSyntax = rewriter.visit(classSyntax)
            case .same(let variable):
                newClassSyntax = VariableRewriter.rewrite(name: variable.name, syntax: variable.syntax(), in: classSyntax)
            }
            self.syntax = ClassRewriter.rewrite(name: name, syntax: newClassSyntax, in: self.syntax)
        }
    }
    
    mutating func insert(request:Request) throws {
        let structTemplate = STRUCT_TEMPLATE.replacingOccurrences(of: "$0", with: request.name).replacingOccurrences(of: "$1", with: "APIRequest")
        
        let text = "\(syntax)"
        try (text + "\n" + structTemplate + "\n ").write(to: url, atomically: true, encoding: .utf8)
        
        self = try SourceFile(path: url.path)
        
        update(vars:request.vars,oldVars:[],inClass:request.name)
        
        let responseTypeItem = SyntaxFactory.makeMemberDeclListItem(decl: request.responseTypeSyntax(), semicolon: nil)
        let errorTypeItem = SyntaxFactory.makeMemberDeclListItem(decl: request.errorTypeSyntax(), semicolon: nil)
        let rewriter = StructContentRewriter {
            return $0.inserting(request.methodSyntax(), at: 0)
                .inserting(request.urlSyntax(), at: 0)
                .inserting(errorTypeItem, at: 0)
                .inserting(responseTypeItem, at: 0)
        }
        
        guard let classSyntax = findClass(name: request.name) else { return }
        let newClassSyntax = rewriter.visit(classSyntax)
        self.syntax = ClassRewriter.rewrite(name: request.name, syntax: newClassSyntax, in: self.syntax)
    }
    
    mutating func update(request:Request) {
        let result = parse(sourceFiles: [self])
        guard let oldRequest = result.1.first(where: {$0.name == request.name}) else { return }
        update(vars: request.vars,oldVars: oldRequest.vars, inClass: request.name)
        
        
        guard let classSyntax = findClass(name: request.name) else { return }
        
        var newClassSyntax = TypeAliasRewriter.rewrite(name: "ResponseType", syntax: request.responseTypeSyntax(), in: classSyntax)
        newClassSyntax = TypeAliasRewriter.rewrite(name: "ErrorType", syntax: request.errorTypeSyntax(), in: newClassSyntax)
        newClassSyntax = VariableRewriter.rewrite(name: "path", syntax: request.urlSyntax(), in: newClassSyntax)
        newClassSyntax = VariableRewriter.rewrite(name: "method", syntax: request.methodSyntax(), in: newClassSyntax)
        self.syntax = ClassRewriter.rewrite(name: request.name, syntax: newClassSyntax, in: self.syntax)
    }
    
    
    func findClass(name: String) -> StructDeclSyntax? {
        let visitor = ClassVisitor()
        syntax.walk(visitor)
        return visitor.syntaxes[name]
    }
    
    static func create(path: String, name: String, structType: String) -> SourceFile? {
        guard let url = URL(string: path) else {
            return nil
        }
		// todo: add fields
		return SourceFile(
			url: url,
			modificationDate: Date(),
            syntax: makeStruct(name: name, type:structType))
	}

	func containsClassWith(name: String) -> Bool {
		let visitor = ClassVisitor()
		self.syntax.walk(visitor)
        return visitor.klasses.contains(where: {$0.name == name})
	}
}

extension Request {
    
    func methodSyntax() -> MemberDeclListItemSyntax {
        let type = "HTTPMethod"
        
        let initializer = InitializerClauseSyntax {
            $0.useEqual(SyntaxFactory.makeEqualToken().withLeadingTrivia(.spaces(1)).withTrailingTrivia(.spaces(1)))
            $0.useValue(SyntaxFactory.makeVariableExpr("." + method.rawValue.lowercased()))
        }
        let Pattern = SyntaxFactory.makePatternBinding(
            pattern: SyntaxFactory.makeIdentifierPattern(
                identifier: SyntaxFactory.makeIdentifier("method").withLeadingTrivia(.spaces(1))),
            typeAnnotation: SyntaxFactory.makeTypeAnnotation(
                colon: SyntaxFactory.makeColonToken().withTrailingTrivia(.spaces(1)),
                type: SyntaxFactory.makeTypeIdentifier(type)),
            initializer: initializer, accessor: nil, trailingComma: nil)
        
        let decl = VariableDeclSyntax {
            $0.useLetOrVarKeyword(SyntaxFactory.makeLetKeyword().withLeadingTrivia([.carriageReturns(1), .tabs(1)]))
            $0.addPatternBinding(Pattern)
        }
        
        let listItem = SyntaxFactory.makeMemberDeclListItem(decl: decl, semicolon: nil)
        return listItem
    }
    
    func urlSyntax() -> MemberDeclListItemSyntax {
        let convertedUrlPath = path.replacingOccurrences(of: "{", with: "\\(").replacingOccurrences(of: "}", with: ")")
        return closureSyntax(name: "path", type: "String", returnValue: "\"" + convertedUrlPath + "\"")
    }
    
    func responseTypeSyntax() -> TypealiasDeclSyntax {
        return typealiasSyntax(name: "ResponseType", type: responseType)
    }
    
    func errorTypeSyntax() -> TypealiasDeclSyntax {
        return typealiasSyntax(name: "ErrorType", type: errorType)
    }
    
    private func typealiasSyntax(name: String, type: String) -> TypealiasDeclSyntax {
        
        let initializer = TypeInitializerClauseSyntax {
            $0.useEqual(SyntaxFactory.makeEqualToken().withLeadingTrivia(.spaces(1)).withTrailingTrivia(.spaces(1)))
            $0.useValue(SyntaxFactory.makeTypeIdentifier(type))
        }
        
        let decl = TypealiasDeclSyntax {
            $0.useTypealiasKeyword(SyntaxFactory.makeTypealiasKeyword().withLeadingTrivia([.carriageReturns(1), .tabs(1)]))
            $0.useIdentifier(SyntaxFactory.makeStringLiteral(name).withLeadingTrivia(.spaces(1)))
            $0.useInitializer(initializer)
        }
        
        return decl
    }
    
    
    private func closureSyntax(name: String, type: String, returnValue: String) -> MemberDeclListItemSyntax {
        
        let codeBlock = CodeBlockItemSyntax {
            $0.useItem(SyntaxFactory.makeReturnKeyword().withLeadingTrivia(.spaces(1)))
        }
        let codeBlock2 = CodeBlockItemSyntax {
            $0.useItem(SyntaxFactory.makeStringLiteral(returnValue).withTrailingTrivia(.spaces(1)).withLeadingTrivia(.spaces(1)))
        }
        
        let closure = ClosureExprSyntax {
            $0.useLeftBrace(SyntaxFactory.makeLeftBraceToken().withLeadingTrivia(.spaces(1)))
            $0.addCodeBlockItem(codeBlock)
            $0.addCodeBlockItem(codeBlock2)
            $0.useRightBrace(SyntaxFactory.makeRightBraceToken())
        }
        
        let Pattern = SyntaxFactory.makePatternBinding(
            pattern: SyntaxFactory.makeIdentifierPattern(
                identifier: SyntaxFactory.makeIdentifier(name).withLeadingTrivia(.spaces(1))),
            typeAnnotation: SyntaxFactory.makeTypeAnnotation(
                colon: SyntaxFactory.makeColonToken().withTrailingTrivia(.spaces(1)),
                type: SyntaxFactory.makeTypeIdentifier(type)),
            initializer: nil, accessor: closure, trailingComma: nil)
        
        
        let decl = VariableDeclSyntax {
            $0.useLetOrVarKeyword(SyntaxFactory.makeVarKeyword().withLeadingTrivia([.carriageReturns(1), .tabs(1)]))
            $0.addPatternBinding(Pattern)
        }
        
        let listItem = SyntaxFactory.makeMemberDeclListItem(decl: decl, semicolon: nil)
        return listItem
    }
}


extension Variable {
    func syntax() -> MemberDeclListItemSyntax {
        let type = self.type.swiftCode() + (optional ? "?" : "")
        let Pattern = SyntaxFactory.makePatternBinding(
            pattern: SyntaxFactory.makeIdentifierPattern(
                identifier: SyntaxFactory.makeIdentifier(name).withLeadingTrivia(.spaces(1))),
            typeAnnotation: SyntaxFactory.makeTypeAnnotation(
                colon: SyntaxFactory.makeColonToken().withTrailingTrivia(.spaces(1)),
                type: SyntaxFactory.makeTypeIdentifier(type)),
            initializer: nil, accessor: nil, trailingComma: nil)
        
        let decl = VariableDeclSyntax {
            $0.useLetOrVarKeyword(SyntaxFactory.makeLetKeyword().withLeadingTrivia([.carriageReturns(1), .tabs(1)]))
            $0.addPatternBinding(Pattern)
        }
        
        let listItem = SyntaxFactory.makeMemberDeclListItem(decl: decl, semicolon: nil)
        return listItem
    }
    
    func swiftCode() -> String {
        return name + ": " + type.swiftCode() + (optional ? "?" : "")
    }
}

extension Type {
    func swiftCode() -> String {
        switch self {
        case .primitive(let type):
            return type.rawValue
        case .array(let type):
            return "[\(type.swiftCode())]"
        case .complex(let type):
            return type
        }
    }
}
