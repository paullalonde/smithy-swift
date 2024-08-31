/*
 * Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
 * SPDX-License-Identifier: Apache-2.0.
 */

import Smithy
import SmithyHTTPAPI
import Foundation
import ClientRuntime
import XCTest

open class NetworkingTestUtils: XCTestCase {

    public var mockHttpDataRequest: HTTPRequest!
    public var mockHttpStreamRequest: HTTPRequest!
    public var expectedMockRequestURL: URL!
    public var expectedMockRequestData: Data!

    override open func setUp() {
        super.setUp()
        expectedMockRequestURL = URL(string: "https://myapi.host.com/path/to/endpoint?qualifier=qualifier-value")!
        let mockRequestBody = "{\"parameter\": \"value\"}"
        expectedMockRequestData = mockRequestBody.data(using: .utf8)
        setMockHttpDataRequest()
        setMockHttpStreamRequest()
    }

    /*
     Create a mock HttpRequest with valid data payload
     */
    open func setMockHttpDataRequest() {
        let headers = Headers(["header-item-name": "header-item-value"])
        let endpoint = getMockEndpoint(headers: headers)

        let httpBody = ByteStream.data(expectedMockRequestData)
        mockHttpDataRequest = HTTPRequest(method: .get, endpoint: endpoint, body: httpBody)
    }

    /*
     Create a mock HttpRequest with valid InputStream
     */
    open func setMockHttpStreamRequest() {
        let headers = Headers(["header-item-name": "header-item-value"])
        let endpoint = getMockEndpoint(headers: headers)

        let httpBody = ByteStream.data(expectedMockRequestData)
        mockHttpStreamRequest = HTTPRequest(method: .get, endpoint: endpoint, body: httpBody)
    }

    open func getMockEndpoint(headers: Headers) -> Endpoint {
        let path = "/path/to/endpoint"
        let host = "myapi.host.com"
        var queryItems: [URIQueryItem] = []
        let endpoint: Endpoint!

        queryItems.append(URIQueryItem(name: "qualifier", value: "qualifier-value"))
        endpoint = Endpoint(host: host, path: path, queryItems: queryItems, headers: headers)
        return endpoint
    }
}
