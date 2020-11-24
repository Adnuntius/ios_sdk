//
//  Copyright (c) 2020 Adnuntius AS.  All rights reserved.
//


import WebKit

struct AdUnit: Codable {
    let auId: String
    let targetId: String
    let html: String
    let matchedAdCount: Int
    let ads: [Ad]
}
