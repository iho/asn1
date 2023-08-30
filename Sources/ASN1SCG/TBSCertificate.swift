// Generated by ASN1.ERP.UNO Compiler, Copyright © 2023 Namdak Tonpa.
import SwiftASN1
import Crypto
import Foundation

@usableFromInline struct TBSCertificate: DERImplicitlyTaggable, Hashable, Sendable {
    @inlinable static var defaultIdentifier: ASN1Identifier { .sequence }
    @usableFromInline var version: Int
    @usableFromInline var serialNumber: ArraySlice<UInt8>
    @usableFromInline var signature: AlgorithmIdentifier
    @usableFromInline var issuer: Name
    @usableFromInline var validity: Validity
    @usableFromInline var subject: Name
    @usableFromInline var subjectPublicKeyInfo: SubjectPublicKeyInfo
    @usableFromInline var issuerUniqueID: ASN1BitString?
    @usableFromInline var subjectUniqueID: ASN1BitString?
    @usableFromInline var extensions: [Extension]?
    @inlinable init(version: Int, serialNumber: ArraySlice<UInt8>, signature: AlgorithmIdentifier, issuer: Name, validity: Validity, subject: Name, subjectPublicKeyInfo: SubjectPublicKeyInfo, issuerUniqueID: ASN1BitString?, subjectUniqueID: ASN1BitString?, extensions: [Extension]?) {
        self.version = version
        self.serialNumber = serialNumber
        self.signature = signature
        self.issuer = issuer
        self.validity = validity
        self.subject = subject
        self.subjectPublicKeyInfo = subjectPublicKeyInfo
        self.issuerUniqueID = issuerUniqueID
        self.subjectUniqueID = subjectUniqueID
        self.extensions = extensions
    }
    @inlinable init(derEncoded root: ASN1Node,
        withIdentifier identifier: ASN1Identifier) throws {
        self = try DER.sequence(root, identifier: identifier) { nodes in
            let version: Int = try DER.explicitlyTagged(&nodes, tagNumber: 0, tagClass: .contextSpecific) { node in return try Int(derEncoded: node) }
            let serialNumber: ArraySlice<UInt8> = try ArraySlice<UInt8>(derEncoded: &nodes)
            let signature: AlgorithmIdentifier = try AlgorithmIdentifier(derEncoded: &nodes)
            let issuer: Name = try Name(derEncoded: &nodes)
            let validity: Validity = try Validity(derEncoded: &nodes)
            let subject: Name = try Name(derEncoded: &nodes)
            let subjectPublicKeyInfo: SubjectPublicKeyInfo = try SubjectPublicKeyInfo(derEncoded: &nodes)
            let issuerUniqueID: ASN1BitString? = try DER.optionalImplicitlyTagged(&nodes, tag: ASN1Identifier(tagWithNumber: 1, tagClass: .contextSpecific))
            let subjectUniqueID: ASN1BitString? = try DER.optionalImplicitlyTagged(&nodes, tag: ASN1Identifier(tagWithNumber: 2, tagClass: .contextSpecific))
            let extensions: [Extension]? = try DER.optionalExplicitlyTagged(&nodes, tagNumber: 3, tagClass: .contextSpecific) { node in try DER.sequence(of: Extension.self, identifier: .sequence, rootNode: node) }
            return TBSCertificate(version: version, serialNumber: serialNumber, signature: signature, issuer: issuer, validity: validity, subject: subject, subjectPublicKeyInfo: subjectPublicKeyInfo, issuerUniqueID: issuerUniqueID, subjectUniqueID: subjectUniqueID, extensions: extensions)
        }
    }
    @inlinable func serialize(into coder: inout DER.Serializer,
        withIdentifier identifier: ASN1Identifier) throws {
        try coder.appendConstructedNode(identifier: identifier) { coder in
            try coder.serialize(explicitlyTaggedWithTagNumber: 0, tagClass: .contextSpecific) { codec in try codec.serialize(version) }
            try coder.serialize(serialNumber)
            try coder.serialize(signature)
            try coder.serialize(issuer)
            try coder.serialize(validity)
            try coder.serialize(subject)
            try coder.serialize(subjectPublicKeyInfo)
            if let issuerUniqueID = self.issuerUniqueID { try coder.serializeOptionalImplicitlyTagged(issuerUniqueID, withIdentifier: ASN1Identifier(tagWithNumber: 1, tagClass: .contextSpecific)) }
            if let subjectUniqueID = self.subjectUniqueID { try coder.serializeOptionalImplicitlyTagged(subjectUniqueID, withIdentifier: ASN1Identifier(tagWithNumber: 2, tagClass: .contextSpecific)) }
            if let extensions = self.extensions { try coder.serialize(explicitlyTaggedWithTagNumber: 3, tagClass: .contextSpecific) { codec in try codec.serializeSequenceOf(extensions) } }
        }
    }
}
