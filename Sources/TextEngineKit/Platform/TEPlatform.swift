import Foundation
import CoreGraphics

#if canImport(UIKit)
import UIKit
public typealias TEColor = UIColor
public typealias TEImage = UIImage
public typealias TEFont = UIFont
public typealias TEScreen = UIScreen
public typealias TEGraphicsImageRenderer = UIGraphicsImageRenderer
public typealias TEGraphicsImageRendererFormat = UIGraphicsImageRendererFormat
public typealias TEUnderlineStyle = NSUnderlineStyle
public typealias TEMutableParagraphStyle = NSMutableParagraphStyle
public typealias TEView = UIView
public typealias TEGraphicsGetCurrentContext = UIGraphicsGetCurrentContext
public typealias TENSLayoutConstraint = NSLayoutConstraint
public typealias TEUIView = UIView
public typealias TECALayer = CALayer
public typealias TEUIBezierPath = UIBezierPath
public typealias TEUIViewContentMode = UIView.ContentMode

/// 跨平台内容模式枚举
public enum TEContentMode: Int {
    case scaleToFill = 0
    case scaleAspectFit = 1
    case scaleAspectFill = 2
    case center = 3
    case top = 4
    case bottom = 5
    case left = 6
    case right = 7
    case topLeft = 8
    case topRight = 9
    case bottomLeft = 10
    case bottomRight = 11
}
public typealias TEUIEdgeInsets = UIEdgeInsets
public typealias TEGestureRecognizer = UIGestureRecognizer
public typealias TELongPressGestureRecognizer = UILongPressGestureRecognizer
#elseif canImport(AppKit)
import AppKit
public typealias TEColor = NSColor
public typealias TEImage = NSImage
public typealias TEFont = NSFont
public typealias TEScreen = NSScreen
// AppKit doesn't have NSGraphicsImageRenderer, so we'll create our own
public class TEGraphicsImageRenderer: TEGraphicsRendererProtocol {
    public typealias RendererFormat = TEGraphicsImageRendererFormat
    
    private let size: CGSize
    private let rendererFormat: TEGraphicsImageRendererFormat
    
    public init(size: CGSize, format: TEGraphicsImageRendererFormat) {
        self.size = size
        self.rendererFormat = format
    }
    
    public var format: TEGraphicsImageRendererFormat {
        return rendererFormat
    }
    
    public func render(actions: (CGContext) -> Void) -> TEImage {
        let image = NSImage(size: size)
        image.lockFocus()
        if let context = NSGraphicsContext.current?.cgContext {
            actions(context)
        }
        image.unlockFocus()
        return image
    }
}

public class TEGraphicsImageRendererFormat: TEGraphicsRendererFormatProtocol {
    public var scale: CGFloat = 1.0
    public var opaque: Bool = true
    public var prefersExtendedRange: Bool = false
}
public typealias TEUnderlineStyle = NSUnderlineStyle
public typealias TEMutableParagraphStyle = NSMutableParagraphStyle
public typealias TEView = NSView
public func TEGraphicsGetCurrentContext() -> CGContext? {
    return NSGraphicsContext.current?.cgContext
}
public typealias TENSLayoutConstraint = NSLayoutConstraint
public typealias TEUIView = NSView
public typealias TECALayer = CALayer
public typealias TEUIBezierPath = NSBezierPath
public typealias TEUIViewContentMode = Int

/// 跨平台内容模式枚举
public enum TEContentMode: Int {
    case scaleToFill = 0
    case scaleAspectFit = 1
    case scaleAspectFill = 2
    case center = 3
    case top = 4
    case bottom = 5
    case left = 6
    case right = 7
    case topLeft = 8
    case topRight = 9
    case bottomLeft = 10
    case bottomRight = 11
}
public typealias TEUIEdgeInsets = NSEdgeInsets
public typealias TEGestureRecognizer = NSGestureRecognizer
public typealias TELongPressGestureRecognizer = NSPressGestureRecognizer

public func TEGetCurrentGraphicsContext() -> CGContext? {
    #if canImport(UIKit)
    return UIGraphicsGetCurrentContext()
    #elseif canImport(AppKit)
    return NSGraphicsContext.current?.cgContext
    #endif
}

public func TEPlatformFormat() -> any TEGraphicsRendererFormatProtocol {
    #if canImport(UIKit)
    let format = UIGraphicsImageRendererFormat()
    format.scale = TEPlatform.screenScale
    format.opaque = true
    format.prefersExtendedRange = true
    return format
    #elseif canImport(AppKit)
    let format = TEGraphicsImageRendererFormat()
    format.scale = TEPlatform.screenScale
    format.opaque = true
    return format
    #endif
}
#endif

public protocol TEGraphicsRendererProtocol {
    associatedtype RendererFormat
    func render(actions: (CGContext) -> Void) -> TEImage
    var format: RendererFormat { get }
}

public protocol TEGraphicsRendererFormatProtocol {
    var scale: CGFloat { get set }
    var opaque: Bool { get set }
    var prefersExtendedRange: Bool { get set }
}

#if canImport(UIKit)
extension UIGraphicsImageRenderer: TEGraphicsRendererProtocol {
    public typealias RendererFormat = UIGraphicsImageRendererFormat
}

extension UIGraphicsImageRendererFormat: TEGraphicsRendererFormatProtocol {}
#endif

public struct TEPlatform {
    public static var isMac: Bool {
        #if os(macOS)
        return true
        #else
        return false
        #endif
    }
    
