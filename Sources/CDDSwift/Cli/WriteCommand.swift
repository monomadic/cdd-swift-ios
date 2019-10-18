import Foundation
import SwiftCLI
import Willow

class WriteCommand: Command {
    enum SourceType: String {
        case model, request
    }
    enum OperationType: String {
        case insert,update,delete
    }
    
    let name: String
    let shortDescription: String
    let operation: OperationType
    let source: SourceType
    
    let path = Param.Required<String>()
    let json = Param.Required<String>()
    let verbose = Flag("-v", "--verbose", description: "Show verbose output", defaultValue: false)
    //    let output = Key<String>("-f", "--output-file", description: "Output logging to file")
    
    
    init(operation: OperationType, source: SourceType) {
        self.operation = operation
        name = operation.rawValue + "-" + source.rawValue + "s"
        shortDescription = "\(operation.rawValue) \(source.rawValue) to swift sorce files"
        self.source = source
    }
    
    func execute() throws {
        
        if verbose.value {
            log.verbose()
        }
        
        if config.dryRun {
            log.infoMessage("CONFIG SETTING Dry run; no changes are written to disk")
        }
        
        try write(path: path.value, json: json.value)
    }
    
    func write(path: String, json:String) throws {
        do {
            var file = try SourceFile(path: path)
            switch operation {
            case .insert:
                switch source {
                case .model:
                    try file.insert(model: Model.from(json: json))
                case .request:
                    try file.insert(request: Request.from(json: json))
                }
            case .update:
                switch source {
                case .model:
                    try file.update(model: Model.from(json: json))
                case .request:
                    try file.update(request: Request.from(json: json))
                }
            case .delete:
                switch source {
                case .model:
                    file.remove(name: json)
                case .request:
                    file.remove(name: json)
                }
            }
            
            writeStringToFile(file: file.url, contents: "\(file.syntax)")
//            try projectReader.generateTests()
//            projectReader.write()
        } catch let error as ProjectError {
            exitWithError(error.localizedDescription)
        } catch {
            exitWithError(error)
        }
    }
}
