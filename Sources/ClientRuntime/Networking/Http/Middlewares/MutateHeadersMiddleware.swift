// Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
// SPDX-License-Identifier: Apache-2.0.

import class Smithy.Context
import struct SmithyHTTPAPI.Headers
import class SmithyHTTPAPI.HTTPRequestBuilder
import class SmithyHTTPAPI.HTTPRequest
import class SmithyHTTPAPI.HTTPResponse

public struct MutateHeadersMiddleware<OperationStackInput, OperationStackOutput> {

    public let id: String = "MutateHeaders"

    private var overrides: Headers
    private var additional: Headers
    private var conditionallySet: Headers

    public init(overrides: [String: String]? = nil,
                additional: [String: String]? = nil,
                conditionallySet: [String: String]? = nil) {
        self.overrides = Headers(overrides ?? [:])
        self.additional = Headers(additional ?? [:])
        self.conditionallySet = Headers(conditionallySet ?? [:])
    }

    private func mutateHeaders(builder: HTTPRequestBuilder) {
        if !additional.dictionary.isEmpty {
            builder.withHeaders(additional)
        }

        if !overrides.dictionary.isEmpty {
            for header in overrides.headers {
                builder.updateHeader(name: header.name, value: header.value)
            }
        }

        if !conditionallySet.dictionary.isEmpty {
            for header in conditionallySet.headers where !builder.headers.exists(name: header.name) {
                builder.headers.add(name: header.name, values: header.value)
            }
        }
    }
}

extension MutateHeadersMiddleware: Interceptor {
    public typealias InputType = OperationStackInput
    public typealias OutputType = OperationStackOutput
    public typealias RequestType = HTTPRequest
    public typealias ResponseType = HTTPResponse

    public func modifyBeforeTransmit(
        context: some MutableRequest<InputType, RequestType>
    ) async throws {
        let builder = context.getRequest().toBuilder()
        mutateHeaders(builder: builder)
        context.updateRequest(updated: builder.build())
    }
}
