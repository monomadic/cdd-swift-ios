////  RoutesVisitor
////  - finds and identifies models and model fields

import SwiftSyntax

struct Klass {
    let name: String
    var interfaces: [String] = []
    var vars: [Variable] = []
    var typeAliases: [String:String] = [:]
    init(name: String) {
        self.name = name
    }
}

class ClassVisitor : SyntaxVisitor {
    var klasses: [Klass] = []
    var syntaxes: [String:StructDeclSyntax] = [:]
    override func visit(_ node: StructDeclSyntax) -> SyntaxVisitorContinueKind {
        let klassName = "\(node.identifier)".trimmingCharacters(in: .whitespaces)
        var klass = Klass(name: klassName)
        
        for member in node.children {
            if type(of: member) == TypeInheritanceClauseSyntax.self {
                for child in member.children {
                    if type(of: child) == InheritedTypeListSyntax.self {
                        klass.interfaces.append(trim("\(child)"))
                    }
                }
            }
        }
        let extractFields = ExtractVariables()
        node.walk(extractFields)
        klass.vars = extractFields.variables
        
        let extractAliases = ExtractTypealiases()
        node.walk(extractAliases)
        klass.typeAliases = extractAliases.aliases
        
        
        klasses.append(klass)
        syntaxes[klass.name] = node
        
        return .skipChildren
    }
}

