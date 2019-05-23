//
//  Request.swift
//  AdnuntiusSDK
//
//  Created by Mateusz Grzywa on 27/08/2018.
//  Copyright © 2018 Mateusz Grzywa. All rights reserved.
//

import UIKit
///https://delivery.adnuntius.com/i?tzo=-120&format=json&usi=jg28mcwbihwdny9e&siteId=1131763067966473843&auId=000000000002c3eb&c=sports
class APIService: NSObject {
    public static func getAds(completion: @escaping (_ ads: AdApi) -> Void?) {
        let url = URL(string: "https://delivery.adnuntius.com/i?format=json")
        
        
        let jsonData = try? JSONSerialization.data(withJSONObject: AdnuntiusSDK.config)
        
        var request = URLRequest(url: url!)
        request.httpMethod = "POST"
        request.httpBody = jsonData
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        URLSession.shared.dataTask(with: request) { (data, response, error) in
            if error != nil {
                AdnuntiusSDK.hasErrors = true
                print(error!.localizedDescription)
            }
            
            guard let data = data else { return }
            //Implement JSON decoding and parsing
            do {
                //Decode retrived data with JSONDecoder and assing type of AdApi object
                let ads = try JSONDecoder().decode(AdApi.self, from: data)
                
                //Get back to the main queue
                DispatchQueue.main.async {
                    completion(ads)
                }
                
            } catch let jsonError {
                AdnuntiusSDK.hasErrors = true
                print("hasErrors")
                print(jsonError)
            }
            
            
            }.resume()
    }
}
