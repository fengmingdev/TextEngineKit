import Foundation

public final class TETextBinding: NSObject, NSSecureCoding {
    public static var supportsSecureCoding: Bool { true }
    public let deleteTogether: Bool
    public init(deleteTogether: Bool = true) { self.deleteTogether = deleteTogether }
    public func encode(with coder: NSCoder) { coder.encode(deleteTogether, forKey: "deleteTogether") }
    public required init?(coder: NSCoder) { self.deleteTogether = coder.decodeBool(forKey: "deleteTogether") }
}

public final class TETextBackedString: NSObject, NSSecureCoding {
    public static var supportsSecureCoding: Bool { true }
    public let string: String
    public init(string: String) { self.string = string }
    public func encode(with coder: NSCoder) { coder.encode(string, forKey: "string") }
    public required init?(coder: NSCoder) { guard let s = coder.decodeObject(of: NSString.self, forKey: "string") as String? else { return nil }; self.string = s }
}