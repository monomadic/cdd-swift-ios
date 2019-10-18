import Foundation
import SwiftSyntax
import SwiftCLI
import Willow

class Config {
	var dryRun: Bool = false
}

let config = Config()

let cli = CLI(
    name: "cdd-swift",
    version: "0.1.0",
    description: "Compiler Driven Development: Swift Adaptor",
    commands: [
        ListCommand(.model),
        ListCommand(.request),
        WriteCommand(operation:.insert,source:.model),
        WriteCommand(operation:.update,source:.model),
        WriteCommand(operation:.delete,source:.model),
        WriteCommand(operation:.insert,source:.request),
        WriteCommand(operation:.update,source:.request),
        WriteCommand(operation:.delete,source:.request)
        
    ]
)

cli.goAndExit()
