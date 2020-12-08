//
//  Copyright (c) 2020 Adnuntius AS.  All rights reserved.
//

import Foundation

open class Logger: NSObject {
    public static func debug(_ message: String) {
#if DEBUG
        print("DEBUG: \(message)")
#endif
    }
    
    public static func error(_ message: String) {
        print("ERROR: \(message)")
    }
}