    public static var isIOS: Bool {
        #if os(iOS)
        return true
        #else
        return false
        #endif
    }
    
    public static var current: String {
        #if os(macOS)
        return "macOS"
        #elseif os(iOS)
        return "iOS"
        #elseif os(tvOS)
        return "tvOS"
        #elseif os(watchOS)
        return "watchOS"
        #else
        return "Unknown"
        #endif
    }
    
    public static var systemVersion: String {
        #if canImport(UIKit)
        return UIDevice.current.systemVersion
        #elseif canImport(AppKit)
        return ProcessInfo.processInfo.operatingSystemVersionString
        #else
        return "Unknown"
        #endif
    }
    
    public static var isSimulator: Bool {
        #if targetEnvironment(simulator)
        return true
        #else
        return false
        #endif
    }
    
    public static var screenScale: CGFloat {
        #if canImport(UIKit)
        return UIScreen.main.scale
        #elseif canImport(AppKit)
        return NSScreen.main?.backingScaleFactor ?? 1.0
        #else
        return 1.0
        #endif
    }
    
    public static var screenBounds: CGRect {
        #if canImport(UIKit)
        return UIScreen.main.bounds
        #elseif canImport(AppKit)
        if let screen = NSScreen.main {
            return screen.frame
        }
        return CGRect(x: 0, y: 0, width: 800, height: 600)
        #else
        return CGRect(x: 0, y: 0, width: 800, height: 600)
        #endif
    }
    
    public static func createGraphicsRenderer(size: CGSize, format: TEGraphicsRendererFormatProtocol) -> any TEGraphicsRendererProtocol {
        #if canImport(UIKit)
        let uiFormat = UIGraphicsImageRendererFormat()
        uiFormat.scale = format.scale
        uiFormat.opaque = format.opaque
        uiFormat.prefersExtendedRange = format.prefersExtendedRange
        return UIGraphicsImageRenderer(size: size, format: uiFormat)
        #elseif canImport(AppKit)
        let nsFormat = TEGraphicsImageRendererFormat()
        nsFormat.scale = format.scale
        nsFormat.opaque = format.opaque
        return TEGraphicsImageRenderer(size: size, format: nsFormat)
        #else
        fatalError("Unsupported platform")
        #endif
    }
}

public extension TEColor {
    static func dynamicColor(light: TEColor, dark: TEColor) -> TEColor {
        #if canImport(UIKit)
        return UIColor { traitCollection in
            traitCollection.userInterfaceStyle == .dark ? dark : light
        }
        #elseif canImport(AppKit)
        return NSColor(name: nil) { appearance in
            if appearance.bestMatch(from: [.darkAqua, .vibrantDark]) != nil {
                return dark
            }
            return light
        }
        #endif
    }
    
    static var systemGray: TEColor {
        #if canImport(UIKit)
        return UIColor.systemGray
        #elseif canImport(AppKit)
        return NSColor.controlBackgroundColor  // Use a different color to avoid recursion
        #endif
    }
    
    static var systemGray6: TEColor {
        #if canImport(UIKit)
        return .systemGray6
        #elseif canImport(AppKit)
        return .quaternaryLabelColor
        #endif
    }
    
    static var systemBlue: TEColor {
        #if canImport(UIKit)
        return UIColor.systemBlue
        #elseif canImport(AppKit)
        return NSColor.controlAccentColor  // Use the correct AppKit color
        #endif
    }
    
    static var systemRed: TEColor {
        #if canImport(UIKit)
        return UIColor.systemRed
        #elseif canImport(AppKit)
        return NSColor.red
        #endif
    }
    
    static var label: TEColor {
        #if canImport(UIKit)
        return .label
        #elseif canImport(AppKit)
        return .labelColor
        #endif
    }
    
    static var systemBackground: TEColor {
        #if canImport(UIKit)
        return .systemBackground
        #elseif canImport(AppKit)
        return .windowBackgroundColor
        #endif
    }
}

public extension TEImage {
    var teSize: CGSize {
        #if canImport(UIKit)
        return (self as! UIImage).size
        #elseif canImport(AppKit)
        return (self as! NSImage).size
        #endif
    }
    
    var teScale: CGFloat {
        #if canImport(UIKit)
        return (self as! UIImage).scale
        #elseif canImport(AppKit)
        return 1.0
        #endif
    }
}

public extension TEFont {
    static func systemFont(ofSize size: CGFloat, weight: FontWeight) -> TEFont {
        #if canImport(UIKit)
        return UIFont.systemFont(ofSize: size, weight: weight)
        #elseif canImport(AppKit)
        return NSFont.systemFont(ofSize: size)
        #endif
    }
    
    static func boldSystemFont(ofSize size: CGFloat) -> TEFont {
        #if canImport(UIKit)
        return UIFont.boldSystemFont(ofSize: size)
        #elseif canImport(AppKit)
        let font = NSFont.systemFont(ofSize: size)
        return NSFontManager.shared.convert(font, toHaveTrait: .boldFontMask)
        #endif
    }
    
    static func italicSystemFont(ofSize size: CGFloat) -> TEFont {
        #if canImport(UIKit)
        return UIFont.italicSystemFont(ofSize: size)
        #elseif canImport(AppKit)
        return NSFontManager.shared.convert(NSFont.systemFont(ofSize: size), toHaveTrait: .italicFontMask)
        #endif
    }
}

#if canImport(UIKit)
public typealias FontWeight = UIFont.Weight
#elseif canImport(AppKit)
public typealias FontWeight = NSFont.Weight
#endif