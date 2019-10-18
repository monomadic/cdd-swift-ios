import Willow
import Foundation


var log = Willow.Logger(logLevels: [.event], writers: [ConsoleWriter(modifiers: [ColorModifier()])])



private var isVerbosity = false

class ColorModifier: LogModifier {
    func modifyMessage(_ message: String, with logLevel: LogLevel) -> String {
        switch logLevel {
        case .error:
            return "[ERROR] \(message)".red
        case .info:
            return "[INFO] \(message)".yellow
        case .event:
            return "[OK] \(message)".green
        default:
            return "[OK] \(message)"
        }
    }
}

extension Logger {
    
    func enableFileOutput(path: String) {
        let writers = [FileWriter(filePath: path)] as [LogWriter]
//        [ConsoleWriter(modifiers: [ColorModifier()]), FileWriter(filePath: path)] as [LogWriter]

        log = Logger(logLevels: [log.logLevels], writers: writers)
    }
    
    func verbose() {
        setLogLevel(.all)
    }
    
    private func setLogLevel(_ level: LogLevel) {
        log = Logger(logLevels: [level], writers: log.writers)
    }
}



class FileWriter: LogWriter {
    private let path: String
    private let modifier = ColorModifier()
    
    init(filePath: String) {
        path = filePath
        try? "".write(toFile: path, atomically: true, encoding: .utf8)
    }
    
    func writeMessage(_ message: String, logLevel: LogLevel) {
        let mess = modifier.modifyMessage(message, with: logLevel)
        let text = try? String(contentsOf: URL(fileURLWithPath: path))
        try? ((text ?? "") + "\n" + mess).write(toFile: path, atomically: true, encoding: .utf8)
    }
    
    func writeMessage(_ message: LogMessage, logLevel: LogLevel) {
        
    }
}

class ErrWriter: LogWriter {
//    private let path: String
    private let modifier = ColorModifier()
    
    
    func writeMessage(_ message: String, logLevel: LogLevel) {
        let stderr = FileHandle.standardError
        
        // Write it
        if let data = message.data(using: .utf8) {
            stderr.write(data)
        }
        
    }
    
    func writeMessage(_ message: LogMessage, logLevel: LogLevel) {
        
    }
}

