//
//  Request.swift
//  AdnuntiusSDK
//
//
//  Copyright (c) 2019 Adnuntius AS.  All rights reserved.
//

import UIKit

class APIService: NSObject {
    public static func getAds(_ adConfig: AdConfig, completion: @escaping (_ ads: AdApi) -> Void?) {
        let url = URL(string: "https://delivery.adnuntius.com/i?format=json")
        
        let jsonData = try? JSONSerialization.data(withJSONObject: adConfig.getConfig())
        
        var request = URLRequest(url: url!)
        request.httpMethod = "POST"
        request.httpBody = jsonData
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        
        URLSession.shared.dataTask(with: request) {
            (data, response, error) in
            if error != nil {
                adConfig.setHasErrors(true)
                print(error!.localizedDescription)
            }
            
            guard let data = data else { return }
            //Implement JSON decoding and parsing
            do {
                //Decode retrived data with JSONDecoder and assign type of AdApi object
                let ads = try JSONDecoder().decode(AdApi.self, from: data)
                
                //Get back to the main queue
                DispatchQueue.main.async {
                    completion(ads)
                }
            } catch let jsonError {
                adConfig.setHasErrors(true)
                print("hasErrors")
                print(jsonError)
            }
        }.resume()
    }
}
