// Generated by ASN1.ERP.UNO Compiler, Copyright © 2023 Namdak Tonpa.
import SwiftASN1
import Crypto
import Foundation

@usableFromInline struct Feature: DERImplicitlyTaggable, Hashable, Sendable {
    @inlinable static var defaultIdentifier: ASN1Identifier { .sequence }
    @usableFromInline var id: ASN1OctetString
    @usableFromInline var key: ASN1OctetString
    @usableFromInline var value: ASN1OctetString
    @usableFromInline var group: ASN1OctetString
    @inlinable init(id: ASN1OctetString, key: ASN1OctetString, value: ASN1OctetString, group: ASN1OctetString) {
        self.id = id
        self.key = key
        self.value = value
        self.group = group
    }
    @inlinable init(derEncoded root: ASN1Node,
        withIdentifier identifier: ASN1Identifier) throws {
        self = try DER.sequence(root, identifier: identifier) { nodes in
            let id: ASN1OctetString = try ASN1OctetString(derEncoded: &nodes)
            let key: ASN1OctetString = try ASN1OctetString(derEncoded: &nodes)
            let value: ASN1OctetString = try ASN1OctetString(derEncoded: &nodes)
            let group: ASN1OctetString = try ASN1OctetString(derEncoded: &nodes)
            return Feature(id: id, key: key, value: value, group: group)
        }
    }
    @inlinable func serialize(into coder: inout DER.Serializer,
        withIdentifier identifier: ASN1Identifier) throws {
        try coder.appendConstructedNode(identifier: identifier) { coder in
            try coder.serialize(id)
            try coder.serialize(key)
            try coder.serialize(value)
            try coder.serialize(group)
        }
    }
}
