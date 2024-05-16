// Code generated by smithy-swift-codegen. DO NOT EDIT!

import ClientRuntime
import SmithyJSON
import SmithyReadWrite

extension InvokeOutput {

    static func httpOutput(from httpResponse: ClientRuntime.HttpResponse) async throws -> InvokeOutput {
        var value = InvokeOutput()
        switch httpResponse.body {
        case .data(let data):
            value.payload = data
        case .stream(let stream):
            value.payload = try stream.readToEnd()
        case .noStream:
            value.payload = nil
        }
        return value
    }
}