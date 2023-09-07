// Generated by ASN1.ERP.UNO Compiler, Copyright © 2023 Namdak Tonpa.
import SwiftASN1
import Crypto
import Foundation

@usableFromInline struct Attribute: DERImplicitlyTaggable, Hashable, Sendable {
    @inlinable static var defaultIdentifier: ASN1Identifier { .sequence }
    @usableFromInline var type: ASN1ObjectIdentifier
    @usableFromInline var values: [ASN1OctetString]
    @inlinable init(type: ASN1ObjectIdentifier, values: [ASN1OctetString]) {
        self.type = type
        self.values = values
    }
    @inlinable init(derEncoded root: ASN1Node,
        withIdentifier identifier: ASN1Identifier) throws {
        self = try DER.sequence(root, identifier: identifier) { nodes in
            let type: ASN1ObjectIdentifier = try ASN1ObjectIdentifier(derEncoded: &nodes)
            let values: [ASN1OctetString] = try DER.set(of: ASN1OctetString.self, identifier: .set, nodes: &nodes)
            return Attribute(type: type, values: values)
        }
    }
    @inlinable func serialize(into coder: inout DER.Serializer,
        withIdentifier identifier: ASN1Identifier) throws {
        try coder.appendConstructedNode(identifier: identifier) { coder in
            try coder.serialize(type)
            try coder.serializeSetOf(values)
        }
    }
}
