/*
 * Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
 * SPDX-License-Identifier: Apache-2.0.
 */

import XCTest
@testable import Runtime
import AwsCommonRuntimeKit

class CRTClientEngineIntegrationTests: NetworkingTestUtils {
    
    var httpClient: SdkHttpClient!
    
    override func setUp() {
        super.setUp()
        let httpClientConfiguration = HttpClientConfiguration()
        let crtEngine = CRTClientEngine()
        httpClient = SdkHttpClient(engine: crtEngine, config: httpClientConfiguration)
    }
    
    override func tearDown() {
        super.tearDown()
    }
    
    func testMakeHttpGetRequest() {
        let expectation = XCTestExpectation(description: "Request has been completed")
        var headers = Headers()
        headers.add(name: "Content-type", value: "application/json")
        headers.add(name: "Host", value: "httpbin.org")
        let request = SdkHttpRequest(method: .get, endpoint: Endpoint(host: "httpbin.org", path: "/get"), headers: headers)
        httpClient.execute(request: request) { result in
            switch result {
            case .success(let response):
                XCTAssertNotNil(response)
                XCTAssert(response.statusCode == HttpStatusCode.ok)
                expectation.fulfill()
            case .failure(let error):
                print(error)
                XCTFail(error.localizedDescription)
                expectation.fulfill()
            }
        }
        
        wait(for: [expectation], timeout: 10.0)
    }
    
    func testMakeHttpPostRequest() throws {
        //used https://httpbin.org
        let expectation = XCTestExpectation(description: "Request has been completed")
        var headers = Headers()
        headers.add(name: "Content-type", value: "application/json")
        headers.add(name: "Host", value: "httpbin.org")
        let body = TestBody(test: "testval")
        let encoder = JSONEncoder()
        let encodedData = try encoder.encode(body)
        let request = SdkHttpRequest(method: .post,
                                     endpoint: Endpoint(host: "httpbin.org", path: "/post"),
                                     headers: headers,
                                     body: HttpBody.data(encodedData))
        httpClient.execute(request: request) { result in
            switch result {
            case .success(let response):
                XCTAssertNotNil(response)
                XCTAssert(response.statusCode == HttpStatusCode.ok)
                expectation.fulfill()
            case .failure(let error):
                print(error)
                XCTFail(error.localizedDescription)
                expectation.fulfill()
            }
        }
        
        wait(for: [expectation], timeout: 20.0)
    }
    
    func testMakeHttpStreamRequestDynamicReceive() {
        //used https://httpbin.org
        let expectation = XCTestExpectation(description: "Request has been completed")
        var headers = Headers()
        headers.add(name: "Content-type", value: "application/json")
        headers.add(name: "Host", value: "httpbin.org")
        let request = SdkHttpRequest(method: .get,
                                     endpoint: Endpoint(host: "httpbin.org", path: "/stream-bytes/1024"),
                                     headers: headers,
                                     body: HttpBody.stream(ByteStream.defaultReader()))
        httpClient.execute(request: request) { result in
            switch result {
            case .success(let response):
                XCTAssertNotNil(response)
                XCTAssert(response.statusCode == HttpStatusCode.ok)
                expectation.fulfill()
            case .failure(let error):
                print(error)
                XCTFail(error.localizedDescription)
                expectation.fulfill()
            }
        }
        
        wait(for: [expectation], timeout: 20.0)
    }
    
    func testMakeHttpStreamRequestReceive() {
        //used https://httpbin.org
        let expectation = XCTestExpectation(description: "Request has been completed")
        var headers = Headers()
        headers.add(name: "Content-type", value: "application/json")
        headers.add(name: "Host", value: "httpbin.org")
        
        let request = SdkHttpRequest(method: .get,
                                     endpoint: Endpoint(host: "httpbin.org", path: "/stream-bytes/1024"),
                                     headers: headers,
                                     body: HttpBody.stream(ByteStream.defaultReader()))
        httpClient.execute(request: request) { result in
            switch result {
            case .success(let response):
                XCTAssertNotNil(response)
                if case let HttpBody.stream(unwrappedStream) = response.body {
                    XCTAssert(unwrappedStream.toBytes().length == 1024)
                } else {
                    XCTFail("Bytes not received")
                }
                XCTAssert(response.statusCode == HttpStatusCode.ok)
                expectation.fulfill()
            case .failure(let error):
                print(error)
                XCTFail(error.localizedDescription)
                expectation.fulfill()
            }
        }
        
        wait(for: [expectation], timeout: 20.0)
    }
    
