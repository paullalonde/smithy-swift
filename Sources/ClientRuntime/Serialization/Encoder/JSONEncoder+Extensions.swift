/*
 * Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
 * SPDX-License-Identifier: Apache-2.0.
 */

import Foundation

public typealias JSONEncoder = Foundation.JSONEncoder
extension JSONEncoder: RequestEncoder {
    public var messageEncoder: MessageEncoder? {
        return AWSMessageEncoder()
    }
}
