// 
//  TEPlatform.swift 
//  TextEngineKit 
// 
//  Created by fengming on 2025/11/17. 
// 
//  平台抽象：统一跨平台类型别名与图形渲染封装，提供屏幕与系统信息。 
// 
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
public func TEGraphicsGetCurrentContext() -> CGContext? {
    #if canImport(UIKit)
    return UIGraphicsGetCurrentContext()
    #elseif canImport(AppKit)
    return NSGraphicsContext.current?.cgContext
    #endif
}
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
public typealias TETapGestureRecognizer = UITapGestureRecognizer
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

// 移除平台分支中的重复定义，统一在文件后部提供跨平台实现

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

/// 获取当前图形上下文（跨平台）
public func TEGetCurrentGraphicsContext() -> CGContext? {
    #if canImport(UIKit)
    return UIGraphicsGetCurrentContext()
    #elseif canImport(AppKit)
    return NSGraphicsContext.current?.cgContext
    #else
    return nil
    #endif
}

/// 图形渲染器协议
///
/// `TEGraphicsRendererProtocol` 提供了一个跨平台的图形渲染抽象，
/// 统一了 iOS (UIGraphicsImageRenderer) 和 macOS (NSGraphicsRenderer) 的渲染接口。
///
/// 主要用途：
/// - 在不同平台上提供一致的渲染接口
/// - 支持自定义渲染格式和配置
/// - 实现平台无关的图形渲染逻辑
///
/// 使用示例：
/// ```swift
/// // 创建渲染器格式
/// let format = TEPlatform.makeRendererFormat(
///     scale: 2.0,
///     opaque: false,
///     extendedRange: true
/// )
/// 
/// // 创建渲染器
/// let renderer = TEPlatform.createGraphicsRenderer(
///     size: CGSize(width: 100, height: 100),
///     format: format
/// )
/// 
/// // 执行渲染
/// let image = renderer.render { context in
///     // 绘制操作
///     context.setFillColor(UIColor.red.cgColor)
///     context.fill(CGRect(origin: .zero, size: CGSize(width: 100, height: 100)))
/// }
/// ```
public protocol TEGraphicsRendererProtocol {
    /// 执行渲染操作
    ///
    /// 在指定的图形上下文中执行绘制操作，并返回渲染结果。
    ///
    /// - Parameter actions: 包含绘制操作的闭包，接收 `CGContext` 参数
    /// - Returns: 渲染后的图像对象
    func render(actions: (CGContext) -> Void) -> TEImage
}

/// 图形渲染器格式协议
///
/// `TEGraphicsRendererFormatProtocol` 定义了跨平台的渲染器格式接口，
/// 提供了统一的格式配置方式。
///
/// 主要特性：
/// - 统一的缩放比例设置
/// - 透明度控制
/// - 扩展范围支持
///
/// 平台差异：
/// - iOS: 对应 `UIGraphicsImageRendererFormat`
/// - macOS: 对应 `NSGraphicsRendererFormat`
///
/// 使用示例：
/// ```swift
/// // 创建格式
/// var format = TEPlatform.makeRendererFormat(
///     scale: UIScreen.main.scale,
///     opaque: false,
///     extendedRange: true
/// )
/// 
/// // 修改格式属性
/// format.scale = 3.0  // 高 DPI 渲染
/// format.opaque = true  // 不透明背景
/// format.prefersExtendedRange = true  // 支持广色域
/// ```
public protocol TEGraphicsRendererFormatProtocol {
    /// 渲染缩放比例
    ///
    /// 控制渲染内容相对于逻辑像素的缩放比例。通常设置为屏幕的 `scale` 属性，
    /// 以获得最佳的显示效果。较高的值会产生更清晰的图像，但会增加内存使用。
    var scale: CGFloat { get set }
    
    /// 是否不透明
    ///
    /// 当设置为 `true` 时，渲染器会优化不透明内容的渲染性能。
    /// 当设置为 `false` 时，支持透明度，但性能略低。
    var opaque: Bool { get set }
    
    /// 是否偏好扩展范围
    ///
    /// 当设置为 `true` 时，渲染器会启用广色域支持（如果硬件支持）。
    /// 适用于需要显示高动态范围内容的场景。
    var prefersExtendedRange: Bool { get set }
}

#if canImport(UIKit)
extension UIGraphicsImageRenderer: TEGraphicsRendererProtocol {
    public func render(actions: (CGContext) -> Void) -> TEImage {
        return self.image { context in
            actions(context.cgContext)
        }
    }
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

    public static func cgImage(from image: TEImage) -> CGImage? {
        #if canImport(UIKit)
        return image.cgImage
        #elseif canImport(AppKit)
        var rect = CGRect(origin: .zero, size: image.teSize)
        return image.cgImage(forProposedRect: &rect, context: nil, hints: nil)
        #endif
    }
}

public extension TEPlatform {
    static func makeRendererFormat(scale: CGFloat, opaque: Bool, extendedRange: Bool) -> any TEGraphicsRendererFormatProtocol {
        #if canImport(UIKit)
        let format = UIGraphicsImageRendererFormat()
        format.scale = scale
        format.opaque = opaque
        format.prefersExtendedRange = extendedRange
        return format
        #elseif canImport(AppKit)
        let format = TEGraphicsImageRendererFormat()
        format.scale = scale
        format.opaque = opaque
        return format
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
        return self.size
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
