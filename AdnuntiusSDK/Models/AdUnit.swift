//
//  AdModel.swift
//  AdnuntiusSDK
//
//  Created by Mateusz Grzywa on 27/08/2018.
//  Copyright © 2018 Mateusz Grzywa. All rights reserved.
//

import UIKit

struct AdUnit: Codable {
    let auId: String
    let targetId: String
    let html: String
    let matchedAdCount: Int
    let ads: [Ad]
}
