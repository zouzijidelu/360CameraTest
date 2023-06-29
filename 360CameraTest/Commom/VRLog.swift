//
//  FirstViewController.swift
//  VRCapture_iOS
//
//  Created by wzb on 2023/5/4.
//


import Foundation
import UIKit
import CocoaLumberjack

private let maxFileSize: UInt64 = 10 * 1024 * 1024

/// Print log in console only when debug.
///
/// - Parameters:
///   - message: Message will be printed.
///   - file: The invoker file.
///   - method: The method this function was invoked by.
///   - line: Line number in file of this method was invoked.
public func printLog<T>(_ message: T, file: String = #file, method: String = #function, line: Int = #line) {
//    #if DEBUG
        let formattedMessage = defaultDateFormatter.string(from: Date())
    let mes = "\(formattedMessage) \((file as NSString).lastPathComponent)[\(line)], \(method): \(message)"
        print(mes)
    let ddmes = "\((file as NSString).lastPathComponent)[\(line)], \(method): \(message)"
        DDLogInfo(mes)
//    #endif
}

/// Print log in console only when debug.
///
/// - Parameters:
///   - message: Message will be printed.
///   - file: The invoker file.
///   - method: The method this function was invoked by.
///   - line: Line number in file of this method was invoked.
//public func printLog<T>(_ message: T, file: String = #file, method: String = #function) {
//    #if DEBUG
//        let methodArr = method.components(separatedBy: "(")
//        print("---------------- \(methodArr.first ?? "") -------------------------")
//        print("\((file as NSString).lastPathComponent):  \(message)")
//    #endif
//}

public func debugBriefPrint<T>(_ message: T, file: String = #file, method: String = #function) {
    #if DEBUG
        print("\((file as NSString).lastPathComponent):  \(message)")
    #endif
}

/// Print log in console even in released version.
///
/// - Parameters:
///   - message: Message will be printed.
///   - file: The invoker file.
///   - method: The method this function was invoked by.
///   - line: Line number in file of this method was invoked.
public func releasePrintLog<T>(_ message: T, file: String = #file, method: String = #function, line: Int = #line) {
    print("\((file as NSString).lastPathComponent)[\(line)], \(method): \(message)")
    if shouldWriteToFile {
        write("\((file as NSString).lastPathComponent)[\(line)], \(method): \(message)")
    }
}

private func redirectNSLogToFile() {
    if writeToFileURL == nil {
        return
    }
    
    if isatty(STDOUT_FILENO) == 1 {
        return
    }
    if UIDevice.current.model.hasSuffix("Simulator") {
        return
    }
    freopen(writeToFileURL?.path.cString(using: .ascii), "a+", stdout)
    freopen(writeToFileURL?.path.cString(using: .ascii), "a+", stderr)
}

/// Save log to file.
///
/// - Parameter file: Destination file
public func writeLog(toFile file: Any?) {
    if file is String {
        writeToFileURL = URL(fileURLWithPath: file as! String)
        shouldWriteToFile = true
    } else if let writeToFile = file as? URL, writeToFile.isFileURL {
        writeToFileURL = writeToFile
        shouldWriteToFile = true
    } else {
        writeToFileURL = nil
        shouldWriteToFile = false
    }
    if shouldWriteToFile {
        redirectNSLogToFile()
    }
}

private var shouldWriteToFile: Bool = false

private var defaultDateFormatter: DateFormatter = {
    let formatter = DateFormatter()
    formatter.locale = NSLocale.current
    formatter.dateFormat = "yyyy-MM-dd HH:mm:ss.SSS"
    return formatter
}()

private func write(_ message: String) {
    logQueue.async {
        do {
            let formattedMessage = "\(defaultDateFormatter.string(from: Date())) \(message) \n"
            if let encodedData = formattedMessage.data(using: .utf8) {
                logFileHandle?.write(encodedData)
            }
            currentLogFileSize += UInt64(formattedMessage.count)
            if currentLogFileSize >= maxFileSize {
                closeFile()
                if writeToFileURL != nil {
                    try FileManager.default.removeItem(at: writeToFileURL!)
                    currentLogFileSize = 0
                }
                openFile()
            }
        } catch {
            print("Remove file failed!!!!")
        }
    }
}

private var currentLogFileSize: UInt64 = 0

private var logQueue: DispatchQueue = {
    let queue = DispatchQueue(label: "com.italktv.dftv.logQueue")
    return queue
}()

/// FileURL of the file to log to
private var writeToFileURL: URL? = nil {
    didSet {
        if writeToFileURL != nil {
            openFile()
        } else {
            closeFile()
        }
    }
}

private var logFileHandle: FileHandle?

private func openFile() {
    if logFileHandle != nil {
        closeFile()
    }
    guard let writeToFileURL = writeToFileURL else { return }
    
    let fileManager: FileManager = FileManager.default
    let fileExists: Bool = fileManager.fileExists(atPath: writeToFileURL.path)
    if !fileExists {
        fileManager.createFile(atPath: writeToFileURL.path, contents: nil)
    }
    
    // 默认 Append
    do {
        logFileHandle = try FileHandle(forWritingTo: writeToFileURL)
        if fileExists {
            logFileHandle?.seekToEndOfFile()
            let appenMarker: String = "-- ** ** ** ** ** ** --"
            if let encodedData = "\n\n\(appenMarker)\n\n".data(using: .utf8) {
                logFileHandle?.write(encodedData)
            }
            let fileAttributes: [FileAttributeKey: Any] =
                try FileManager.default.attributesOfItem(atPath: writeToFileURL.path)
            currentLogFileSize = fileAttributes[.size] as? UInt64 ?? 0
        }
    } catch {
        logFileHandle = nil
        return
    }
}

private func closeFile() {
    logFileHandle?.synchronizeFile()
    logFileHandle?.closeFile()
    logFileHandle = nil
}





