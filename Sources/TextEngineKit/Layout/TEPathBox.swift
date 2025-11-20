import Foundation
import CoreGraphics

public final class TEPathBox: NSObject, NSSecureCoding {
public class var supportsSecureCoding: Bool { true }
    public let rect: CGRect
    public init(rect: CGRect) { self.rect = rect }
    public func encode(with coder: NSCoder) {
        coder.encode(Double(rect.origin.x), forKey: "x")
        coder.encode(Double(rect.origin.y), forKey: "y")
        coder.encode(Double(rect.size.width), forKey: "w")
        coder.encode(Double(rect.size.height), forKey: "h")
    }
    public required init?(coder: NSCoder) {
        let x = coder.decodeDouble(forKey: "x")
        let y = coder.decodeDouble(forKey: "y")
        let w = coder.decodeDouble(forKey: "w")
        let h = coder.decodeDouble(forKey: "h")
        self.rect = CGRect(x: CGFloat(x), y: CGFloat(y), width: CGFloat(w), height: CGFloat(h))
        super.init()
    }
}
