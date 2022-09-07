//
//  URLSessionManager.swift
//  RequestBuilder
//
//  Created by Michael Long on 8/29/22.
//

import Foundation
import Combine

public protocol URLSessionManager: AnyObject {

    // base
    var base: URL? { get }

    // codable
    var defaultEncoder: DataEncoder { get }
    var defaultDecoder: DataDecoder { get }

    // request support
    func request(forURL url: URL?) -> URLRequestBuilder
    func data(for request: URLRequest) -> AnyPublisher<(Any?, HTTPURLResponse?), Error>

    // interceptor support
    func interceptor(_ interceptor: URLRequestInterceptor) -> URLSessionManager
    
}

extension URLSessionManager {

    /// Convenience function returns a new request builder using the session's base URL.
    public func request() -> URLRequestBuilder {
        self.request(forURL: nil)
    }

    /// Adds a new intercept handler to the session manager chain
    public func interceptor(_ interceptor: URLRequestInterceptor) -> URLSessionManager {
        interceptor.parent = self
        return interceptor
    }

}
