import SwiftSyntax

class ExtractTypealiases : SyntaxVisitor {
    var aliases : [String:String] = [:]
    
    override func visit(_ node: TypealiasDeclSyntax) -> SyntaxVisitorContinueKind {
        
        
        let words = "\(node)".trimmedWhiteSpaces.components(separatedBy: " ").compactMap({ (value) -> String? in
           let new = value.trimmedWhiteSpaces
            return new.count > 0 ? new : nil
        })
        if words.count == 4 {
            aliases[words[1]] = words[3]
        }
        
        return .skipChildren
    }
    
}


