//
//  Utils.swift
//  CYaml
//
//  Created by Rob Saunders on 7/10/19.
//

import Foundation
private let templateName = "cddTemplate"

func writeStringToFile(file: URL, contents: String) -> Result<(), Swift.Error> {
	if config.dryRun == true {
		return .success(())
	}

	do {
		try contents.write(toFile: file.path, atomically: false, encoding: String.Encoding.utf8)
		return .success(())
	}
	catch let err { return .failure(err) }
}

/// read files in a directory to [URL]
func readDirectory(_ path: String) -> Result<[URL], Swift.Error> {
	do {
		let files = try FileManager.default.contentsOfDirectory(at: URL.init(fileURLWithPath: path), includingPropertiesForKeys: [], options:  [.skipsHiddenFiles, .skipsSubdirectoryDescendants])

		return .success(files)
	}
	catch let error {
		return .failure(error)
	}
}

/// read file contents to string
func readFile(_ url: URL) -> Result<String, Swift.Error> {
	do {
		let file = try String(contentsOf: url, encoding: .utf8)
		return .success(file)
	}
	catch let error {
		return .failure(error)
	}
}

func findProjectName(at projectPath:String) -> String {
    switch readDirectory(projectPath) {
    case .success(let files):
        for filename in files {
            if filename.lastPathComponent.contains(".xcodeproj"), let name = filename.lastPathComponent.components(separatedBy: ".").first {
                return name
            }
        }
    case .failure(_):
        exitWithError("Can't find swift project at \(projectPath)")
    }
    return ""
}

func copyDirectory(from sourceDir: String, to targetDir: String, projectName: String) {
	let fileManager = FileManager.default

	if !fileExists(file: targetDir) {
		do {
			try fileManager.createDirectory(atPath: targetDir, withIntermediateDirectories: true, attributes: nil)
		} catch {
			exitWithError("whoops")
		}
	}

	switch readDirectory(sourceDir) {
	case .success(let files):
		for filename in files {
			let sourceFilePath = filename.relativePath
            let newName = filename.lastPathComponent.replacingOccurrences(of: templateName, with: projectName)
			let targetFilePath = targetDir + "/" + newName

			if fileIsDir(sourceFilePath) {
				copyDirectory(from: sourceFilePath, to: targetFilePath, projectName: projectName)
			} else {
				copyFile(from: sourceFilePath, to: targetFilePath, projectName: projectName)
			}
		}
	case .failure(_):
		exitWithError("Error copying \(sourceDir) to \(targetDir)")
	}
}

func copyFile(from source: String, to target: String, projectName: String) {
	let fileManager = FileManager.default

	do {
        let targetURL = URL(fileURLWithPath: target)
		try fileManager.copyItem(
			at: URL(fileURLWithPath: source),
			to: targetURL)
        
        if let content = try? String(contentsOf: targetURL) {
            let newContent = content.replacingOccurrences(of: templateName, with: projectName)
            try newContent.write(to: targetURL, atomically: true, encoding: .utf8)
        }
	} catch CocoaError.fileWriteFileExists {
		log.warnMessage("File exists, overwriting \(target)")

		try! fileManager.removeItem(atPath: target)
		copyFile(from: source, to: target, projectName: projectName)
	} catch {
		log.errorMessage("\(error)")
		exitWithError("Error copying \(source) to \(target)")
	}
}

func fileIsDir(_ sourceFilePath: String) -> Bool {
	let fileManager = FileManager.default

	do {
		let attr = try fileManager.attributesOfItem(atPath: sourceFilePath)

		if let fileType = attr[FileAttributeKey.type] as? FileAttributeType {
			return fileType == FileAttributeType.typeDirectory.self
		}
	} catch {
		return false // throw?
	}

	return false // throw?
}

/// trim unnecessary characters from a string
func trim(_ string: String) -> String {
	return string
		.trimmingCharacters(in: .whitespacesAndNewlines)
		.replacingOccurrences(of: "\"", with: "")
}

func fileLastModifiedDate(file: String) -> Date? {
	do {
		let attributes = try FileManager.default.attributesOfItem(atPath: file)
		return attributes[FileAttributeKey.modificationDate] as? Date
	}
	catch let error as NSError {
		log.errorMessage("Ooops! Something went wrong: \(error)")
		return nil
	}
}

func fileLastModifiedDate(url: URL) throws -> Date {
	do {
		let attributes = try FileManager.default.attributesOfItem(atPath: url.path)
		return attributes[FileAttributeKey.modificationDate] as! Date
	}
}

extension String {
    var trimmedWhiteSpaces: String {
        return trimmingCharacters(in: .whitespacesAndNewlines)
    }
}

func fileExists(file: String) -> Bool {
	return FileManager.default.fileExists(atPath: file)
}
