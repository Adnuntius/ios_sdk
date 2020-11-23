//
//  Copyright (c) 2020 Adnuntius AS.  All rights reserved.
//

import Foundation

open class Logger: NSObject {
    public static func debug(_ message: String) {
        print("DEBUG: " + message)
    }
}
