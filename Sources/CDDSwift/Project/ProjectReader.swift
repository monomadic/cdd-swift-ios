//
//  ProjectReader.swift
//	- Responsible for understanding project directory structure and writing reading files

import Foundation
import Yams
import SwiftSyntax

let MODELS_DIR = "/iOS/$0/Source/API/APIModels.swift"
let REQUESTS_DIR = "/iOS/$0/Source/API/APIRequests.swift"
let SETTINGS_FILE = "/iOS/$0/Source/API/APISettings.swift"

protocol ProjectSource {
    mutating func remove(name: String)
    mutating func insert(model:Model) throws
    mutating func update(model:Model)
    mutating func insert(request:Request) throws
    mutating func update(request:Request)
}

class ProjectReader {
    let projectPath: String
    var settingsFile: SourceFile
    var modelsFile: SourceFile
    var requestsFile: SourceFile
    
    init(projectPath: String) throws {
        self.projectPath = projectPath
        do {
            let projectName = findProjectName(at: self.projectPath + "/iOS")
            log.infoMessage("Found project: " + projectName)
            self.settingsFile = try SourceFile(path: self.projectPath + SETTINGS_FILE.replacingOccurrences(of: "$0", with: projectName))
            
            self.modelsFile = try SourceFile(path: self.projectPath + MODELS_DIR.replacingOccurrences(of: "$0", with: projectName))
            self.requestsFile = try SourceFile(path: self.projectPath + REQUESTS_DIR.replacingOccurrences(of: "$0", with: projectName))
        }
    }
    
    func read() throws -> Project {
        return try generateProject()
    }
    
    func generateProject() throws -> Project {
        let projectInfo = try parseProjectInfo(self.settingsFile)
        let result = parse(sourceFiles: [modelsFile,requestsFile])
        
        return Project(info: projectInfo, models: result.0, requests: result.1)
    }

	/// attempt to generate unit tests for generated requests
	func generateTests() throws {
		let swiftProject = try self.generateProject()
		let projectName = guessProjectName()
		let unitTests = TestsBuilder(project: swiftProject, projectName: projectName).build()

		let testFile = URL(string: self.projectPath + "/iOS/\(projectName)Tests/ApiResourceTests.swift")!

		switch writeStringToFile(file: testFile, contents: unitTests) {
		case .success(_):
			log.eventMessage("Wrote tests to \(testFile.path)")
		case .failure(let error):
			exitWithError(error)
		}
	}
    
    func write(project: Project) throws {
        // generate a Project from swift files
        let swiftProject = try self.generateProject()
        
        log.eventMessage("Generated project from swift project with \(swiftProject.models.count) models, \(swiftProject.requests.count) routes.".green)
        log.infoMessage("- source models: \(swiftProject.models.map({$0.name}))")
        log.infoMessage("- source requests: \(swiftProject.requests.map({$0.name}))")
        
        self.settingsFile.update(projectInfo: project.info)
        
        let modelsChanges1 = project.models.compare(to: swiftProject.models)
        for change in modelsChanges1 {
            var sourceFile = modelsFile
            switch change {
            case .deletion(let model):
                sourceFile.remove(name:model.name)
            case .insertion(let model):
                try sourceFile.insert(model:model)
            case .same(let model):
               sourceFile.update(model:model)
            }
            modelsFile = sourceFile
        }
        
        let requestsChanges1 = project.requests.compare(to: swiftProject.requests)
        for change in requestsChanges1 {
            var sourceFile = requestsFile
            
            switch change {
            case .deletion(let request):
                sourceFile.remove(name: request.name)
            case .insertion(let request):
                try sourceFile.insert(request: request)
            case .same(let request):
                sourceFile.update(request: request)
            }
            requestsFile = sourceFile
        }
        
        try write().get()
    }
    
    func write() -> Result<(), Swift.Error> {
        do {
            // write models
			for sourceFile in [modelsFile,requestsFile, settingsFile] {
				logFileWrite(
					result: writeStringToFile(file: sourceFile.url, contents: "\(sourceFile.syntax)"),
					filePath: sourceFile.url.path)
			}
        } catch let err {
            return .failure(err)
        }

		return .success(())
    }

	func guessProjectName() -> String {
		if case let .success(files) = readDirectory(self.projectPath + "/iOS") {
			for file in files {
				if file.pathExtension == "xcodeproj" {
					var file = file
					file.deletePathExtension()
					return file.lastPathComponent
				}
			}
		}

		return "MyProject"
	}
}

func logFileWrite(result: Result<(), Swift.Error>, filePath: String) {
	switch result {
	case .success(_):
		log.eventMessage("WROTE \(filePath)")
	case .failure(let err):
		log.errorMessage("ERROR WRITING \(filePath): \(err)")
	}
}
