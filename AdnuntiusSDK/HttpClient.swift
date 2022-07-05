//
//  HttpClient.swift
//  AdnuntiusSDK
//
//  Created by Jason Pell on 7/7/2022.
//  Copyright © 2022 Adnuntius AS. All rights reserved.
//

import Foundation

public struct HttpClientResponse {
    public let url: String
    public var code: Int = 0
    public var msg: String?
    public var data: [String:Any]?
    
    public init(_ url: String) {
        self.url = url
    }
}

public protocol HttpClientHandler {
    func onComplete(_ response: HttpClientResponse)
}

// https://stackoverflow.com/questions/26784315/can-i-somehow-do-a-synchronous-http-request-via-nsurlsession-in-swift
extension URLSession {
    func synchronousDataTask(urlrequest: URLRequest) -> (data: Data?, response: URLResponse?, error: Error?) {
        var data: Data?
        var response: URLResponse?
        var error: Error?

        let semaphore = DispatchSemaphore(value: 0)
        let dataTask = self.dataTask(with: urlrequest) {
            data = $0
            response = $1
            error = $2

            semaphore.signal()
        }
        dataTask.resume()

        _ = semaphore.wait(timeout: .distantFuture)

        return (data, response, error)
    }
}

public class HttpClient {
    private var userAgent: String?
    private var accessToken: String?
    
    open func accessToken(_ accessToken: String) {
        self.accessToken = accessToken
    }
    
    open func userAgent(_ userAgent: String) {
        self.userAgent = userAgent
    }
    
    public func jsonGet(_ url: String, _ handler: HttpClientHandler) -> Void {
        jsonRequest(url, nil, handler)
    }
    
    public func jsonPost(_ url: String, _ request: Data, _ handler: HttpClientHandler) -> Void {
        jsonRequest(url, request, handler)
    }
    
    public func syncJsonPost(_ url: String, _ request: Data) -> HttpClientResponse {
        let urlRequest = getJsonRequest(url, request)
        let (data, response, error) = URLSession.shared.synchronousDataTask(urlrequest: urlRequest)
        return self.getHttpClientResponse(url, data, response, error)
    }
    
    private func getJsonRequest(_ url: String, _ request: Data?) -> URLRequest {
        var urlRequest: URLRequest = URLRequest(url: URL(string: url)!)
        if request != nil {
            urlRequest.httpMethod = "POST"
            urlRequest.httpBody = request
            urlRequest.addValue("application/json", forHTTPHeaderField: "Content-Type")
        } else {
            urlRequest.httpMethod = "GET"
        }
        
        urlRequest.addValue("application/json", forHTTPHeaderField: "Accept")
        if (self.userAgent != nil) {
            urlRequest.addValue(self.userAgent!, forHTTPHeaderField: "User-Agent")
        }
        
        if (self.accessToken != nil) {
            urlRequest.addValue("Bearer \(self.accessToken!)", forHTTPHeaderField: "Authorization")
        }
        return urlRequest
    }
    
    private func jsonRequest(_ url: String, _ request: Data?, _ handler: HttpClientHandler) -> Void {
        let urlRequest = getJsonRequest(url, request)
        let task = URLSession.shared.dataTask(with: urlRequest) {(data, response, error) in
            let clientResponse = self.getHttpClientResponse(url, data, response, error)
            handler.onComplete(clientResponse)
        }
        task.resume()
    }

    private func getHttpClientResponse(_ url: String, _ data: Data?, _ response: URLResponse?, _ error: Error?) -> HttpClientResponse {
        var clientResponse = HttpClientResponse(url)
        
        guard let data = data, error == nil else {
            clientResponse.code = 500
            clientResponse.msg = String(describing: error)
            return clientResponse
        }
        
        if let httpResponse = response as? HTTPURLResponse {
            do {
                if let responseJSON = try JSONSerialization.jsonObject(with: data, options: []) as? [String: Any] {
                    clientResponse.code = httpResponse.statusCode
                    clientResponse.data = responseJSON
                    return clientResponse
                }
            } catch let error as NSError {
                clientResponse.code = 500
                clientResponse.msg = String(describing: error)
                return clientResponse
            }
        }
        
        clientResponse.code = 500
        clientResponse.msg = "Malformed response"
        return clientResponse
    }
}
