// Copyright (c) 2018 Token Browser, Inc
//
// This program is free software: you can redistribute it and/or modify
// it under the terms of the GNU General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.
//
// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
// GNU General Public License for more details.
//
// You should have received a copy of the GNU General Public License
// along with this program.  If not, see <http://www.gnu.org/licenses/>.

import Foundation

/*
 This file facilitates log statements which will only print when in debug mode.
 
 By default, DLog will log when -D DEBUG is in the "Other Swift Flags" and do nothing when it is not. You can temporarily override this behavior by just forcing `shouldDebugLog` to return whatever you want, though it is reco
 
 ALog will always log with details about the file, function, and line of the caller.
 
 Note: The message is the only required variable for any of these.
 */

/// Determines if debug logs should fire.
/// NOTE: This can be overridden temporarily on a local basis, but it's not recommended that said changes be checked in
///
/// - Returns: True if debug logs should fire, false if not.
private func shouldDebugLog() -> Bool {
    #if DEBUG
        return true
    #else
        return false
    #endif
}

/**
 Prints a detailed log statement, but only when in debug mode.
 
 - parameter message:  The message you wish to log out.
 */
func DLog(_ message: @autoclosure () -> String, filePath: StaticString = #file, function: StaticString = #function, line: UInt = #line) {
    guard shouldDebugLog() else { return }
    
    detailedLog(message(), String(describing: filePath), String(describing: function), line)
}

/**
 Always prints a detailed log statement.
 
 - parameter message:  The message you wish to log out.
 */
func ALog(_ message: @autoclosure () -> String, filePath: StaticString = #file, function: StaticString = #function, line: UInt = #line) {
    detailedLog(message(), String(describing: filePath), String(describing: function), line)
}
    
/**
 Centralizes the detailed message formatting into a single method.
 
 - parameter message:  The message to print
 - parameter filePath: The file path of the original caller.
 - parameter function: The function of the original caller
 - parameter line:     the line number of the original caller.
 */
private func detailedLog(_ message: String, _ filePath: String, _ function: String, _ line: UInt) {
    let fileName = (filePath as NSString).lastPathComponent
    print("[\(fileName):\(line)] \(function) - \(message)")
}

// MARK: - Obj-C Compatibility

class OCDLog: NSObject {
    
    override init() {
        fatalError("Don't actually try to make objects with this!")
    }
    
    /**
     Allows access to the debug-only logging feature from Objective-C.
     
     Note that all items must be passed in, but should be able to be passed in with macros like so:
     [OCDLog dlog:@"The message to print"
         filePath:__FILE__
         function:__FUNCTION__
             line:__LINE__];
     */
    @objc static func dlog(_ message: String, filePath: UnsafePointer<CChar>, function: UnsafePointer<CChar>, line: UInt) {
        guard shouldDebugLog() else { return }
        
        detailedLog(message, String(cString: filePath), String(cString: function), line)
    }
    
    /**
     Allows access to the always-logging feature from Objective-C.
     
     Note that all items must be passed in, but should be able to be passed in with macros like so:
     [OCDLog alog:@"The message to print"
         filePath:__FILE__
         function:__FUNCTION__
             line:__LINE__];
     */
    @objc static func alog(_ message: String, filePath: UnsafePointer<CChar>, function: UnsafePointer<CChar>, line: UInt) {
        detailedLog(message, String(cString: filePath), String(cString: function), line)
    }
}
