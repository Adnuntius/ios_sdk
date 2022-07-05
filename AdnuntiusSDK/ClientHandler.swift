//
//  ClientHandler.swift
//  AdnuntiusSDK
//
//  Created by Jason Pell on 7/7/2022.
//  Copyright © 2022 Adnuntius AS. All rights reserved.
//

import Foundation

public protocol ClientHandler {
    func onFailure(_ msg: String)
}
