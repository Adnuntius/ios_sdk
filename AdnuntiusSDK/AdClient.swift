//
//  AdClient.swift
//  AdnuntiusSDK
//
//  Created by Jason Pell on 23/5/2022.
//  Copyright © 2022 Adnuntius AS. All rights reserved.
//
//
// WARNING: This code should not be used for applications its only by adnuntius developers
//

import Foundation

public protocol AdClientHandler {
    func onComplete(_ baseUrl: String, _ html: String?)
    func onFailure(_ msg: String)
}

public class AdClientRequest: Codable {
    public let auId: String
    public let kv: [String: [String]]?
    public let c: [String]?
    
    public init(_ request: AdRequest) {
        self.auId = request.auId
        self.c = request.c
        self.kv = request.kv
    }
}

public class AdClientRequests: Codable {
    public var adUnits: [AdClientRequest]?
    
    public init(_ request: AdClientRequest) {
        self.adUnits = [request]
    }
}

public class AdClient {
    private let encoder = JSONEncoder()
    private var env: AdnuntiusEnvironment = AdnuntiusEnvironment.production
    private let logger: Logger = Logger()
    private var userAgent: String?
    
    public init() {
    }
    
    open func setUserAgent(_ userAgent: String) {
        self.userAgent = userAgent
    }
    
    open func setEnv(_ env: AdnuntiusEnvironment) {
        self.env = env
    }
    
    open func adRequest(_ request: AdRequest, _ handler: AdClientHandler) -> Void {
        let requests = AdClientRequests(AdClientRequest(request))
        let data = try! self.encoder.encode(requests)
        
        let baseUrl = AdUtils.getBaseUrl(env)
        let url = URL(string: baseUrl + "/i?format=json&sdk=ios:\(AdnuntiusSDK.sdk_version)")!
        var urlRequest = URLRequest(url: url)
        urlRequest.httpMethod = "POST"
        urlRequest.httpBody = data
        urlRequest.addValue("application/json", forHTTPHeaderField: "Content-Type")
        urlRequest.addValue("application/json", forHTTPHeaderField: "Accept")
        if (self.userAgent != nil) {
            urlRequest.addValue(self.userAgent!, forHTTPHeaderField: "User-Agent")
        }
        
        let task = URLSession.shared.dataTask(with: urlRequest) {(data, response, error) in
            guard let data = data, error == nil else {
                handler.onFailure("\(String(describing: error))")
                return
            }
            
            if let httpResponse = response as? HTTPURLResponse {
                if (httpResponse.statusCode != 200) {
                    handler.onFailure("Failed with \(httpResponse.statusCode): \(String(describing: response))")
                    return
                }
            }
            
            do {
                if let responseJSON = try JSONSerialization.jsonObject(with: data, options: []) as? [String: Any] {
                     if let adUnits = responseJSON["adUnits"] as? [[String: Any]] {
                         if let adUnit = adUnits.first {
                             if adUnit["matchedAdCount"] as? Int ?? 0 > 0, let html = adUnit["html"] as? String {
                                 handler.onComplete(baseUrl, "\(html)")
                                 return
                             } else {
                                 handler.onComplete(baseUrl, nil)
                                 return
                             }
                         }
                     }
                }
            } catch let error as NSError {
                handler.onFailure("\(String(describing: error))")
                return
            }
            
            handler.onFailure("Malformed response: missing an adUnits section")
            return
        }
        task.resume()
    }
}
