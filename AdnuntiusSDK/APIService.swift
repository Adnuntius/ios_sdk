//
//  Copyright (c) 2020 Adnuntius AS.  All rights reserved.
//

import WebKit

public struct AdnuntiusHttpError: Error {
    let code: Int
    let message: String
}

class APIService: NSObject {
    public static func getAds(_ config: [String: Any] = [:], completion: @escaping (_ ads: AdApi?, _ error: Error?) -> Void?) {
        let url = URL(string: "https://delivery.adnuntius.com/i?format=json&sdk=ios:" + AdnuntiusSDK.sdk_version)
        
        let jsonData = try? JSONSerialization.data(withJSONObject: config)
        
        let theJSONText = String(data: jsonData!, encoding: .utf8)
        Logger.debug("Json Request: " + theJSONText!)

        var request = URLRequest(url: url!)
        request.httpMethod = "POST"
        request.httpBody = jsonData
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        
        URLSession.shared.dataTask(with: request) {
            (data, response, error) in
            if error != nil {
                DispatchQueue.main.async {
                    completion(nil, error)
                }
            }
            
            guard let data = data else { return }
            do {
                let hresponse = response as! HTTPURLResponse
                if hresponse.statusCode != 200 {
                    let theData = String(data: data, encoding: .utf8)
                    DispatchQueue.main.async {
                        completion(nil, AdnuntiusHttpError(code: hresponse.statusCode, message: theData!))
                    }
                } else {
                    let ads = try JSONDecoder().decode(AdApi.self, from: data)

                    DispatchQueue.main.async {
                        completion(ads, nil)
                    }
                }
            } catch let error {
                DispatchQueue.main.async {
                    completion(nil, error)
                }
            }
        }.resume()
    }
}
