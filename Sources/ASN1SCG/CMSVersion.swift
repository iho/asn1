// Generated by ASN1.ERP.UNO Compiler, Copyright © 2023 Namdak Tonpa.
public struct CMSVersion : Hashable, Sendable, Comparable {
    @usableFromInline  var rawValue: Int
    @inlinable public static func < (lhs: CMSVersion, rhs: CMSVersion) -> Bool { lhs.rawValue < rhs.rawValue }
    @inlinable init(rawValue: Int) { self.rawValue = rawValue }
    public static let v0 = Self(rawValue: 0)
    public static let v1 = Self(rawValue: 1)
    public static let v2 = Self(rawValue: 2)
    public static let v3 = Self(rawValue: 3)
    public static let v4 = Self(rawValue: 4)
    public static let v5 = Self(rawValue: 5)
}
