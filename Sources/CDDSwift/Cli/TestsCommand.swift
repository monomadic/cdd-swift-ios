//
//  GenerateTestsCommand.swift
//  CDDSwift
//
//  Created by Alexei on 14/11/2019.
//
import Foundation
import SwiftCLI
import Willow

class TestsCommand: Command {
    let name: String = "generate-tests"
    let shortDescription: String = "Generating tests"
    
    let projectName = Param.Required<String>()
    let path = Param.Required<String>()
    let pathToTest = Param.Required<String>()
    let verbose = Flag("-v", "--verbose", description: "Show verbose output", defaultValue: false)
    //    let output = Key<String>("-f", "--output-file", description: "Output logging to file")
    
    
    
    func execute() throws {
        
        if verbose.value {
            log.verbose()
        }
        
        if config.dryRun {
            log.infoMessage("CONFIG SETTING Dry run; no changes are written to disk")
        }
        
        let allFiles = try FileManager.default.contentsOfDirectory(atPath: path.value)
        let files = try allFiles.filter({$0.components(separatedBy: ".").last == "swift"}).map { try SourceFile(path: $0)}
        
        let objects = parse(sourceFiles: files)
                   
        let builder = TestsBuilder(projectName: projectName.value, models: objects.0, requests: objects.1)
        let text = builder.build()
        
        try text.write(toFile: pathToTest.value, atomically: false, encoding: String.Encoding.utf8)
    }
}
