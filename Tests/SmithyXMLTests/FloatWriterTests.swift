//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import XCTest
@_spi(SmithyReadWrite) import SmithyXML
@_spi(SmithyReadWrite) import SmithyReadWrite

class FloatWriterTests: XCTestCase {

    private struct HasFPElements {

        static func write(_ value: HasFPElements, to writer: Writer) throws {
            try writer[.init("f")].write(value.f)
            try writer[.init("d")].write(value.d)
        }

        let f: Float
        let d: Double
    }

    func test_serializesInfinity() throws {
        let fp = HasFPElements(f: .infinity, d: .infinity)
        let actualData = try Writer.write(
            fp,
            rootNodeInfo: .init("fp"),
            with: HasFPElements.write(_:to:)
        )
        let expectedData = Data("<fp><f>Infinity</f><d>Infinity</d></fp>".utf8)
        XCTAssertEqual(actualData, expectedData)
    }

    func test_serializesNegativeInfinity() throws {
        let fp = HasFPElements(f: -.infinity, d: -.infinity)
        let actualData = try Writer.write(
            fp,
            rootNodeInfo: .init("fp"),
            with: HasFPElements.write(_:to:)
        )
        let expectedData = Data("<fp><f>-Infinity</f><d>-Infinity</d></fp>".utf8)
        XCTAssertEqual(actualData, expectedData)
    }

    func test_serializesNaN() throws {
        let fp = HasFPElements(f: .nan, d: .nan)
        let actualData = try Writer.write(
            fp,
            rootNodeInfo: .init("fp"),
            with: HasFPElements.write(_:to:)
        )
        let expectedData = Data("<fp><f>NaN</f><d>NaN</d></fp>".utf8)
        XCTAssertEqual(actualData, expectedData)
    }
}
