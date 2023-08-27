// Generated by ASN1.ERP.UNO Compiler, Copyright © 2023 Namdak Tonpa.
import SwiftASN1
import Crypto
import Foundation

@usableFromInline struct SubstringFilter: DERImplicitlyTaggable, Hashable, Sendable {
    @inlinable static var defaultIdentifier: ASN1Identifier { .sequence }
    @usableFromInline var type: ASN1OctetString
    @usableFromInline var substrings: [SubstringFilter_substrings_Choice]
    @inlinable init(type: ASN1OctetString, substrings: [SubstringFilter_substrings_Choice]) {
        self.type = type
        self.substrings = substrings
    }
    @inlinable init(derEncoded root: ASN1Node,
        withIdentifier identifier: ASN1Identifier) throws {
        self = try DER.sequence(root, identifier: identifier) { nodes in
            let type = try ASN1OctetString(derEncoded: &nodes)
            let substrings = try DER.sequence(of: SubstringFilter_substrings_Choice.self, identifier: .sequence, nodes: &nodes)
            return SubstringFilter(type: type, substrings: substrings)
        }
    }
    @inlinable func serialize(into coder: inout DER.Serializer,
        withIdentifier identifier: ASN1Identifier) throws {
        try coder.appendConstructedNode(identifier: identifier) { coder in
            try coder.serialize(type)
            try coder.serializeSequenceOf(substrings)
        }
    }
}
