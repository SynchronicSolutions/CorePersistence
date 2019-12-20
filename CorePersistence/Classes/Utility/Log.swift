//
//  Log.swift
//  CorePersistence
//
//  Created by Milos Babic on 12/16/19.
//

import Foundation

public struct Log {
    enum Level: String {
        case verbose = "🔵🔵🔵"
        case warning = "🟠🟠🟠"
        case error = "🔴🔴🔴"
    }
    
    public static func verbose(_ message: String) {
        printMessage(level: .verbose, message: message)
    }
    
    public static func warning(_ message: String) {
        printMessage(level: .warning, message: message)
    }
    
    public static func error(_ message: String) {
        printMessage(level: .error, message: message)
    }
    
    public static func error(_ error: Error) {
        printMessage(level: .error, message: error.localizedDescription)
    }
    
    static func printMessage(level: Level, message: String) {
        let levelIcons: String = level.rawValue
        print("\(levelIcons) [CorePersistence] \(message) \(levelIcons)\n")
    }
}
