//
//  Rewriters.swift
//  cdd-swift
//
//  Created by Alexei on 19/07/2019.
//



import Foundation
import SwiftSyntax



public class ClassRewriter: SyntaxRewriter {
    static func rewrite(name: String, syntax:Syntax, in sourceFileSyntax:SourceFileSyntax) -> SourceFileSyntax {
        let rewriter = ClassRewriter()
        rewriter.syntax = syntax
        rewriter.name = name
        return rewriter.visit(sourceFileSyntax) as! SourceFileSyntax
    }
    var syntax: Syntax!
    var name: String!
    override public func visit(_ node: StructDeclSyntax) -> DeclSyntax {
        let visitor = ClassVisitor()
        node.walk(visitor)
        if visitor.klasses.first?.name == name {
            return syntax as! DeclSyntax
        }
        return node
    }
}

public class VariableRewriter: SyntaxRewriter {
    static func rewrite(name: String, syntax:Syntax, in mainSyntax:Syntax) -> Syntax {
        let rewriter = VariableRewriter()
        rewriter.syntax = syntax
        rewriter.name = name
        return rewriter.visit(mainSyntax)
    }
    var syntax: Syntax!
    var name: String!
    override public func visit(_ node: MemberDeclListItemSyntax) -> Syntax {

        if node.child(at: 1)?.description == name {
            return syntax
        }
        return node
    }
}

public class VariableRemover: SyntaxRewriter {
    static func remove(name: String, in mainSyntax:Syntax) -> Syntax {
        let rewriter = VariableRemover()
        rewriter.name = name
        return rewriter.visit(mainSyntax)
    }
    var name: String!
    override public func visit(_ node: MemberDeclListSyntax) -> Syntax {
        
        for (index,child) in node.children.enumerated() {
            let extractor = ExtractVariables()
            child.walk(extractor)
            if extractor.variables.first?.name == name {
                return node.removing(childAt: index)
            }
        }
        
        return node
    }
}


public class ClassRemover: SyntaxRewriter {
    static func remove(name: String, in sourceFileSyntax:SourceFileSyntax) -> SourceFileSyntax {
        let rewriter = ClassRemover()
        rewriter.name = name
        return rewriter.visit(sourceFileSyntax) as! SourceFileSyntax
    }
    var name: String!
    override public func visit(_ node: CodeBlockItemSyntax) -> Syntax {
        let visitor = ClassVisitor()
        node.walk(visitor)
        if visitor.klasses.first?.name == name {
            return SyntaxFactory.makeStringSegment("")
        }
        return node
    }
}


public class TypeAliasRewriter: SyntaxRewriter {
    static func rewrite(name: String, syntax:DeclSyntax, in mainSyntax:Syntax) -> Syntax {
        let rewriter = TypeAliasRewriter()
        rewriter.syntax = syntax
        rewriter.name = name
        return rewriter.visit(mainSyntax)
    }
    var syntax: DeclSyntax!
    var name: String!
    override public func visit(_ node: TypealiasDeclSyntax) -> DeclSyntax {
        let extractor = ExtractTypealiases()
        node.walk(extractor)
        
        if extractor.aliases.keys.first == name {
            return syntax
        }
        return node
    }
}
