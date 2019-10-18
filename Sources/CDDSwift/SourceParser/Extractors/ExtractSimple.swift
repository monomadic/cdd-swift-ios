import SwiftSyntax

class ValueVisitor: SyntaxVisitor {
    var value: String?
    func walk(in child:Syntax) -> String? {
        child.walk(self)
        return self.value
    }
}

class ExtractReturnValue : ValueVisitor {
    
    override func visit(_ node: StringLiteralExprSyntax) -> SyntaxVisitorContinueKind {
        self.value = trim("\(node)")
        return .skipChildren
    }
}

class ExtractComlexPath : ValueVisitor {
    
    override func visit(_ node: StringInterpolationSegmentsSyntax) -> SyntaxVisitorContinueKind {
        self.value = trim("\(node)").replacingOccurrences(of: "\\(", with: "{").replacingOccurrences(of: ")", with: "}")
        return .skipChildren
    }
}

class ExtractMethodType : ValueVisitor {
    override func visit(_ node: ImplicitMemberExprSyntax) -> SyntaxVisitorContinueKind {
        self.value = trim("\(node)").replacingOccurrences(of: ".", with: "")
        return .skipChildren
    }
}

class ExtractAll : ValueVisitor {
    
    override func visit(_ node: TokenSyntax) -> SyntaxVisitorContinueKind {
        print(trim("\(node)"))
        return .skipChildren
    }
}
