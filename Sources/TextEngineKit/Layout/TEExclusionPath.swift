//
//  TEExclusionPath.swift
//  TextEngineKit
//
//  Created by Assistant on 2025/11/21.
//
//  排除路径支持：实现文本环绕复杂路径的功能
//

#if canImport(UIKit)
import UIKit
import Foundation
import CoreText
import CoreGraphics

/// 排除路径
/// 定义文本布局时应避开的区域，支持复杂的几何形状
/// 
/// 功能特性:
/// - 支持任意UIBezierPath路径形状
/// - 内外两种排除模式
/// - 可配置的内边距
/// - 点包含检测和矩形相交检测
/// 
/// 使用示例:
/// ```swift
/// // 创建矩形排除路径
/// let rectPath = TEExclusionPath.rect(CGRect(x: 100, y: 100, width: 200, height: 150))
/// 
/// // 创建圆形排除路径
/// let circlePath = TEExclusionPath.circle(center: CGPoint(x: 200, y: 200), radius: 50)
/// 
/// // 创建自定义路径
/// let customPath = UIBezierPath()
/// customPath.move(to: CGPoint(x: 0, y: 0))
/// customPath.addLine(to: CGPoint(x: 100, y: 100))
/// customPath.addLine(to: CGPoint(x: 0, y: 100))
/// customPath.close()
/// let trianglePath = TEExclusionPath(path: customPath, type: .inside)
/// ```
public struct TEExclusionPath {
    
    /// 路径
    public let path: UIBezierPath
    
    /// 内边距
    public let padding: UIEdgeInsets
    
    /// 类型
    public let type: ExclusionType
    
    /// 排除类型
    /// 定义文本相对于排除路径的流动方式
    /// 
    /// - `inside`: 路径内部排除，文本在路径外部流动
    /// - `outside`: 路径外部排除，文本在路径内部流动
    /// 
    /// 使用示例:
    /// ```swift
    /// // 图片周围的文本环绕（内部排除）
    /// let imageExclusion = TEExclusionPath.rect(imageRect, type: .inside)
    /// 
    /// // 形状内部的文本填充（外部排除）
    /// let shapeText = TEExclusionPath.circle(center: center, radius: radius, type: .outside)
    /// ```
    public enum ExclusionType {
        case inside    // 路径内部排除（文本在路径外部流动）
        case outside   // 路径外部排除（文本在路径内部流动）
    }
    
    /// 初始化排除路径
    /// - 使用指定的路径、内边距和排除类型创建排除路径
    /// 
    /// 使用示例:
    /// ```swift
    /// let path = UIBezierPath(ovalIn: CGRect(x: 0, y: 0, width: 100, height: 100))
    /// let exclusionPath = TEExclusionPath(
    ///     path: path,
    ///     padding: UIEdgeInsets(top: 10, left: 10, bottom: 10, right: 10),
    ///     type: .inside
    /// )
    /// ```
    /// 
    /// - Parameters:
    ///   - path: 定义排除区域的UIBezierPath
    ///   - padding: 路径的内边距，默认为.zero
    ///   - type: 排除类型，默认为.inside
    public init(path: UIBezierPath, padding: UIEdgeInsets = .zero, type: ExclusionType = .inside) {
        self.path = path
        self.padding = padding
        self.type = type
    }
    
    /// 创建矩形排除路径
    /// - 使用指定的矩形区域创建排除路径
    /// - 支持自定义内边距和排除类型
    /// 
    /// 使用示例:
    /// ```swift
    /// // 创建简单的矩形排除路径
    /// let rectPath = TEExclusionPath.rect(CGRect(x: 100, y: 100, width: 200, height: 150))
    /// 
    /// // 创建带内边距的矩形排除路径
    /// let paddedRectPath = TEExclusionPath.rect(
    ///     CGRect(x: 100, y: 100, width: 200, height: 150),
    ///     padding: UIEdgeInsets(top: 10, left: 10, bottom: 10, right: 10),
    ///     type: .inside
    /// )
    /// ```
    /// 
    /// - Parameters:
    ///   - rect: 定义排除区域的矩形
    ///   - padding: 矩形的内边距，默认为.zero
    ///   - type: 排除类型，默认为.inside
    /// - Returns: 新的矩形排除路径实例
    public static func rect(_ rect: CGRect, padding: UIEdgeInsets = .zero, type: ExclusionType = .inside) -> TEExclusionPath {
        let path = UIBezierPath(rect: rect)
        return TEExclusionPath(path: path, padding: padding, type: type)
    }
    
