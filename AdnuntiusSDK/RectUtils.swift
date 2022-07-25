//
//  RectUtils.swift
//  AdnuntiusSDK
//
//  Created by Jason Pell on 27/7/2022.
//  Copyright © 2022 Adnuntius AS. All rights reserved.
//

import Foundation
import UIKit

public class RectUtils {
    public static func percentageContains(_ container: CGRect, _ childView: CGRect) -> Int {
        let intersection:CGRect = container.intersection(childView)
        if (intersection.height > 0 && intersection.width > 0) {
            let viewArea = childView.width * childView.height
            let intersectArea = intersection.width * intersection.height
            let percentage = Int((intersectArea / (viewArea / 100)).rounded())
            // a single pixel still must be valid, so just force to 1 percent
            return percentage > 0 ? percentage : 1
        }
        return 0
    }
}
