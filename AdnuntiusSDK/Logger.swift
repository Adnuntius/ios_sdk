//
//  Logger.swift
//  AdnuntiusSDK
//
//  Created by Jason Pell on 6/10/21.
//  Copyright © 2021 Adnuntius AS. All rights reserved.
//

import Foundation

public class Logger {
    // for debugging purposes can tag a view with an id
    open var id: String = ""
    open var debug: Bool = false
    open var verbose: Bool = false
    
    public init() {
    }
    
    @available(*, deprecated, message: "logger.debug")
    open func isDebugEnabled() -> Bool {
        return self.debug
    }
    
    open func verbose(_ message: String) {
        if self.verbose {
            print("\(id) VERBOSE    \(message)")
        }
    }
    
    open func debug(_ message: String) {
        if self.debug {
            print("\(id) DEBUG  \(message)")
        }
    }

    open func error(_ message: String) {
        print("ERROR: \(message)")
    }
}
