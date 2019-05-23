//
//  AdModel.swift
//  AdnuntiusSDK
//
//  Created by Mateusz Grzywa on 27/08/2018.
//  Copyright © 2018 Mateusz Grzywa. All rights reserved.
//

import UIKit

struct Ad: Codable {
    let destinationUrlEsc: String
    let assets: Asset
    let clickUrl: String
    let urls: Dictionary<String, String>
    let urlsEsc: Dictionary<String, String>
    let destinationUrls: Dictionary<String, String>
    let impressionTrackingUrls: [String]
    let impressionTrackingUrlsEsc: [String]
    let adId: String
    let selectedColumn: String
    let selectedColumnPosition: String
    let renderedPixel: String
    let renderedPixelEsc: String
    let visibleUrl: String
    let visibleUrlEsc: String
    let viewUrl: String
    let viewUrlEsc: String
    let rt: String
    let creativeWidth: String
    let creativeHeight: String
    let creativeId: String
    let lineItemId: String
    let layoutId: String
    let layoutName: String
    let layoutExternalReference: String
    let renderTemplate: String
    let html: String
}
