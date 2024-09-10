//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

@_spi(SmithyReadWrite) import protocol SmithyReadWrite.SmithyWriter
import enum SmithyReadWrite.Document
import struct Foundation.Date
import struct Foundation.Data
@_spi(SmithyReadWrite) import typealias SmithyReadWrite.WritingClosure
@_spi(SmithyTimestamps) import enum SmithyTimestamps.TimestampFormat
@_spi(SmithyTimestamps) import struct SmithyTimestamps.TimestampFormatter

/// A class used to encode a tree of model data as XML.
///
/// Custom types (i.e. structures and unions) that are to be written as XML need to provide
/// a writing closure.  A writing closure is code generated for Smithy model types.
///
/// This writer will write all Swift types used by Smithy models, and will also write Swift
/// `Array` and `Dictionary` (optionally as flattened XML) given a writing closure for
/// their enclosed data types.
@_spi(SmithyReadWrite)
public final class Writer: SmithyWriter {
    var content: String?
    var children: [Writer] = []
    weak var parent: Writer?
    let nodeInfo: NodeInfo
    var isCollection = false
    public var nodeInfoPath: [NodeInfo] { (parent?.nodeInfoPath ?? []) + [nodeInfo] }

    // MARK: - init & deinit

    /// Used by the `DocumentWriter` to begin serialization of a model to XML.
    /// - Parameter nodeInfo: The node info for the XML node.
    public init(nodeInfo: NodeInfo) {
        self.nodeInfo = nodeInfo
    }

    private init(nodeInfo: NodeInfo, parent: Writer?) {
        self.nodeInfo = nodeInfo
        self.parent = parent
    }

    // MARK: - creating and detaching writers for subelements

    public subscript(_ nodeInfo: NodeInfo) -> Writer {
        let namespaceDef = nodeInfoPath.compactMap { $0.namespaceDef }.contains(nodeInfo.namespaceDef) ?
            nil : nodeInfo.namespaceDef
        let newNodeInfo = NodeInfo(nodeInfo.name, location: nodeInfo.location, namespaceDef: namespaceDef)
        let newChild = Writer(nodeInfo: newNodeInfo, parent: self)
        addChild(newChild)
        return newChild
    }

    // MARK: - Writing values

    public func write(_ value: Bool?) throws {
        record(string: value.map { $0 ? "true" : "false" })
    }

    public func write(_ value: String?) throws {
        record(string: value)
    }

    public func write(_ value: Double?) throws {
        guard let value else { return }
        guard !value.isNaN else {
            record(string: "NaN")
            return
        }
        switch value {
        case .infinity:
            record(string: "Infinity")
        case -.infinity:
            record(string: "-Infinity")
        default:
            record(string: "\(value)")
        }
    }

    public func write(_ value: Float?) throws {
        guard let value else { return }
        guard !value.isNaN else {
            record(string: "NaN")
            return
        }
        switch value {
        case .infinity:
            record(string: "Infinity")
        case -.infinity:
            record(string: "-Infinity")
        default:
            record(string: "\(value)")
        }
    }

    public func write(_ value: Int?) throws {
        record(string: value.map { "\($0)" })
    }

    public func write(_ value: Int8?) throws {
        record(string: value.map { "\($0)" })
    }

    public func write(_ value: Int16?) throws {
        record(string: value.map { "\($0)" })
    }

    public func write(_ value: UInt8?) throws {
        record(string: value.map { "\($0)" })
    }

    public func write(_ value: Data?) throws {
        try write(value?.base64EncodedString())
    }

    public func write(_ value: Document?) throws {
        // No operation.  Smithy document not supported in XML
    }

    public func writeTimestamp(_ value: Date?, format: TimestampFormat) throws {
        guard let value else { return }
        record(string: TimestampFormatter(format: format).string(from: value))
    }

    public func write<T: RawRepresentable>(_ value: T?) throws where T.RawValue == Int {
        try write(value?.rawValue)
    }

    public func write<T: RawRepresentable>(_ value: T?) throws where T.RawValue == String {
        try write(value?.rawValue)
    }

    public func writeMap<T>(
        _ value: [String: T]?,
        valueWritingClosure: WritingClosure<T, Writer>,
        keyNodeInfo: NodeInfo,
        valueNodeInfo: NodeInfo,
        isFlattened: Bool
    ) throws {
        guard let value else { return }
        if isFlattened {
            guard let parent = self.parent else { return }
            parent.isCollection = true
            for (key, value) in value {
                let entryWriter = parent[.init(nodeInfo.name)]
                try entryWriter[keyNodeInfo].write(key)
                try valueWritingClosure(value, entryWriter[valueNodeInfo])
            }
        } else {
            isCollection = true
            for (key, value) in value {
                let entryWriter = self[.init("entry")]
                try entryWriter[keyNodeInfo].write(key)
                try valueWritingClosure(value, entryWriter[valueNodeInfo])
            }
        }
    }

    public func writeList<T>(
        _ value: [T]?,
        memberWritingClosure: WritingClosure<T, Writer>,
        memberNodeInfo: NodeInfo,
        isFlattened: Bool
    ) throws {
        guard let value else { return }
        if isFlattened {
            guard let parent = self.parent, !nodeInfo.name.isEmpty else { return }
            parent.isCollection = true
            let flattenedMemberNodeInfo = NodeInfo(
                nodeInfo.name,
                location: memberNodeInfo.location,
                namespaceDef: memberNodeInfo.namespaceDef
            )
            for member in value {
                try memberWritingClosure(member, parent[flattenedMemberNodeInfo])
            }
        } else {
            isCollection = true
            for member in value {
                try memberWritingClosure(member, self[memberNodeInfo])
            }
        }
    }

    public func writeNull() throws {
        // Null not defined in XML.  No operation.
    }

    // MARK: - Private methods

    private func addChild(_ child: Writer) {
        children.append(child)
        child.parent = self
    }

    private func record(string: String?) {
        guard let string else { return }
        content = string
    }
}