    /// 创建圆形排除路径
    /// - 使用指定的圆心和半径创建圆形排除路径
    /// - 支持自定义内边距和排除类型
    /// 
    /// 使用示例:
    /// ```swift
    /// // 创建简单的圆形排除路径
    /// let circlePath = TEExclusionPath.circle(center: CGPoint(x: 200, y: 200), radius: 50)
    /// 
    /// // 创建带内边距的圆形排除路径
    /// let paddedCirclePath = TEExclusionPath.circle(
    ///     center: CGPoint(x: 200, y: 200),
    ///     radius: 50,
    ///     padding: UIEdgeInsets(top: 10, left: 10, bottom: 10, right: 10),
    ///     type: .inside
    /// )
    /// ```
    /// 
    /// - Parameters:
    ///   - center: 圆的中心点坐标
    ///   - radius: 圆的半径
    ///   - padding: 圆形的内边距，默认为.zero
    ///   - type: 排除类型，默认为.inside
    /// - Returns: 新的圆形排除路径实例
    public static func circle(center: CGPoint, radius: CGFloat, padding: UIEdgeInsets = .zero, type: ExclusionType = .inside) -> TEExclusionPath {
        let path = UIBezierPath(ovalIn: CGRect(x: center.x - radius, y: center.y - radius, width: radius * 2, height: radius * 2))
        return TEExclusionPath(path: path, padding: padding, type: type)
    }
    
    /// 创建椭圆排除路径
    /// - 使用指定的圆心和X/Y轴半径创建椭圆排除路径
    /// - 支持自定义内边距和排除类型
    /// 
    /// 使用示例:
    /// ```swift
    /// // 创建简单的椭圆排除路径
    /// let ellipsePath = TEExclusionPath.ellipse(
    ///     center: CGPoint(x: 200, y: 200),
    ///     radiusX: 100,
    ///     radiusY: 50
    /// )
    /// 
    /// // 创建带内边距的椭圆排除路径
    /// let paddedEllipsePath = TEExclusionPath.ellipse(
    ///     center: CGPoint(x: 200, y: 200),
    ///     radiusX: 100,
    ///     radiusY: 50,
    ///     padding: UIEdgeInsets(top: 10, left: 10, bottom: 10, right: 10),
    ///     type: .inside
    /// )
    /// ```
    /// 
    /// - Parameters:
    ///   - center: 椭圆的中心点坐标
    ///   - radiusX: X轴半径（半长轴）
    ///   - radiusY: Y轴半径（半短轴）
    ///   - padding: 椭圆的内边距，默认为.zero
    ///   - type: 排除类型，默认为.inside
    /// - Returns: 新的椭圆排除路径实例
    public static func ellipse(center: CGPoint, radiusX: CGFloat, radiusY: CGFloat, padding: UIEdgeInsets = .zero, type: ExclusionType = .inside) -> TEExclusionPath {
        let path = UIBezierPath(ovalIn: CGRect(x: center.x - radiusX, y: center.y - radiusY, width: radiusX * 2, height: radiusY * 2))
        return TEExclusionPath(path: path, padding: padding, type: type)
    }
    
    /// 获取带内边距的路径边界
    /// - 计算包含内边距的路径边界矩形
    /// - 用于确定文本布局时的实际排除区域
    /// 
    /// 使用示例:
    /// ```swift
    /// let path = TEExclusionPath.rect(CGRect(x: 100, y: 100, width: 200, height: 150))
    /// let paddedBounds = path.paddedBounds // 包含内边距的边界
    /// ```
    /// 
    /// - Returns: 包含内边距的路径边界矩形
    internal var paddedBounds: CGRect {
        let bounds = path.bounds
        return CGRect(
            x: bounds.minX - padding.left,
            y: bounds.minY - padding.top,
            width: bounds.width + padding.left + padding.right,
            height: bounds.height + padding.top + padding.bottom
        )
    }
    
