//
//  URLRequestInterceptorMock.swift
//  LiveFrontDemo
//
//  Created by Michael Long on 8/31/22.
//

import Foundation
import Combine

public class URLRequestInterceptorMock: URLRequestInterceptor {

    public static let ANYPATH = "*"

    public struct Mock {
        var status: Int
        var data: () -> Any?
        var error: Error?
    }

    public var mocks: [String:Mock] = [:]
    public var parent: URLSessionManager!

    // MARK: - Path Mocking

    public func mock(data: Data?, status: Int = 200) {
        mock(.init(status: status, data: { data }, error: nil))
    }

    public func mock(path: String, data: Data?, status: Int = 200) {
        mock(.init(status: status, data: { data }, error: nil), path: path)
    }

    public func mock<T>(data: @escaping @autoclosure () -> T, status: Int = 200) {
        mock(.init(status: status, data: data, error: nil))
    }

    public func mock<T>(path: String, data: @escaping @autoclosure () -> T, status: Int = 200) {
        mock(.init(status: status, data: data, error: nil), path: path)
    }

    public func mock(error: Error, status: Int = 999) {
        mock(.init(status: status, data: { nil }, error: error))
    }

    public func mock(path: String, error: Error, status: Int = 999) {
        mock(.init(status: status, data: { nil }, error: error), path: path)
    }

    public func mock(status: Int) {
        mock(.init(status: status, data: { Data() }, error: nil))
    }

    public func mock(path: String, status: Int) {
        mock(.init(status: status, data: { Data() }, error: nil), path: path)
    }

    // MARK: - Supporting

    public func mock(_ mock: Mock, path: String = ANYPATH) {
        mocks[normalized(path)] = mock
    }

    public func remove(path: String = ANYPATH) {
        mocks.removeValue(forKey: normalized(path))
    }

    public func reset() {
        mocks = [:]
    }

    // MARK: - Interceptor

    public func data(for request: URLRequest) -> AnyPublisher<(Any?, HTTPURLResponse?), Error> {
#if DEBUG
        if mocks.isEmpty {
            return parent.data(for: request)
        }
        if let path = request.url?.absoluteString, let mock = mocks[normalized(path)] {
            return publisher(for: mock, path: path)
        }
        if let mock = mocks[Self.ANYPATH] {
            return publisher(for: mock, path: "/")
        }
#endif
        return parent.data(for: request)
    }

    // MARK: - Helpers

    // standard return function for mock
    public func publisher(for mock: Mock, path: String) -> AnyPublisher<(Any?, HTTPURLResponse?), Error> {
        if let data = mock.data() {
            return Just((data, HTTPURLResponse(url: URL(string: path)!, statusCode: mock.status, httpVersion: nil, headerFields: nil)))
                .setFailureType(to: Error.self)
                .eraseToAnyPublisher()
        } else {
            return Just<(Any?, HTTPURLResponse?)>((nil, nil))
                .setFailureType(to: Error.self)
                .tryMap { _ in
                    throw (mock.error ?? URLError(.unknown))
                }
                .eraseToAnyPublisher()
        }
    }

    // this exists due to randomization of query item elements when absoluteString builds
    public func normalized(_ path: String) -> String {
        let comp = path.components(separatedBy: "?")
        if comp.count == 1 {
            return path
        }
        let items = comp[1]
            .components(separatedBy: "&")
            .sorted()
            .joined(separator: "&")
        return comp[0] + "?" + items
    }

}

extension URLSessionManager {

    /// Allows user to reach into interceptor chain to configure a single mock.
    public var mock: URLRequestInterceptorMock? {
        find(URLRequestInterceptorMock.self)
    }

    /// Allows user to reach into interceptor chain to configure a set of mocks.
    public func mock(configuration: (_ mock: URLRequestInterceptorMock) -> Void) {
        if let interceptor = find(URLRequestInterceptorMock.self) {
            configuration(interceptor)
        }
    }

}
