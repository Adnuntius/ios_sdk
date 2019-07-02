//
//  AdModel.swift
//  AdnuntiusSDK
//
//
//  Copyright (c) 2019 Adnuntius AS.  All rights reserved.
//

import UIKit

struct AdUnit: Codable {
    let auId: String
    let targetId: String
    let html: String
    let matchedAdCount: Int
    let ads: [Ad]
}
