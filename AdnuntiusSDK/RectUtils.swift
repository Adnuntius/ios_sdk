//
//  RectUtils.swift
//  AdnuntiusSDK
//
//  Created by Jason Pell on 27/7/2022.
//  Copyright © 2022 Adnuntius AS. All rights reserved.
//

import Foundation
import UIKit

private extension Double {
    func toInt() -> Int {
        // this is a rubbish value, Im not sure if it should be zero or something else,
        // im going with zero for now
        if self >= Double(Int.min) && self < Double(Int.max) {
            return Int(self)
        } else {
            return Int(0)
        }
    }
}

public class RectUtils {
    // https://stackoverflow.com/a/40544010
    public static func percentageContains(_ container: CGRect, _ childView: CGRect) -> Int {
        let intersection:CGRect = container.intersection(childView)
        if (intersection.height > 0 && intersection.width > 0) {
            let viewArea = childView.width * childView.height
            let intersectArea = intersection.width * intersection.height
            let percentage = ((intersectArea / (viewArea / 100)).rounded()).toInt()
            // a single pixel still must be valid, so just force to 1 percent
            return percentage > 0 ? percentage : 1
        }
        return 0
    }
}
