// 
//  TETextBorder.swift 
//  TextEngineKit 
// 
//  Created by fengming on 2025/11/17. 
// 
//  文本边框：定义边框样式与绘制参数，用于装饰富文本。 
// 
import Foundation
import CoreGraphics

/// 文本边框
/// 用于创建文本周围的装饰性边框
public final class TETextBorder: NSObject, NSCopying, NSSecureCoding {
    
    // MARK: - 属性
    
    /// 边框颜色
    public var color: TEColor?
    
    /// 边框宽度
    public var width: CGFloat = 0
    
    /// 圆角半径
    public var cornerRadius: CGFloat = 0
    
    /// 内边距
    public var insets: TEUIEdgeInsets = TEUIEdgeInsets(top: 0, left: 0, bottom: 0, right: 0)
    
    /// 线条样式
    public var lineStyle: TELineStyle = .solid
    
    /// 填充颜色
    public var fillColor: TEColor?
    
    /// 阴影
    public var shadow: TETextShadow?
    
    /// 线帽样式
    public var lineCap: CGLineCap = .round
    
    /// 线条连接样式
    public var lineJoin: CGLineJoin = .round
    
    // MARK: - 初始化
    
    public override init() {
        super.init()
    }
    
    /// 便利初始化
    public convenience init(color: TEColor? = nil, width: CGFloat = 1, cornerRadius: CGFloat = 0) {
        self.init()
        self.color = color
        self.width = width
        self.cornerRadius = cornerRadius
    }
    
    // MARK: - NSCopying
    
    public func copy(with zone: NSZone? = nil) -> Any {
        let border = TETextBorder()
        border.color = color
        border.width = width
        border.cornerRadius = cornerRadius
        border.insets = insets
        border.lineStyle = lineStyle
        border.fillColor = fillColor
        border.shadow = shadow?.copy() as? TETextShadow
        border.lineCap = lineCap
        border.lineJoin = lineJoin
        return border
    }
    
    // MARK: - NSSecureCoding
    
    public static var supportsSecureCoding: Bool { return true }
    
    public func encode(with coder: NSCoder) {
        coder.encode(color, forKey: "color")
        coder.encode(width, forKey: "width")
        coder.encode(cornerRadius, forKey: "cornerRadius")
        #if canImport(UIKit)
        coder.encode(NSValue(uiEdgeInsets: insets), forKey: "insets")
        #elseif canImport(AppKit)
        coder.encode(NSValue(edgeInsets: insets), forKey: "insets")
        #endif
        coder.encode(lineStyle.rawValue, forKey: "lineStyle")
        coder.encode(fillColor, forKey: "fillColor")
        coder.encode(shadow, forKey: "shadow")
        coder.encode(lineCap.rawValue, forKey: "lineCap")
        coder.encode(lineJoin.rawValue, forKey: "lineJoin")
    }
    
    public required init?(coder: NSCoder) {
        super.init()
        color = coder.decodeObject(of: TEColor.self, forKey: "color")
        width = CGFloat(coder.decodeDouble(forKey: "width"))
        cornerRadius = CGFloat(coder.decodeDouble(forKey: "cornerRadius"))
        if let insetsValue = coder.decodeObject(of: NSValue.self, forKey: "insets") {
            #if canImport(UIKit)
            insets = insetsValue.uiEdgeInsetsValue
            #elseif canImport(AppKit)
            let edgeInsets = insetsValue.edgeInsetsValue
            insets = NSEdgeInsets(top: edgeInsets.top, left: edgeInsets.left, bottom: edgeInsets.bottom, right: edgeInsets.right)
            #endif
        }
        lineStyle = TELineStyle(rawValue: coder.decodeInteger(forKey: "lineStyle")) ?? .solid
        fillColor = coder.decodeObject(of: TEColor.self, forKey: "fillColor")
        shadow = coder.decodeObject(of: TETextShadow.self, forKey: "shadow")
        lineCap = CGLineCap(rawValue: Int32(coder.decodeInteger(forKey: "lineCap"))) ?? .round
        lineJoin = CGLineJoin(rawValue: Int32(coder.decodeInteger(forKey: "lineJoin"))) ?? .round
    }
    
