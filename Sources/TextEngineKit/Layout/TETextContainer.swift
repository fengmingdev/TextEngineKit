// 
//  TETextContainer.swift 
//  TextEngineKit 
// 
//  Created by fengming on 2025/11/17. 
// 
//  文本容器：管理布局尺寸、路径与排除路径，支持复制与安全归档。 
// 
import Foundation
import CoreText
import CoreGraphics
#if canImport(UIKit)
import UIKit
#elseif canImport(AppKit)
import AppKit
#endif

/// 文本容器
/// 管理文本布局的容器，支持自定义路径和排除路径
@objc(TETextContainer)
public final class TETextContainer: NSObject, NSCopying, NSSecureCoding {
    public override class func classForKeyedUnarchiver() -> AnyClass { TETextContainer.self }
    
    // MARK: - 属性
    
    /// 容器尺寸
    public var size: CGSize = .zero
    
    /// 内边距
    public var insets: TEUIEdgeInsets = TEUIEdgeInsets(top: 0, left: 0, bottom: 0, right: 0)
    
    /// 文本布局路径
    /// 定义文本可以布局的区域，默认为矩形
    public var path: CGPath? {
        didSet {
            updatePathBounds()
        }
    }
    
    /// 排除路径数组
    /// 定义文本不能布局的区域（如图片、按钮等）
    public var exclusionPaths: [CGPath] = [] {
        didSet {
            updateExclusionPathBounds()
        }
    }
    
    /// 最大行数
    public var maximumNumberOfLines: Int = 0
    
    /// 行截断类型
    public var lineBreakMode: CTLineBreakMode = .byWordWrapping
    
    /// 是否允许字体回退
    public var allowsFontFallback: Bool = true
    
    /// 是否允许非连续布局
    public var allowsNonContiguousLayout: Bool = true
    
    /// 行间距
    public var lineSpacing: CGFloat = 0
    
    /// 段落间距
    public var paragraphSpacing: CGFloat = 0
    
    /// 文本对齐方式
    public var textAlignment: CTTextAlignment = .natural
    
    /// 文本方向
    public var baseWritingDirection: CTWritingDirection = .natural
    
    /// 路径边界缓存
    private var pathBoundsCache: CGRect = .zero
    
    /// 排除路径边界缓存
    private var exclusionPathBoundsCache: [CGRect] = []
    
    /// 路径边界（只读）
    public var pathBounds: CGRect {
        if !isCacheValid {
            updatePathBounds()
            updateExclusionPathBounds()
            isCacheValid = true
        }
        return pathBoundsCache
    }
    
    /// 排除路径边界（只读）
    public var exclusionPathBounds: CGRect {
        if !isCacheValid {
            updatePathBounds()
            updateExclusionPathBounds()
            isCacheValid = true
        }
        // 返回所有排除路径的并集边界
        return exclusionPathBoundsCache.reduce(CGRect.null) { result, rect in
            result.isNull ? rect : result.union(rect)
        }
    }
    
    /// 缓存是否有效
    private var isCacheValid: Bool = false
    
    // MARK: - 初始化
    
    public override init() {
        super.init()
    }
    
    /// 便利初始化
    public convenience init(size: CGSize) {
        self.init()
        self.size = size
    }
    
    /// 使用路径初始化
    public convenience init(path: CGPath) {
        self.init()
        self.path = path
        updatePathBounds()
    }
    
    // MARK: - NSCopying
    
    public func copy(with zone: NSZone? = nil) -> Any {
        let container = TETextContainer()
        container.size = size
        container.insets = insets
        container.path = path?.copy()
        container.exclusionPaths = exclusionPaths.compactMap { $0.copy() }
        container.maximumNumberOfLines = maximumNumberOfLines
        container.lineBreakMode = lineBreakMode
        container.allowsFontFallback = allowsFontFallback
        container.allowsNonContiguousLayout = allowsNonContiguousLayout
        container.lineSpacing = lineSpacing
        container.paragraphSpacing = paragraphSpacing
        container.textAlignment = textAlignment
        container.baseWritingDirection = baseWritingDirection
        return container
    }
    
    // MARK: - NSSecureCoding
    
public class var supportsSecureCoding: Bool { true }
    
