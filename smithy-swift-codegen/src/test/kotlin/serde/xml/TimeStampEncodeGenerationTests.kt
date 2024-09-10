/*
 * Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
 * SPDX-License-Identifier: Apache-2.0.
 */

package serde.xml

import MockHTTPRestXMLProtocolGenerator
import TestContext
import defaultSettings
import getFileContents
import io.kotest.matchers.string.shouldContainOnlyOnce
import org.junit.jupiter.api.Test

class TimeStampEncodeGenerationTests {
    @Test
    fun `001 encode all timestamps`() {
        val context = setupTests("Isolated/Restxml/xml-timestamp.smithy", "aws.protocoltests.restxml#RestXml")
        val contents = getFileContents(context.manifest, "Sources/RestXml/models/XmlTimestampsInput+Write.swift")
        val expectedContents = """
extension XmlTimestampsInput {

    static func write(value: XmlTimestampsInput?, to writer: SmithyXML.Writer) throws {
        guard let value else { return }
        try writer["dateTime"].writeTimestamp(value.dateTime, format: SmithyTimestamps.TimestampFormat.dateTime)
        try writer["epochSeconds"].writeTimestamp(value.epochSeconds, format: SmithyTimestamps.TimestampFormat.epochSeconds)
        try writer["httpDate"].writeTimestamp(value.httpDate, format: SmithyTimestamps.TimestampFormat.httpDate)
        try writer["normal"].writeTimestamp(value.normal, format: SmithyTimestamps.TimestampFormat.dateTime)
    }
}
"""
        contents.shouldContainOnlyOnce(expectedContents)
    }

    @Test
    fun `002 encode nested list with timestamps`() {
        val context = setupTests("Isolated/Restxml/xml-timestamp-nested.smithy", "aws.protocoltests.restxml#RestXml")
        val contents = getFileContents(context.manifest, "Sources/RestXml/models/XmlTimestampsNestedInput+Write.swift")
        val expectedContents = """
extension XmlTimestampsNestedInput {

    static func write(value: XmlTimestampsNestedInput?, to writer: SmithyXML.Writer) throws {
        guard let value else { return }
        try writer["nestedTimestampList"].writeList(value.nestedTimestampList, memberWritingClosure: SmithyReadWrite.listWritingClosure(memberWritingClosure: SmithyReadWrite.timestampWritingClosure(format: SmithyTimestamps.TimestampFormat.epochSeconds), memberNodeInfo: "member", isFlattened: false), memberNodeInfo: "member", isFlattened: false)
    }
}
"""
        contents.shouldContainOnlyOnce(expectedContents)
    }

    @Test
    fun `003 encode nested list with timestamps httpDate`() {
        val context = setupTests("Isolated/Restxml/xml-timestamp-nested.smithy", "aws.protocoltests.restxml#RestXml")
        val contents = getFileContents(context.manifest, "Sources/RestXml/models/XmlTimestampsNestedHTTPDateInput+Write.swift")
        val expectedContents = """
extension XmlTimestampsNestedHTTPDateInput {

    static func write(value: XmlTimestampsNestedHTTPDateInput?, to writer: SmithyXML.Writer) throws {
        guard let value else { return }
        try writer["nestedTimestampList"].writeList(value.nestedTimestampList, memberWritingClosure: SmithyReadWrite.listWritingClosure(memberWritingClosure: SmithyReadWrite.timestampWritingClosure(format: SmithyTimestamps.TimestampFormat.httpDate), memberNodeInfo: "member", isFlattened: false), memberNodeInfo: "member", isFlattened: false)
    }
}
"""
        contents.shouldContainOnlyOnce(expectedContents)
    }

    @Test
    fun `004 encode nested list with timestamps with xmlname`() {
        val context = setupTests("Isolated/Restxml/xml-timestamp-nested-xmlname.smithy", "aws.protocoltests.restxml#RestXml")
        val contents = getFileContents(context.manifest, "Sources/RestXml/models/XmlTimestampsNestedXmlNameInput+Write.swift")
        val expectedContents = """
extension XmlTimestampsNestedXmlNameInput {

    static func write(value: XmlTimestampsNestedXmlNameInput?, to writer: SmithyXML.Writer) throws {
        guard let value else { return }
        try writer["nestedTimestampList"].writeList(value.nestedTimestampList, memberWritingClosure: SmithyReadWrite.listWritingClosure(memberWritingClosure: SmithyReadWrite.timestampWritingClosure(format: SmithyTimestamps.TimestampFormat.epochSeconds), memberNodeInfo: "nestedTag2", isFlattened: false), memberNodeInfo: "nestedTag1", isFlattened: false)
    }
}
"""
        contents.shouldContainOnlyOnce(expectedContents)
    }

    @Test
    fun `005 encode all timestamps, withxmlName`() {
        val context = setupTests("Isolated/Restxml/xml-timestamp-xmlname.smithy", "aws.protocoltests.restxml#RestXml")
        val contents = getFileContents(context.manifest, "Sources/RestXml/models/XmlTimestampsXmlNameInput+Write.swift")
        val expectedContents = """
extension XmlTimestampsXmlNameInput {

    static func write(value: XmlTimestampsXmlNameInput?, to writer: SmithyXML.Writer) throws {
        guard let value else { return }
        try writer["dateTime"].writeTimestamp(value.dateTime, format: SmithyTimestamps.TimestampFormat.dateTime)
        try writer["notNormalName"].writeTimestamp(value.normal, format: SmithyTimestamps.TimestampFormat.dateTime)
    }
}
"""
        contents.shouldContainOnlyOnce(expectedContents)
    }
    private fun setupTests(smithyFile: String, serviceShapeId: String): TestContext {
        val context = TestContext.initContextFrom(smithyFile, serviceShapeId, MockHTTPRestXMLProtocolGenerator()) { model ->
            model.defaultSettings(serviceShapeId, "RestXml", "2019-12-16", "Rest Xml Protocol")
        }
        context.generator.generateCodableConformanceForNestedTypes(context.generationCtx)
        context.generator.generateSerializers(context.generationCtx)
        context.generationCtx.delegator.flushWriters()
        return context
    }
}
