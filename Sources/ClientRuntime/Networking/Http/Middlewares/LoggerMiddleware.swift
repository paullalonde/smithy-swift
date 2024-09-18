//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import protocol Smithy.LogAgent
import class Smithy.Context
import class SmithyHTTPAPI.HTTPRequest
import class SmithyHTTPAPI.HTTPResponse

public struct LoggerMiddleware<OperationStackInput, OperationStackOutput> {

    public let id: String = "Logger"

    let clientLogMode: ClientLogMode

    public init(clientLogMode: ClientLogMode) {
        self.clientLogMode = clientLogMode
    }

    private func logRequest(logger: any LogAgent, request: HTTPRequest) {
        if clientLogMode == .requestWithoutAuthorizationHeader {
            logger.debug("Request: \(request.debugDescriptionWithoutAuthorizationHeader)")
        } else if clientLogMode == .request || clientLogMode == .requestAndResponse {
            logger.debug("Request: \(request.debugDescription)")
        } else if clientLogMode == .requestAndResponseWithBody || clientLogMode == .requestWithBody {
            logger.debug("Request: \(request.debugDescriptionWithBody)")
        }
    }

    private func logResponse(logger: any LogAgent, response: HTTPResponse) {
        if clientLogMode == .response || clientLogMode == .requestAndResponse {
            logger.debug("Response: \(response.debugDescription)")
        } else if clientLogMode == .requestAndResponseWithBody || clientLogMode == .responseWithBody {
            logger.debug("Response: \(response.debugDescriptionWithBody)")
        }
    }
}

extension LoggerMiddleware: Interceptor {
    public typealias InputType = OperationStackInput
    public typealias OutputType = OperationStackOutput
    public typealias RequestType = HTTPRequest
    public typealias ResponseType = HTTPResponse

    public func readBeforeTransmit(
        context: some AfterSerialization<InputType, RequestType>
    ) async throws {
        guard let logger = context.getAttributes().getLogger() else {
            return
        }

        logRequest(logger: logger, request: context.getRequest())
    }

    public func readAfterTransmit(
        context: some BeforeDeserialization<InputType, RequestType, ResponseType>
    ) async throws {
        guard let logger = context.getAttributes().getLogger() else {
            return
        }

        logResponse(logger: logger, response: context.getResponse())
    }
}