    public func encode(with coder: NSCoder) {
        coder.encode(Double(size.width), forKey: "size_w")
        coder.encode(Double(size.height), forKey: "size_h")
        coder.encode(Double(insets.top), forKey: "insets_top")
        coder.encode(Double(insets.left), forKey: "insets_left")
        coder.encode(Double(insets.bottom), forKey: "insets_bottom")
        coder.encode(Double(insets.right), forKey: "insets_right")
        
        let p = (path ?? createDefaultPath()).boundingBox
        coder.encode(Double(p.origin.x), forKey: "path_x")
        coder.encode(Double(p.origin.y), forKey: "path_y")
        coder.encode(Double(p.size.width), forKey: "path_w")
        coder.encode(Double(p.size.height), forKey: "path_h")
        
        coder.encode(exclusionPaths.count, forKey: "ex_count")
        for (i, ex) in exclusionPaths.enumerated() {
            let b = ex.boundingBox
            coder.encode(Double(b.origin.x), forKey: "ex_\(i)_x")
            coder.encode(Double(b.origin.y), forKey: "ex_\(i)_y")
            coder.encode(Double(b.size.width), forKey: "ex_\(i)_w")
            coder.encode(Double(b.size.height), forKey: "ex_\(i)_h")
        }
        
        coder.encode(maximumNumberOfLines, forKey: "maximumNumberOfLines")
        coder.encode(lineBreakMode.rawValue, forKey: "lineBreakMode")
        coder.encode(allowsFontFallback, forKey: "allowsFontFallback")
        coder.encode(allowsNonContiguousLayout, forKey: "allowsNonContiguousLayout")
        coder.encode(lineSpacing, forKey: "lineSpacing")
        coder.encode(paragraphSpacing, forKey: "paragraphSpacing")
        coder.encode(textAlignment.rawValue, forKey: "textAlignment")
        coder.encode(baseWritingDirection.rawValue, forKey: "baseWritingDirection")
    }
    
    public required init?(coder: NSCoder) {
        super.init()
        
        let sw = CGFloat(coder.decodeDouble(forKey: "size_w"))
        let sh = CGFloat(coder.decodeDouble(forKey: "size_h"))
        if sw > 0 || sh > 0 { size = CGSize(width: sw, height: sh) }
        let top = CGFloat(coder.decodeDouble(forKey: "insets_top"))
        let left = CGFloat(coder.decodeDouble(forKey: "insets_left"))
        let bottom = CGFloat(coder.decodeDouble(forKey: "insets_bottom"))
        let right = CGFloat(coder.decodeDouble(forKey: "insets_right"))
        insets = TEUIEdgeInsets(top: top, left: left, bottom: bottom, right: right)
        
        let px = CGFloat(coder.decodeDouble(forKey: "path_x"))
        let py = CGFloat(coder.decodeDouble(forKey: "path_y"))
        let pw = CGFloat(coder.decodeDouble(forKey: "path_w"))
        let ph = CGFloat(coder.decodeDouble(forKey: "path_h"))
        if pw > 0 && ph > 0 {
            self.path = createPathFromRect(CGRect(x: px, y: py, width: pw, height: ph))
        } else {
            self.path = createDefaultPath()
        }
        
        exclusionPaths = []
        let exCount = coder.decodeInteger(forKey: "ex_count")
        for i in 0..<exCount {
            let exx = CGFloat(coder.decodeDouble(forKey: "ex_\(i)_x"))
            let exy = CGFloat(coder.decodeDouble(forKey: "ex_\(i)_y"))
            let exw = CGFloat(coder.decodeDouble(forKey: "ex_\(i)_w"))
            let exh = CGFloat(coder.decodeDouble(forKey: "ex_\(i)_h"))
            if exw > 0 && exh > 0 {
                exclusionPaths.append(createPathFromRect(CGRect(x: exx, y: exy, width: exw, height: exh)))
            }
        }
        
        maximumNumberOfLines = coder.decodeInteger(forKey: "maximumNumberOfLines")
        lineBreakMode = CTLineBreakMode(rawValue: UInt8(coder.decodeInteger(forKey: "lineBreakMode"))) ?? .byWordWrapping
        allowsFontFallback = coder.decodeBool(forKey: "allowsFontFallback")
        allowsNonContiguousLayout = coder.decodeBool(forKey: "allowsNonContiguousLayout")
        lineSpacing = CGFloat(coder.decodeDouble(forKey: "lineSpacing"))
        paragraphSpacing = CGFloat(coder.decodeDouble(forKey: "paragraphSpacing"))
        textAlignment = CTTextAlignment(rawValue: UInt8(coder.decodeInteger(forKey: "textAlignment"))) ?? .natural
        baseWritingDirection = CTWritingDirection(rawValue: Int8(coder.decodeInteger(forKey: "baseWritingDirection"))) ?? .natural
        
        updatePathBounds()
        updateExclusionPathBounds()
    }

