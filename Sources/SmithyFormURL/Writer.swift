//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

@_spi(SmithyReadWrite) import protocol SmithyReadWrite.SmithyWriter
import protocol Smithy.SmithyDocument
@_spi(SmithyTimestamps) import enum SmithyTimestamps.TimestampFormat
@_spi(SmithyTimestamps) import struct SmithyTimestamps.TimestampFormatter
import struct Foundation.Data
import struct Foundation.Date
import struct Foundation.CharacterSet

@_spi(SmithyReadWrite)
public final class Writer: SmithyWriter {
    public typealias NodeInfo = SmithyFormURL.NodeInfo

    let nodeInfo: NodeInfo
    var content: String?
    var children: [Writer] = []
    weak var parent: Writer?
    public var nodeInfoPath: [NodeInfo] { (parent?.nodeInfoPath ?? []) + [nodeInfo] }

    public required init(nodeInfo: NodeInfo) {
        self.nodeInfo = nodeInfo
    }

    init(nodeInfo: NodeInfo, parent: Writer? = nil) {
        self.nodeInfo = nodeInfo
        self.parent = parent
    }
}

public extension Writer {

    func data() throws -> Data {
        return Data((query ?? "").utf8)
    }

    private var query: String? {
        var subqueries = [String]()
        if !nodeInfo.name.isEmpty && !((content ?? "").isEmpty && !children.isEmpty) {
            self.subqueryString.map { subqueries.append($0) }
        }
        children.forEach { child in
            if let query = child.query { subqueries.append(query) }
        }
        guard !subqueries.isEmpty else { return nil }
        return subqueries.joined(separator: "&")
    }

    private var subqueryString: String? {
        guard let content else { return nil }
        let queryName = nodeInfoPath.map(\.name).filter { !$0.isEmpty }.joined(separator: ".")
        return "\(queryName.urlPercentEncodedForQuery)=\(content.urlPercentEncodedForQuery)"
    }

    subscript(nodeInfo: NodeInfo) -> Writer {
        if let child = children.first(where: { $0.nodeInfo == nodeInfo }) {
            return child
        } else {
            let newChild = Writer(nodeInfo: nodeInfo, parent: self)
            addChild(newChild)
            return newChild
        }
    }

    func write(_ value: Bool?) throws {
        record(string: value.map { $0 ? "true" : "false" })
    }

    func write(_ value: String?) throws {
        record(string: value)
    }

    func write(_ value: Double?) throws {
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

    func write(_ value: Float?) throws {
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

    func write(_ value: Int?) throws {
        record(string: value.map { "\($0)" })
    }

    func write(_ value: Int8?) throws {
        record(string: value.map { "\($0)" })
    }

    func write(_ value: Int16?) throws {
        record(string: value.map { "\($0)" })
    }

    func write(_ value: UInt8?) throws {
        record(string: value.map { "\($0)" })
    }

    func write(_ value: Data?) throws {
        try write(value?.base64EncodedString())
    }

    func write(_ value: SmithyDocument?) throws {
        // No operation.  Smithy document not supported in FormURL
    }

    func writeTimestamp(_ value: Date?, format: SmithyTimestamps.TimestampFormat) throws {
        guard let value else { return }
        record(string: TimestampFormatter(format: format).string(from: value))
    }

    func write<T>(_ value: T?) throws where T: RawRepresentable, T.RawValue == Int {
        try write(value?.rawValue)
    }

    func write<T>(_ value: T?) throws where T: RawRepresentable, T.RawValue == String {
        try write(value?.rawValue)
    }

    func writeMap<T>(
        _ value: [String: T]?,
        valueWritingClosure: (T, Writer) throws -> Void,
        keyNodeInfo: NodeInfo,
        valueNodeInfo: NodeInfo,
        isFlattened: Bool
    ) throws {
        guard let value, !value.isEmpty else { return }
        let entryWriter = isFlattened ? self : self[.init("entry")]
        let keysAndValues = value.map { (key: $0.key, value: $0.value) }.sorted { $0.key < $1.key }
        for (index, (key, value)) in keysAndValues.enumerated() {
            let indexedWriter = entryWriter[.init("\(index + 1)")]
            try indexedWriter[keyNodeInfo].write(key)
            try valueWritingClosure(value, indexedWriter[valueNodeInfo])
        }
    }

    func writeList<T>(
        _ value: [T]?,
        memberWritingClosure: (T, Writer) throws -> Void,
        memberNodeInfo: NodeInfo,
        isFlattened: Bool
    ) throws {
        guard let value else { return }
        guard !value.isEmpty else { try write(""); return }
        let entryWriter = isFlattened ? self : self[memberNodeInfo]
        for (index, value) in value.enumerated() {
            let indexedWriter = entryWriter[.init("\(index + 1)")]
            try memberWritingClosure(value, indexedWriter)
        }
    }

    func writeNull() throws {
        // Null not defined in FormURL.
        // No action taken, node remains in 'no content' state.
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

private extension String {

    private static let allowedForQuery = CharacterSet.alphanumerics.union(CharacterSet(charactersIn: "_-.~"))

    var urlPercentEncodedForQuery: String {
        addingPercentEncoding(withAllowedCharacters: Self.allowedForQuery) ?? self
    }
}
