// Generated by ASN1.ERP.UNO Compiler, Copyright © 2023 Namdak Tonpa.
import SwiftASN1
import Crypto
import Foundation

@usableFromInline struct MatchingRuleAssertion: DERImplicitlyTaggable, Hashable, Sendable {
    @inlinable static var defaultIdentifier: ASN1Identifier { .sequence }
    @usableFromInline var matchingRule: ASN1OctetString?
    @usableFromInline var type: ASN1OctetString?
    @usableFromInline var matchValue: ASN1OctetString
    @usableFromInline var dnAttributes: Bool
    @inlinable init(matchingRule: ASN1OctetString?, type: ASN1OctetString?, matchValue: ASN1OctetString, dnAttributes: Bool) {
        self.matchingRule = matchingRule
        self.type = type
        self.matchValue = matchValue
        self.dnAttributes = dnAttributes
    }
    @inlinable init(derEncoded root: ASN1Node,
        withIdentifier identifier: ASN1Identifier) throws {
        self = try DER.sequence(root, identifier: identifier) { nodes in
            let matchingRule: ASN1OctetString? = try DER.optionalImplicitlyTagged(&nodes, tagNumber: 1, tagClass: .contextSpecific) { node in return try ASN1OctetString(derEncoded: node) }
            let type: ASN1OctetString? = try DER.optionalImplicitlyTagged(&nodes, tagNumber: 2, tagClass: .contextSpecific) { node in return try ASN1OctetString(derEncoded: node) }
            let matchValue: ASN1OctetString = try ASN1OctetString(derEncoded: &nodes)
            let dnAttributes: Bool = try Bool(derEncoded: &nodes)
            return MatchingRuleAssertion(matchingRule: matchingRule, type: type, matchValue: matchValue, dnAttributes: dnAttributes)
        }
    }
    @inlinable func serialize(into coder: inout DER.Serializer,
        withIdentifier identifier: ASN1Identifier) throws {
        try coder.appendConstructedNode(identifier: identifier) { coder in
            if let matchingRule = self.matchingRule { try coder.serializeOptionalImplicitlyTagged(matchingRule, withIdentifier: ASN1Identifier(tagWithNumber: 1, tagClass: .contextSpecific)) }
            if let type = self.type { try coder.serializeOptionalImplicitlyTagged(type, withIdentifier: ASN1Identifier(tagWithNumber: 2, tagClass: .contextSpecific)) }
            try coder.serializeOptionalImplicitlyTagged(matchValue, withIdentifier: ASN1Identifier(tagWithNumber: 3, tagClass: .contextSpecific))
            try coder.serializeOptionalImplicitlyTagged(dnAttributes, withIdentifier: ASN1Identifier(tagWithNumber: 4, tagClass: .contextSpecific))
        }
    }
}
