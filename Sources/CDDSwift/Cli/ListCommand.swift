import Foundation
import SwiftCLI
import Willow

class ListCommand: Command {
    enum CommandType {
        case model, request
    }
    
    let name: String
    let shortDescription: String
    let type: CommandType
    
    let path = Param.Required<String>()
    
    let verbose = Flag("-v", "--verbose", description: "Show verbose output", defaultValue: false)
    //    let output = Key<String>("-f", "--output-file", description: "Output logging to file")
    
    
    init(_ type: CommandType) {
        switch type {
        case .model:
            name = "list-models"
            shortDescription = "Parsing swift sorce files to Models"
        case .request:
            name = "list-requests"
            shortDescription = "Parsing swift sorce files to Requests"
        }
        self.type = type
    }
    
    func execute() throws {
        
        if verbose.value {
            log.verbose()
        }
        
        if config.dryRun {
            log.infoMessage("CONFIG SETTING Dry run; no changes are written to disk")
        }
        
        read(path: path.value)
    }
    
    func read(path:String) {
        do {
            let file = try SourceFile(path: path)
            let objects = parse(sourceFiles: [file])
            
            switch type {
            case .model:
                try print(objects.0.json())
            case .request:
                try print(objects.1.json())
            }
            
            log.eventMessage("Project Readed")
        } catch let error as ProjectError {
            exitWithError(error.localizedDescription)
        } catch {
            exitWithError(error)
        }
    }
}