    // MARK: - Secure Unarchiving Convenience
    public class func unarchiveSecureManual(from data: Data) -> TETextContainer? {
        do {
            let unarchiver = try NSKeyedUnarchiver(forReadingFrom: data)
            unarchiver.requiresSecureCoding = true
            let obj = unarchiver.decodeObject(of: TETextContainer.self, forKey: NSKeyedArchiveRootObjectKey)
            unarchiver.finishDecoding()
            return obj
        } catch {
            return nil
        }
    }
    
    // MARK: - 公共方法
    
    /// 获取实际的布局路径
    /// 考虑内边距后的路径
    public func effectivePath() -> CGPath {
        guard let path = path else {
            return createDefaultPath()
        }
        
        // 如果内边距为0，直接返回原路径
        if insets.top == 0 && insets.left == 0 && insets.bottom == 0 && insets.right == 0 {
            return path
        }
        
        // 应用内边距变换
        let bounds = pathBoundsCache
        let insetBounds = CGRect(
            x: bounds.origin.x + insets.left,
            y: bounds.origin.y + insets.top,
            width: bounds.size.width - insets.left - insets.right,
            height: bounds.size.height - insets.top - insets.bottom
        )
        
        return createPathFromRect(insetBounds)
    }
    
    /// 获取排除路径的边界矩形
    /// - Parameter path: 排除路径
    /// - Returns: 边界矩形
    public func boundingRect(for exclusionPath: CGPath) -> CGRect {
        return exclusionPath.boundingBox
    }
    
    /// 检查点是否在布局路径内
    /// - Parameter point: 要检查的点
    /// - Returns: 是否在路径内
    public func contains(_ point: CGPoint) -> Bool {
        guard let path = effectivePath() as CGPath? else { return false }
        
        // 检查是否在主路径内
        var isInMainPath = path.contains(point)
        
        // 检查是否在排除路径内
        for exclusionPath in exclusionPaths {
            if exclusionPath.contains(point) {
                isInMainPath = false
                break
            }
        }
        
        return isInMainPath
    }
    
    /// 检查矩形是否与布局路径相交
    /// - Parameter rect: 要检查的矩形
    /// - Returns: 是否相交
    public func intersects(_ rect: CGRect) -> Bool {
        guard let path = effectivePath() as CGPath? else { return false }
        
        // 检查是否与主路径相交
        var intersectsMainPath = path.boundingBox.intersects(rect)
        
        // 检查是否与排除路径相交
        for exclusionPath in exclusionPaths {
            if exclusionPath.boundingBox.intersects(rect) {
                intersectsMainPath = false
                break
            }
        }
        
        return intersectsMainPath
    }
    
    /// 添加排除路径
    /// - Parameter path: 排除路径
    public func addExclusionPath(_ path: CGPath) {
        exclusionPaths.append(path)
        updateExclusionPathBounds()
        invalidateCache()
    }
    
    /// 移除排除路径
    /// - Parameter path: 要移除的排除路径
    public func removeExclusionPath(_ path: CGPath) {
        exclusionPaths.removeAll { $0 == path }
        updateExclusionPathBounds()
        invalidateCache()
    }
    
    /// 清除所有排除路径
    public func clearExclusionPaths() {
        exclusionPaths.removeAll()
        exclusionPathBoundsCache.removeAll()
        invalidateCache()
    }
    
    /// 设置圆形路径
    /// - Parameters:
    ///   - center: 圆心
    ///   - radius: 半径
    public func setCircularPath(center: CGPoint, radius: CGFloat) {
        let path = CGMutablePath()
        path.addEllipse(in: CGRect(x: center.x - radius, y: center.y - radius, width: radius * 2, height: radius * 2))
        self.path = path
        TETextEngine.shared.logDebug("设置圆形路径: center=\(center), radius=\(radius)", category: "container")
    }
    
    /// 设置圆角矩形路径
    /// - Parameters:
    ///   - rect: 矩形
    ///   - cornerRadius: 圆角半径
    public func setRoundedRectPath(_ rect: CGRect, cornerRadius: CGFloat) {
        let path = CGMutablePath()
        path.addRoundedRect(in: rect, cornerWidth: cornerRadius, cornerHeight: cornerRadius)
        self.path = path
        TETextEngine.shared.logDebug("设置圆角矩形路径: rect=\(rect), cornerRadius=\(cornerRadius)", category: "container")
    }
    
    /// 设置贝塞尔曲线路径
    /// - Parameter bezierPath: 贝塞尔路径
    #if canImport(UIKit)
    public func setBezierPath(_ bezierPath: UIBezierPath) {
        self.path = bezierPath.cgPath
        TETextEngine.shared.logDebug("设置贝塞尔曲线路径", category: "container")
    }
    #elseif canImport(AppKit)
    @available(macOS 14.0, *)
    public func setBezierPath(_ bezierPath: NSBezierPath) {
        self.path = bezierPath.cgPath
        TETextEngine.shared.logDebug("设置贝塞尔曲线路径", category: "container")
    }
    