    // MARK: - 公共方法
    
    /// 创建内边框
    /// - Returns: 内边框
    public static func innerBorder() -> TETextBorder {
        let border = TETextBorder()
        border.insets = TEUIEdgeInsets(top: -2, left: -2, bottom: -2, right: -2)
        return border
    }
    
    /// 创建外边框
    /// - Returns: 外边框
    public static func outerBorder() -> TETextBorder {
        let border = TETextBorder()
        border.insets = TEUIEdgeInsets(top: 2, left: 2, bottom: 2, right: 2)
        return border
    }
    
    /// 创建填充边框
    /// - Parameter color: 填充颜色
    /// - Returns: 填充边框
    public static func fillBorder(_ color: TEColor) -> TETextBorder {
        let border = TETextBorder()
        border.fillColor = color
        border.insets = TEUIEdgeInsets(top: -1, left: -1, bottom: -1, right: -1)
        return border
    }
    
    /// 创建圆角边框
    /// - Parameters:
    ///   - color: 边框颜色
    ///   - width: 边框宽度
    ///   - radius: 圆角半径
    /// - Returns: 圆角边框
    public static func roundedBorder(color: TEColor, width: CGFloat = 1, radius: CGFloat = 4) -> TETextBorder {
        let border = TETextBorder()
        border.color = color
        border.width = width
        border.cornerRadius = radius
        return border
    }
    
    /// 绘制边框
    /// - Parameters:
    ///   - context: 图形上下文
    ///   - rect: 绘制矩形
    ///   - lineOrigin: 行原点
    ///   - lineAscent: 行上升高度
    ///   - lineDescent: 行下降高度
    ///   - lineHeight: 行高
    func draw(in context: CGContext, rect: CGRect, lineOrigin: CGPoint, lineAscent: CGFloat, lineDescent: CGFloat, lineHeight: CGFloat) {
        guard width > 0 || fillColor != nil else { return }
        
        context.saveGState()
        
        // 应用阴影
        if let shadow = shadow {
            context.setShadow(offset: shadow.offset, blur: shadow.radius, color: shadow.color?.cgColor)
        }
        
        // 计算实际绘制矩形
        let drawRect = CGRect(
            x: rect.origin.x + insets.left,
            y: rect.origin.y + insets.top,
            width: rect.size.width - insets.left - insets.right,
            height: rect.size.height - insets.top - insets.bottom
        )
        let path = createPath(for: drawRect, lineAscent: lineAscent, lineDescent: lineDescent, lineHeight: lineHeight)
        
        // 填充背景
        if let fillColor = fillColor {
            context.setFillColor(fillColor.cgColor)
            context.addPath(path)
            context.fillPath()
        }
        
        // 绘制边框
        if width > 0, let color = color {
            context.setStrokeColor(color.cgColor)
            context.setLineWidth(width)
            context.setLineCap(lineCap)
            context.setLineJoin(lineJoin)
            
            // 应用线条样式
            applyLineStyle(to: context)
            
            context.addPath(path)
            context.strokePath()
        }
        
        context.restoreGState()
    }
    
    // MARK: - 私有方法
    
    /// 创建路径
    /// - Parameters:
    ///   - rect: 矩形
    ///   - lineAscent: 行上升高度
    ///   - lineDescent: 行下降高度
    ///   - lineHeight: 行高
    /// - Returns: 路径
    private func createPath(for rect: CGRect, lineAscent: CGFloat, lineDescent: CGFloat, lineHeight: CGFloat) -> CGPath {
        let path = CGMutablePath()
        
        if cornerRadius > 0 {
            path.addRoundedRect(in: rect, cornerWidth: cornerRadius, cornerHeight: cornerRadius)
        } else {
            path.addRect(rect)
        }
        
        return path
    }
    
    /// 应用线条样式
    /// - Parameter context: 图形上下文
    private func applyLineStyle(to context: CGContext) {
        switch lineStyle {
        case .solid:
            break // 默认实线
        case .dashed:
            context.setLineDash(phase: 0, lengths: [4, 2])
        case .dotted:
            context.setLineDash(phase: 0, lengths: [1, 1])
        case .dashDot:
            context.setLineDash(phase: 0, lengths: [4, 2, 1, 2])
        case .dashDotDot:
            context.setLineDash(phase: 0, lengths: [4, 2, 1, 2, 1, 2])
        }
    }
}

