//
//  AdUtils.swift
//  AdnuntiusSDK
//
//  Created by Jason Pell on 23/5/2022.
//  Copyright © 2022 Adnuntius AS. All rights reserved.
//

import Foundation

public class AdUtils {
    public static func getBaseUrl(_ env: AdnuntiusEnvironment) -> String {
        if (env == AdnuntiusEnvironment.production) {
            return "https://delivery.adnuntius.com"
        } else if (env == AdnuntiusEnvironment.localhost) {
            return "http://localhost:8078"
        } else {
            return "https://adserver.\(env).delivery.adnuntius.com"
        }
    }
}