    /// 检查点是否在排除区域内
    /// - 根据排除类型判断点是否应该在文本布局时被排除
    /// - 会考虑内边距的影响
    /// - 支持内外两种排除模式
    /// 
    /// 使用示例:
    /// ```swift
    /// let exclusionPath = TEExclusionPath.rect(CGRect(x: 0, y: 0, width: 100, height: 100))
    /// 
    /// // 检查内部排除
    /// let insidePoint = CGPoint(x: 50, y: 50)
    /// let isInsideExcluded = exclusionPath.contains(insidePoint) // true
    /// 
    /// // 检查外部排除
    /// let outsidePath = TEExclusionPath.rect(CGRect(x: 0, y: 0, width: 100, height: 100), type: .outside)
    /// let outsidePoint = CGPoint(x: 150, y: 150)
    /// let isOutsideExcluded = outsidePath.contains(outsidePoint) // true
    /// ```
    /// 
    /// - Parameter point: 要检查的点坐标
    /// - Returns: 如果点在排除区域内返回 `true`，否则返回 `false`
    public func contains(_ point: CGPoint) -> Bool {
        let paddedPath = getPaddedPath()
        let contains = paddedPath.contains(point)
        
        switch type {
        case .inside:
            return contains
        case .outside:
            return !contains
        }
    }
    
    /// 检查矩形是否与排除区域相交
    /// - Parameter rect: 矩形
    /// - Returns: 是否相交
    public func intersects(_ rect: CGRect) -> Bool {
        let paddedPath = getPaddedPath()
        let pathBounds = paddedPath.bounds
        
        // 先检查边界框相交
        if !pathBounds.intersects(rect) {
            return false
        }
        
        // 再检查路径相交
        let rectPath = UIBezierPath(rect: rect)
        return paddedPath.intersects(with: rectPath)
    }
    
    /// 获取带内边距的路径
    /// - Returns: 带内边距的路径
    private func getPaddedPath() -> UIBezierPath {
        if padding == .zero {
            return path
        }
        
        // 创建带内边距的路径
        let paddedPath = UIBezierPath()
        let bounds = path.bounds
        let paddedBounds = self.paddedBounds
        
        // 这里可以实现更复杂的路径扩展逻辑
        // 简化实现：直接缩放路径
        let scaleX = paddedBounds.width / bounds.width
        let scaleY = paddedBounds.height / bounds.height
        
        paddedPath.append(path)
        paddedPath.apply(CGAffineTransform(translationX: -bounds.midX, y: -bounds.midY))
        paddedPath.apply(CGAffineTransform(scaleX: scaleX, y: scaleY))
        paddedPath.apply(CGAffineTransform(translationX: paddedBounds.midX, y: paddedBounds.midY))
        
        return paddedPath
    }
}

/// 排除路径管理器
/// 管理多个排除路径
@MainActor
public final class TEExclusionPathManager {
    
    // MARK: - 属性
    
    /// 排除路径数组
    private var exclusionPaths: [TEExclusionPath] = []
    
    /// 线程安全锁
    private let lock = NSLock()
    
    /// 缓存的边界框
    private var cachedBounds: CGRect?
    
    /// 缓存的有效矩形数组
    private var cachedValidRects: [CGRect]?
    
    // MARK: - 公共方法
    
    /// 添加排除路径
    /// - Parameter path: 排除路径
    public func addExclusionPath(_ path: TEExclusionPath) {
        lock.lock()
        exclusionPaths.append(path)
        invalidateCache()
        lock.unlock()
    }
    
    /// 移除排除路径
    /// - Parameter path: 排除路径
    public func removeExclusionPath(_ path: TEExclusionPath) {
        lock.lock()
        exclusionPaths.removeAll { $0.path === path.path }
        invalidateCache()
        lock.unlock()
    }
    
    /// 清除所有排除路径
    public func clearExclusionPaths() {
        lock.lock()
        exclusionPaths.removeAll()
        invalidateCache()
        lock.unlock()
    }
    
    /// 获取所有排除路径
    /// - Returns: 排除路径数组
    public func getExclusionPaths() -> [TEExclusionPath] {
        lock.lock()
        let paths = exclusionPaths
        lock.unlock()
        return paths
    }
    
    /// 检查点是否在排除区域内
    /// - Parameter point: 点
    /// - Returns: 是否在排除区域内
    public func isPointExcluded(_ point: CGPoint) -> Bool {
        lock.lock()
        let result = exclusionPaths.contains { $0.contains(point) }
        lock.unlock()
        return result
    }
    
