//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import protocol Smithy.RequestMessageSerializer
import class Smithy.Context
import SmithyEventStreams
import SmithyEventStreamsAPI
import SmithyEventStreamsAuthAPI
import struct Foundation.Data
@_spi(SmithyReadWrite) import typealias SmithyReadWrite.WritingClosure
import SmithyHTTPAPI

public struct EventStreamBodyMiddleware<OperationStackInput,
                                        OperationStackOutput,
                                        OperationStackInputPayload> {
    public let id: Swift.String = "EventStreamBodyMiddleware"

    let keyPath: KeyPath<OperationStackInput, AsyncThrowingStream<OperationStackInputPayload, Swift.Error>?>
    let defaultBody: String?
    let marshalClosure: MarshalClosure<OperationStackInputPayload>
    let initialRequestMessage: Message?

    public init(
        keyPath: KeyPath<OperationStackInput, AsyncThrowingStream<OperationStackInputPayload, Swift.Error>?>,
        defaultBody: String? = nil,
        marshalClosure: @escaping MarshalClosure<OperationStackInputPayload>,
        initialRequestMessage: Message? = nil
    ) {
        self.keyPath = keyPath
        self.defaultBody = defaultBody
        self.marshalClosure = marshalClosure
        self.initialRequestMessage = initialRequestMessage
    }
}

extension EventStreamBodyMiddleware: RequestMessageSerializer {
    public typealias InputType = OperationStackInput
    public typealias RequestType = HTTPRequest

    public func apply(input: OperationStackInput, builder: HTTPRequestBuilder, attributes: Smithy.Context) throws {
        if let eventStream = input[keyPath: keyPath] {
            guard let messageEncoder = attributes.messageEncoder else {
                fatalError("Message encoder is required for streaming payload")
            }
            guard let messageSigner = attributes.messageSigner else {
                fatalError("Message signer is required for streaming payload")
            }
            let encoderStream = DefaultMessageEncoderStream(
              stream: eventStream,
              messageEncoder: messageEncoder,
              marshalClosure: marshalClosure,
              messageSigner: messageSigner,
              initialRequestMessage: initialRequestMessage
            )
            builder.withBody(.stream(encoderStream))
        } else if let defaultBody {
            builder.withBody(.data(Data(defaultBody.utf8)))
        }
    }
}