    func testMakeHttpStreamRequestReceiveOneByte() {
        //used https://httpbin.org
        let expectation = XCTestExpectation(description: "Request has been completed")
        var headers = Headers()
        headers.add(name: "Content-type", value: "application/json")
        headers.add(name: "Host", value: "httpbin.org")
        
        let request = SdkHttpRequest(method: .get,
                                     endpoint: Endpoint(host: "httpbin.org", path: "/stream-bytes/1"),
                                     headers: headers,
                                     body: HttpBody.stream(ByteStream.defaultReader()))
        httpClient.execute(request: request) { result in
            switch result {
            case .success(let response):
                XCTAssertNotNil(response)
                if case let HttpBody.stream(unwrappedStream) = response.body {
                    XCTAssert(unwrappedStream.toBytes().length == 1)
                } else {
                    XCTFail("Bytes not received")
                }
                XCTAssert(response.statusCode == HttpStatusCode.ok)
                expectation.fulfill()
            case .failure(let error):
                print(error)
                XCTFail(error.localizedDescription)
                expectation.fulfill()
            }
        }
        
        wait(for: [expectation], timeout: 20.0)
    }
    
    func testMakeHttpStreamRequestReceive3ThousandBytes() {
        //used https://httpbin.org
        let expectation = XCTestExpectation(description: "Request has been completed")
        
        var headers = Headers()
        headers.add(name: "Content-type", value: "application/json")
        headers.add(name: "Host", value: "httpbin.org")
        
        let request = SdkHttpRequest(method: .get,
                                     endpoint: Endpoint(host: "httpbin.org", path: "/stream-bytes/3000"),
                                     headers: headers,
                                     body: HttpBody.stream(ByteStream.defaultReader()))
        httpClient.execute(request: request) { result in
            switch result {
            case .success(let response):
                XCTAssertNotNil(response)
                if case let HttpBody.stream(unwrappedStream) = response.body {
                    XCTAssert(unwrappedStream.toBytes().length == 3000)
                } else {
                    XCTFail("Bytes not received")
                }
                XCTAssert(response.statusCode == HttpStatusCode.ok)
                expectation.fulfill()
            case .failure(let error):
                print(error)
                XCTFail(error.localizedDescription)
                expectation.fulfill()
            }
        }
        
        wait(for: [expectation], timeout: 20.0)
    }
    
    func testMakeHttpStreamRequestFromData() throws {
        //used https://httpbin.org
        let expectation = XCTestExpectation(description: "Request has been completed")
        var headers = Headers()
        headers.add(name: "Content-type", value: "application/json")
        headers.add(name: "Host", value: "httpbin.org")
        let body = TestBody(test: "testval")
        let encoder = JSONEncoder()
        let encodedData = try encoder.encode(body)
        
        let request = SdkHttpRequest(method: .post,
                                     endpoint: Endpoint(host: "httpbin.org", path: "/post"),
                                     headers: headers,
                                     body: HttpBody.stream(.buffer(ByteBuffer(data: encodedData))))
        httpClient.execute(request: request) { result in
            switch result {
            case .success(let response):
                XCTAssertNotNil(response)
                XCTAssert(response.statusCode == HttpStatusCode.ok)
                expectation.fulfill()
            case .failure(let error):
                print(error)
                XCTFail(error.localizedDescription)
                expectation.fulfill()
            }
        }
        
        wait(for: [expectation], timeout: 20.0)
    }
}

struct TestBody: Codable {
    let test: String
}