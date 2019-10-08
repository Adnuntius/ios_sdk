//
//  Logger.swift
//  AdnuntiusSDK
//
//  Created by Adnuntius Australia on 10/10/19.
//  Copyright © 2019 Adnuntius AS. All rights reserved.
//

import Foundation

open class Logger: NSObject {
    public static func debug(_ message: String) {
        print("DEBUG: " + message)
    }
}
