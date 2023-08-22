// This file is autogenerated by ASN1.ERP.UNO. Do not edit.

import ASN1SCG
import SwiftASN1
import Crypto
import Foundation

@usableFromInline struct LDAPResult: DERImplicitlyTaggable, Hashable, Sendable {
    @inlinable static var defaultIdentifier: ASN1Identifier { .sequence }
    @usableFromInline var resultCode: LDAPResult
    @usableFromInline var matchedDN: ASN1OctetString
    @usableFromInline var diagnosticMessage: ASN1OctetString
    @usableFromInline var referral: [String]
    @inlinable init(resultCode: LDAPResult, matchedDN: ASN1OctetString, diagnosticMessage: ASN1OctetString, referral: [String]) {
        self.resultCode = resultCode
        self.matchedDN = matchedDN
        self.diagnosticMessage = diagnosticMessage
        self.referral = referral
    }
    @inlinable init(derEncoded root: ASN1Node,
        withIdentifier identifier: ASN1Identifier) throws {
        self = try DER.sequence(root, identifier: identifier) { nodes in
            let resultCode = try LDAPResult(derEncoded: &nodes)
            let matchedDN = try ASN1OctetString(derEncoded: &nodes)
            let diagnosticMessage = try ASN1OctetString(derEncoded: &nodes)
            let referral = try DER.sequence(of: String.self, identifier: .sequence, nodes: &nodes)
            return LDAPResult(resultCode: resultCode, matchedDN: matchedDN, diagnosticMessage: diagnosticMessage, referral: referral)
        }
    }
    @inlinable func serialize(into coder: inout DER.Serializer,
        withIdentifier identifier: ASN1Identifier) throws {
        try coder.appendConstructedNode(identifier: identifier) { coder in
            try coder.serialize(self.resultCode)
            try coder.serialize(self.matchedDN)
            try coder.serialize(self.diagnosticMessage)
            try coder.serializeSequenceOf(referral)
        }
    }
}
