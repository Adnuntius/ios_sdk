//
//  Logger.swift
//  AdnuntiusSDK
//
//  Created by Jason Pell on 6/10/21.
//  Copyright © 2021 Adnuntius AS. All rights reserved.
//

import Foundation

public class Logger {
    private var debug: Bool = false
    
    public init() {
        
    }
    
    open func enableDebug(_ debug: Bool) {
        self.debug = debug
    }
    
    open func debug(_ message: String) {
        if self.debug {
            print("DEBUG: \(message)")
        }
    }
    
    open func isDebugEnabled() -> Bool {
        return self.debug
    }
    
    open func error(_ message: String) {
        print("ERROR: \(message)")
    }
}