// MARK: - 线条样式

/// 线条样式
public enum TELineStyle: Int {
    case solid = 0      // 实线
    case dashed = 1     // 虚线
    case dotted = 2     // 点线
    case dashDot = 3    // 点划线
    case dashDotDot = 4 // 双点划线
}

// MARK: - 文本阴影

/// 文本阴影
public final class TETextShadow: NSObject, NSCopying, NSSecureCoding {
    
    // MARK: - 属性
    
    /// 阴影颜色
    public var color: TEColor?
    
    /// 阴影偏移
    public var offset: CGSize = .zero
    
    /// 阴影模糊半径
    public var radius: CGFloat = 0
    
    /// 内阴影
    public var isInnerShadow: Bool = false
    
    /// 透明度
    public var opacity: CGFloat = 1.0
    
    // MARK: - 初始化
    
    public override init() {
        super.init()
    }
    
    /// 便利初始化
    public convenience init(color: TEColor? = nil, offset: CGSize = .zero, radius: CGFloat = 0) {
        self.init()
        self.color = color
        self.offset = offset
        self.radius = radius
    }
    
    // MARK: - NSCopying
    
    public func copy(with zone: NSZone? = nil) -> Any {
        let shadow = TETextShadow()
        shadow.color = color
        shadow.offset = offset
        shadow.radius = radius
        shadow.isInnerShadow = isInnerShadow
        shadow.opacity = opacity
        return shadow
    }
    
    // MARK: - NSSecureCoding
    
    public static var supportsSecureCoding: Bool { return true }
    
    public func encode(with coder: NSCoder) {
        coder.encode(color, forKey: "color")
        #if canImport(UIKit)
        coder.encode(NSValue(cgSize: offset), forKey: "offset")
        #elseif canImport(AppKit)
        coder.encode(NSValue(size: offset), forKey: "offset")
        #endif
        coder.encode(radius, forKey: "radius")
        coder.encode(isInnerShadow, forKey: "isInnerShadow")
        coder.encode(opacity, forKey: "opacity")
    }
    
    public required init?(coder: NSCoder) {
        super.init()
        color = coder.decodeObject(of: TEColor.self, forKey: "color")
        if let offsetValue = coder.decodeObject(of: NSValue.self, forKey: "offset") {
            #if canImport(UIKit)
            offset = offsetValue.cgSizeValue
            #elseif canImport(AppKit)
            offset = offsetValue.sizeValue
            #endif
        }
        radius = CGFloat(coder.decodeDouble(forKey: "radius"))
        isInnerShadow = coder.decodeBool(forKey: "isInnerShadow")
        opacity = CGFloat(coder.decodeDouble(forKey: "opacity"))
    }
    
    // MARK: - 公共方法
    
    /// 创建简单阴影
    /// - Parameters:
    ///   - color: 阴影颜色
    ///   - offset: 阴影偏移
    ///   - radius: 阴影半径
    /// - Returns: 阴影对象
    public static func shadow(color: TEColor, offset: CGSize, radius: CGFloat) -> TETextShadow {
        return TETextShadow(color: color, offset: offset, radius: radius)
    }
    
    /// 创建内阴影
    /// - Parameters:
    ///   - color: 阴影颜色
    ///   - offset: 阴影偏移
    ///   - radius: 阴影半径
    /// - Returns: 内阴影对象
    public static func innerShadow(color: TEColor, offset: CGSize, radius: CGFloat) -> TETextShadow {
        let shadow = TETextShadow(color: color, offset: offset, radius: radius)
        shadow.isInnerShadow = true
        return shadow
    }
    
    /// 创建模糊阴影
    /// - Parameters:
    ///   - color: 阴影颜色
    ///   - radius: 模糊半径
    /// - Returns: 模糊阴影对象
    public static func blurShadow(color: TEColor, radius: CGFloat) -> TETextShadow {
        return TETextShadow(color: color, offset: .zero, radius: radius)
    }
}