    // macOS 14.0 以下版本的兼容方法
    @available(macOS, deprecated: 14.0, message: "Use setBezierPath with cgPath property")
    public func setBezierPathLegacy(_ bezierPath: NSBezierPath) {
        // 将 NSBezierPath 转换为 CGPath（macOS 14.0 以下版本）
        let path = CGMutablePath()
        var points = [CGPoint](repeating: .zero, count: 3)
        
        for i in 0..<bezierPath.elementCount {
            let type = bezierPath.element(at: i, associatedPoints: &points)
            switch type {
            case .moveTo:
                path.move(to: points[0])
            case .lineTo:
                path.addLine(to: points[0])
            case .curveTo:
                path.addCurve(to: points[2], control1: points[0], control2: points[1])
            case .cubicCurveTo:
                path.addCurve(to: points[3], control1: points[0], control2: points[1])
            case .quadraticCurveTo:
                path.addQuadCurve(to: points[2], control: points[0])
            case .closePath:
                path.closeSubpath()
            @unknown default:
                break
            }
        }
        
        self.path = path
        TETextEngine.shared.logDebug("设置贝塞尔曲线路径（兼容模式）", category: "container")
    }
    #endif
    
    /// 重置为默认矩形路径
    public func resetToDefaultPath() {
        self.path = nil
        clearExclusionPaths()
        TETextEngine.shared.logDebug("重置为默认矩形路径", category: "container")
    }
    
    /// 获取布局统计信息
    public func getStatistics() -> TETextContainerStatistics {
        return TETextContainerStatistics(
            pathComplexity: calculatePathComplexity(),
            exclusionPathCount: exclusionPaths.count,
            effectiveBounds: effectivePath().boundingBox
        )
    }
    
    // MARK: - 私有方法
    
    /// 设置默认路径
    private func setupDefaultPath() {
        self.path = nil
        isCacheValid = true
    }
    
    /// 创建默认路径
    private func createDefaultPath() -> CGPath {
        let path = CGMutablePath()
        let effectiveSize = CGSize(
            width: size.width - insets.left - insets.right,
            height: size.height - insets.top - insets.bottom
        )
        path.addRect(CGRect(origin: .zero, size: effectiveSize))
        return path
    }
    
    /// 从矩形创建路径
    private func createPathFromRect(_ rect: CGRect) -> CGPath {
        let path = CGMutablePath()
        path.addRect(rect)
        return path
    }
    
    /// 更新路径边界
    private func updatePathBounds() {
        pathBoundsCache = path?.boundingBox ?? CGRect(origin: .zero, size: size)
        isCacheValid = false
    }
    
    /// 更新排除路径边界
    private func updateExclusionPathBounds() {
        exclusionPathBoundsCache = exclusionPaths.map { $0.boundingBox }
        isCacheValid = false
    }
    
    /// 使缓存失效
    private func invalidateCache() {
        isCacheValid = false
    }
    
    /// 计算路径复杂度
    private func calculatePathComplexity() -> Int {
        guard let path = path else { return 0 }
        
        // 简单的复杂度计算：基于路径元素数量
        var complexity = 0
        path.applyWithBlock { element in
            complexity += 1
        }
        
        return complexity
    }

    // 旧版序列化逻辑已移除，统一使用边界矩形编码，确保 SecureCoding 白名单
}

// MARK: - 文本容器统计信息

/// 文本容器统计信息
public struct TETextContainerStatistics {
    /// 路径复杂度（元素数量）
    public let pathComplexity: Int
    
    /// 排除路径数量
    public let exclusionPathCount: Int
    
    /// 有效边界矩形
    public let effectiveBounds: CGRect
    
    /// 描述信息
    public var description: String {
        let bounds = effectiveBounds
        return """
        文本容器统计:
        - 路径复杂度: \(pathComplexity) 个元素
        - 排除路径数量: \(exclusionPathCount)
        - 有效边界: origin(\(bounds.origin.x), \(bounds.origin.y)) size(\(bounds.size.width), \(bounds.size.height))
        """
    }
}

// MARK: - CGPath 扩展

extension CGPath {
    /// 检查点是否在路径内
    func contains(_ point: CGPoint) -> Bool {
        // 使用 Core Graphics 的路径包含检测
        return self.contains(point, using: .winding, transform: .identity)
    }
}
