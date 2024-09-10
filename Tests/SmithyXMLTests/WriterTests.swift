//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

@_spi(SmithyReadWrite) import SmithyReadWrite
@_spi(SmithyReadWrite) import SmithyXML
import XCTest

class WriterTests: XCTestCase {

    private struct HasNestedElements: Encodable {

        static func write(_ value: HasNestedElements, to writer: Writer) throws {
            try writer[.init("a")].write(value.a)
            try writer[.init("b")].write(value.b)
        }

        let a: String
        let b: String
    }

    func test_encodesXMLWithNestedElements() throws {
        let data = try Writer.write(
            HasNestedElements(a: "a", b: "b"),
            rootNodeInfo: .init("test"),
            with: HasNestedElements.write(_:to:)
        )
        let expected = "<test><a>a</a><b>b</b></test>"
        XCTAssertEqual(String(data: try XCTUnwrap(data), encoding: .utf8), expected)
    }

    private struct HasNestedElementAndAttribute: Encodable {

        static func write(_ value: HasNestedElementAndAttribute, to writer: Writer) throws {
            try writer[.init("a")].write(value.a)
            try writer[.init("b", location: .attribute)].write(value.b)
        }

        let a: String
        let b: String
    }

    func test_encodesXMLWithElementAndAttribute() throws {
        let data = try Writer.write(
            HasNestedElementAndAttribute(a: "a", b: "b"),
            rootNodeInfo: .init("test"),
            with: HasNestedElementAndAttribute.write(_:to:)
        )
        let expected = "<test b=\"b\"><a>a</a></test>"
        XCTAssertEqual(String(data: try XCTUnwrap(data), encoding: .utf8), expected)
    }

    func test_encodesXMLWithElementAndAttributeAndNamespace() throws {
        let data = try Writer.write(
            HasNestedElementAndAttribute(a: "a", b: "b"),
            rootNodeInfo: .init("test", namespaceDef: .init(prefix: "", uri: "https://www.def.com/1.0")),
            with: HasNestedElementAndAttribute.write(_:to:)
        )
        let expected = "<test xmlns=\"https://www.def.com/1.0\" b=\"b\"><a>a</a></test>"
        XCTAssertEqual(String(data: try XCTUnwrap(data), encoding: .utf8), expected)
    }

    func test_encodesXMLWithElementAndAttributeAndSpecialChars() throws {
        let data = try Writer.write(
            HasNestedElementAndAttribute(a: "'<a&z>'", b: "\"b&s\""),
            rootNodeInfo: .init("test"),
            with: HasNestedElementAndAttribute.write(_:to:)
        )
        let expected = "<test b=\"&quot;b&amp;s&quot;\"><a>\'&lt;a&amp;z&gt;\'</a></test>"
        XCTAssertEqual(String(data: try XCTUnwrap(data), encoding: .utf8), expected)
    }
}
