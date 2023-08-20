// This file is autogenerated by ASN1.ERP.UNO. Do not edit.

import ASN1SCG
import SwiftASN1
import Crypto
import Foundation

@usableFromInline struct MatchingRuleAssertion: DERImplicitlyTaggable, Hashable, Sendable {
    @inlinable static var defaultIdentifier: ASN1Identifier { .sequence }
    @usableFromInline var matchingRule: ASN1OctetString
    @usableFromInline var type: ASN1OctetString
    @usableFromInline var matchValue: ASN1OctetString
    @usableFromInline var dnAttributes: Bool
    @inlinable init(matchingRule: ASN1OctetString, type: ASN1OctetString, matchValue: ASN1OctetString, dnAttributes: Bool) {
        self.matchingRule = matchingRule
        self.type = type
        self.matchValue = matchValue
        self.dnAttributes = dnAttributes
    }
    @inlinable init(derEncoded root: ASN1Node,
        withIdentifier identifier: ASN1Identifier) throws {
        self = try DER.sequence(root, identifier: identifier) { nodes in
            let matchingRule = try ASN1OctetString(derEncoded: &nodes)
            let type = try ASN1OctetString(derEncoded: &nodes)
            let matchValue = try ASN1OctetString(derEncoded: &nodes)
            let dnAttributes = try Bool(derEncoded: &nodes)
            return MatchingRuleAssertion(matchingRule: matchingRule, type: type, matchValue: matchValue, dnAttributes: dnAttributes)
        }
    }
    @inlinable func serialize(into coder: inout DER.Serializer,
        withIdentifier identifier: ASN1Identifier) throws {
        try coder.appendConstructedNode(identifier: identifier) { coder in
            try coder.serialize(self.matchingRule)
            try coder.serialize(self.type)
            try coder.serialize(self.matchValue)
            try coder.serialize(self.dnAttributes)
        }
    }
}