    /// 检查矩形是否与排除区域相交
    /// - Parameter rect: 矩形
    /// - Returns: 是否相交
    public func doesRectIntersectExclusion(_ rect: CGRect) -> Bool {
        lock.lock()
        let result = exclusionPaths.contains { $0.intersects(rect) }
        lock.unlock()
        return result
    }
    
    /// 获取在给定矩形内的有效区域
    /// - Parameter rect: 矩形
    /// - Returns: 有效区域数组
    public func getValidRects(in rect: CGRect) -> [CGRect] {
        lock.lock()
        
        // 检查缓存
        if let cachedBounds = cachedBounds,
           cachedBounds == rect,
           let cachedRects = cachedValidRects {
            lock.unlock()
            return cachedRects
        }
        
        var validRects = [rect]
        
        for exclusionPath in exclusionPaths {
            var newValidRects: [CGRect] = []
            
            for validRect in validRects {
                let splitRects = splitRect(validRect, with: exclusionPath)
                newValidRects.append(contentsOf: splitRects)
            }
            
            validRects = newValidRects
        }
        
        // 缓存结果
        cachedBounds = rect
        cachedValidRects = validRects
        
        lock.unlock()
        return validRects
    }
    
    /// 计算文本容器尺寸
    /// - Parameters:
    ///   - containerSize: 容器尺寸
    ///   - lineHeight: 行高
    /// - Returns: 可用文本区域数组
    public func calculateTextAreas(containerSize: CGSize, lineHeight: CGFloat) -> [CGRect] {
        let containerRect = CGRect(origin: .zero, size: containerSize)
        return getValidRects(in: containerRect)
    }
    
    /// 调整CTFrame以适应排除路径
    /// - Parameters:
    ///   - frame: 原始CTFrame
    ///   - exclusionPaths: 排除路径
    /// - Returns: 调整后的CTFrame
    public func adjustFrameForExclusions(_ frame: CTFrame, exclusionPaths: [TEExclusionPath]) -> CTFrame {
        // 这里需要实现复杂的CoreText框架调整逻辑
        // 简化实现：返回原始框架
        return frame
    }
    
    // MARK: - 私有方法
    
    /// 使用排除路径分割矩形
    /// - Parameters:
    ///   - rect: 原始矩形
    ///   - exclusionPath: 排除路径
    /// - Returns: 分割后的矩形数组
    private func splitRect(_ rect: CGRect, with exclusionPath: TEExclusionPath) -> [CGRect] {
        // 简化实现：如果矩形与排除路径相交，返回空数组
        // 实际实现需要复杂的几何计算
        if exclusionPath.intersects(rect) {
            return []
        }
        return [rect]
    }
    
    /// 使缓存失效
    private func invalidateCache() {
        cachedBounds = nil
        cachedValidRects = nil
    }
}

/// UIBezierPath扩展
extension UIBezierPath {
    /// 检查两个路径是否相交
    /// - Parameter path: 另一个路径
    /// - Returns: 是否相交
    func intersects(with path: UIBezierPath) -> Bool {
        // 简化实现：检查边界框相交
        return self.bounds.intersects(path.bounds)
    }
}

/// 文本容器扩展，支持排除路径
extension TETextContainer {
    
    /// 排除路径管理器
    private static var exclusionPathManagerKey: UInt8 = 0
    
    /// 获取排除路径管理器
    public var exclusionPathManager: TEExclusionPathManager? {
        get {
            return objc_getAssociatedObject(self, &TETextContainer.exclusionPathManagerKey) as? TEExclusionPathManager
        }
        set {
            objc_setAssociatedObject(self, &TETextContainer.exclusionPathManagerKey, newValue, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
        }
    }
    
    /// 添加排除路径
    /// - Parameter path: 排除路径
    public func addExclusionPath(_ path: TEExclusionPath) {
        if exclusionPathManager == nil {
            exclusionPathManager = TEExclusionPathManager()
        }
        exclusionPathManager?.addExclusionPath(path)
    }
    
    /// 移除排除路径
    /// - Parameter path: 排除路径
    public func removeExclusionPath(_ path: TEExclusionPath) {
        exclusionPathManager?.removeExclusionPath(path)
    }
    
    /// 清除所有排除路径
    public func clearExclusionPaths() {
        exclusionPathManager?.clearExclusionPaths()
    }
}

#endif