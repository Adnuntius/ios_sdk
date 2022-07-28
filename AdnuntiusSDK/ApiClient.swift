//
//  Copyright © 2022 Adnuntius AS. All rights reserved.
//

import Foundation

public protocol ApiClientHandler {
    func onSuccess(_ url: String, _ json: [String : Any])
    func onFailure(_ url: String, _ msg: String)
    func onAuthFailure()
}

public struct BearerToken {
    public var accessToken: String?
    public var expiresIn: String?
    public var refreshToken: String?
}

public class Authenticate: Codable {
    public var grant_type: String = "password"
    public var scope: String = "ng_api"
    public var username: String
    public var password: String
    
    public init(_ username: String, _ password: String) {
        self.username = username
        self.password = password
    }
}

private class ApiClientHttpRequest: HttpClientHandler {
    private let httpClient: HttpClient = HttpClient()
    private let encoder = JSONEncoder()
    private var env: AdnuntiusEnvironment = AdnuntiusEnvironment.production
    private var bearerToken = BearerToken()
    private var authenticate: Authenticate?
    private var handler: ApiClientHandler?
    private var url: String?
    private var data: Data?
    
    public init() {
    }
    
    open func setEnv(_ env: AdnuntiusEnvironment) {
        self.env = env
    }
    
    open func authenticate(_ username: String, _ password: String) -> Void {
        self.authenticate = Authenticate(username, password)
    }

    func onComplete(_ response: HttpClientResponse) {
        if (response.code == 200) {
            handler!.onSuccess(response.url, response.data!)
        } else if (response.data != nil) {
            handler!.onFailure(response.url, "\(response.code): \(response.data!)")
        } else {
            handler!.onFailure(response.url, "\(response.code): \(response.msg!)")
        }
    }
    
    open func perform(_ url: String, _ data: Data?, _ handler: ApiClientHandler) {
        self.url = url
        self.data = data
        self.handler = handler
        
        if (bearerToken.accessToken == nil) {
            let authData = try! self.encoder.encode(authenticate)
            let clientResponse = self.httpClient.syncJsonPost(getAuthUrl(), authData)
            if clientResponse.code == 200 {
                self.bearerToken.accessToken = clientResponse.data!["access_token"] as? String
                self.bearerToken.expiresIn = clientResponse.data!["expires_in"] as? String
                self.bearerToken.refreshToken = clientResponse.data!["refresh_token"] as? String
                self.httpClient.accessToken(self.bearerToken.accessToken!)
            } else {
                handler.onAuthFailure()
                return
            }
        }
        
        if self.data != nil {
            self.httpClient.jsonPost(self.url!, self.data!, self)
        } else {
            self.httpClient.jsonGet(self.url!, self)
        }
    }
    
    private func getAuthUrl() -> String {
        if (self.env == AdnuntiusEnvironment.production) {
            return "https://api.adnuntius.com/api/authenticate";
        } else {
            return "https://api.\(env).adnuntius.com/api/authenticate";
        }
    }
}

public class ApiClient {
    private var env: AdnuntiusEnvironment = AdnuntiusEnvironment.production
    private var requester = ApiClientHttpRequest()
    private let logger = Logger()
    
    public init() {
    }
    
    open func setEnv(_ env: AdnuntiusEnvironment) {
        self.env = env
        requester.setEnv(env)
    }
    
    open func authenticate(_ username: String, _ password: String) -> Void {
        requester.authenticate(username, password)
    }
    
    open func creative(_ creativeId: String, _ networkId: String, _ handler: ApiClientHandler) -> Void {
        let url = getApiUrl("creatives", creativeId, networkId)
        requester.perform(url, nil, handler)
    }
    
    private func getApiUrl(_ resource : String, _ id: String, _ networkId: String) -> String {
        if (self.env == AdnuntiusEnvironment.production) {
            return "https://api.adnuntius.com/api/v1/\(resource)/\(id)?context=\(networkId)";
        } else {
            return "https://api.\(env).adnuntius.com/api/v1/\(resource)/\(id)?context=\(networkId)";
        }
    }
}
