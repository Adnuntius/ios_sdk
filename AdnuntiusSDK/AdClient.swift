//
//  AdClient.swift
//  AdnuntiusSDK
//
//  Created by Jason Pell on 23/5/2022.
//  Copyright © 2022 Adnuntius AS. All rights reserved.
//
//
// WARNING: This code is not supported for production applications
//          Its for internal use only
//

import Foundation

public protocol AdClientHandler: ClientHandler {
    func onComplete(_ baseUrl: String, _ html: String?)
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

private class AdClientHttpHandler: HttpClientHandler {
    private let baseUrl: String
    private let handler: AdClientHandler
    
    public init(_ baseUrl: String, _ handler: AdClientHandler) {
        self.baseUrl = baseUrl
        self.handler = handler
    }

    func onComplete(_ response: HttpClientResponse) {
        if (response.code == 200) {
            if let adUnits = response.data!["adUnits"] as? [[String: Any]] {
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
            handler.onFailure("Malformed response: missing an adUnits section")
            return
        } else if (response.data != nil) {
            handler.onFailure("\(response.code): \(response.data!)")
        } else {
            handler.onFailure("\(response.code): \(response.msg!)")
        }
    }
}

public class AdClient {
    private let encoder = JSONEncoder()
    private var env: AdnuntiusEnvironment = AdnuntiusEnvironment.production
    private let logger: Logger = Logger()
    private let httpClient: HttpClient = HttpClient()
    
    public init() {
    }
    
    open func setUserAgent(_ userAgent: String) {
        self.httpClient.userAgent(userAgent)
    }
    
    open func setEnv(_ env: AdnuntiusEnvironment) {
        self.env = env
    }
    
    open func adRequest(_ request: AdRequest, _ handler: AdClientHandler) -> Void {
        let requests = AdClientRequests(AdClientRequest(request))
        let data = try! self.encoder.encode(requests)
        
        let baseUrl = AdUtils.getBaseUrl(env)
        let url = baseUrl + "/i?format=json&sdk=ios:\(AdnuntiusSDK.sdk_version)"
        self.httpClient.jsonPost(url, data, AdClientHttpHandler(baseUrl, handler))
    }
}
