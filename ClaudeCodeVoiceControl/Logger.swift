import Foundation

class Logger {
    static let shared = Logger()
    private let logFile: URL
    private let dateFormatter: DateFormatter
    
    private init() {
        // Create logs in Documents directory
        let documentsPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
        logFile = documentsPath.appendingPathComponent("ClaudeCodeVoiceControl.log")
        
        dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd HH:mm:ss.SSS"
        
        // Create file if it doesn't exist
        if !FileManager.default.fileExists(atPath: logFile.path) {
            FileManager.default.createFile(atPath: logFile.path, contents: nil)
        }
    }
    
    func log(_ message: String, file: String = #file, function: String = #function, line: Int = #line) {
        let timestamp = dateFormatter.string(from: Date())
        let fileName = URL(fileURLWithPath: file).lastPathComponent
        let logMessage = "\(timestamp) [\(fileName):\(line)] \(function): \(message)\n"
        
        // Print to console
        print(logMessage)
        
        // Write to file
        if let data = logMessage.data(using: .utf8) {
            if let fileHandle = try? FileHandle(forWritingTo: logFile) {
                fileHandle.seekToEndOfFile()
                fileHandle.write(data)
                fileHandle.closeFile()
            }
        }
    }
    
    func getLogPath() -> String {
        return logFile.path
    }
    
    func readLogs() -> String {
        return (try? String(contentsOf: logFile)) ?? "No logs found"
    }
    
    func clearLogs() {
        try? "".write(to: logFile, atomically: true, encoding: .utf8)
    }
}