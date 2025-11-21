//
//  TEExclusionPath.swift
//  TextEngineKit
//
//  Created by Assistant on 2025/11/21.
//
//  排除路径：支持文本环绕复杂路径，参考MPITextKit设计
//

#if canImport(UIKit)
import UIKit
import Foundation

/// 排除路径
/// 定义文本布局时应避开的区域，支持复杂的几何形状
/// 参考MPITextKit的排除路径实现
public struct TEExclusionPath: Equatable {
    
    /// 排除类型
    public enum ExclusionType {
        /// 排除路径内部区域（默认）
        /// 文本将围绕路径外部流动
        case inside
        
        /// 排除路径外部区域
        /// 文本将只在路径内部流动
        case outside
    }
    
    /// 排除路径的几何形状
    public let path: UIBezierPath
    
    /// 内边距，用于扩展排除区域
    public let padding: UIEdgeInsets
    
    /// 排除类型
    public let type: ExclusionType
    
    /// 初始化排除路径
    /// - Parameters:
    ///   - path: 排除路径的几何形状
    ///   - padding: 内边距，默认为零
    ///   - type: 排除类型，默认为inside
    public init(path: UIBezierPath, padding: UIEdgeInsets = .zero, type: ExclusionType = .inside) {
        self.path = path
        self.padding = padding
        self.type = type
    }
    
    /// 创建矩形排除路径
    /// - Parameters:
    ///   - rect: 矩形区域
    ///   - padding: 内边距，默认为零
    ///   - type: 排除类型，默认为inside
    /// - Returns: 矩形排除路径
    public static func rect(_ rect: CGRect, padding: UIEdgeInsets = .zero, type: ExclusionType = .inside) -> TEExclusionPath {
        let path = UIBezierPath(rect: rect)
        return TEExclusionPath(path: path, padding: padding, type: type)
    }
    
    /// 创建圆形排除路径
    /// - Parameters:
    ///   - center: 圆心位置
    ///   - radius: 半径
    ///   - padding: 内边距，默认为零
    ///   - type: 排除类型，默认为inside
    /// - Returns: 圆形排除路径
    public static func circle(center: CGPoint, radius: CGFloat, padding: UIEdgeInsets = .zero, type: ExclusionType = .inside) -> TEExclusionPath {
        let path = UIBezierPath(arcCenter: center, radius: radius, startAngle: 0, endAngle: CGFloat.pi * 2, clockwise: true)
        return TEExclusionPath(path: path, padding: padding, type: type)
    }
    
    /// 创建椭圆排除路径
    /// - Parameters:
    ///   - rect: 椭圆的边界矩形
    ///   - padding: 内边距，默认为零
    ///   - type: 排除类型，默认为inside
    /// - Returns: 椭圆排除路径
    public static func ellipse(in rect: CGRect, padding: UIEdgeInsets = .zero, type: ExclusionType = .inside) -> TEExclusionPath {
        let path = UIBezierPath(ovalIn: rect)
        return TEExclusionPath(path: path, padding: padding, type: type)
    }
    
    /// 检查点是否在排除区域内
    /// - Parameter point: 要检查的点
    /// - Returns: true表示点在排除区域内，false表示不在
    public func contains(_ point: CGPoint) -> Bool {
        // 考虑内边距的影响
        let paddedPath = getPaddedPath()
        
        switch type {
        case .inside:
            // 内部排除：点在路径内部则包含
            return paddedPath.contains(point)
        case .outside:
            // 外部排除：点在路径外部则包含
            return !paddedPath.contains(point)
        }
    }
    
    /// 获取考虑内边距后的边界矩形
    public var paddedBounds: CGRect {
        let originalBounds = path.bounds
        return CGRect(
            x: originalBounds.origin.x - padding.left,
            y: originalBounds.origin.y - padding.top,
            width: originalBounds.width + padding.left + padding.right,
            height: originalBounds.height + padding.top + padding.bottom
        )
    }
    
    /// 获取考虑内边距后的路径
    private func getPaddedPath() -> UIBezierPath {
        if padding == .zero {
            return path
        }
        
        // 创建内边距变换
        let transform = CGAffineTransform(translationX: -padding.left, y: -padding.top)
        let paddedPath = path.copy() as! UIBezierPath
        paddedPath.apply(transform)
        
        // 调整路径大小以包含内边距
        let scaleX = (path.bounds.width + padding.left + padding.right) / path.bounds.width
        let scaleY = (path.bounds.height + padding.top + padding.bottom) / path.bounds.height
        let scaleTransform = CGAffineTransform(scaleX: scaleX, y: scaleY)
        paddedPath.apply(scaleTransform)
        
        return paddedPath
    }
    
    /// 获取路径与矩形的交集
    /// - Parameter rect: 要检查的矩形
    /// - Returns: 交集矩形数组
    public func intersects(with rect: CGRect) -> [CGRect] {
        let paddedPath = getPaddedPath()
        let pathBounds = paddedPath.bounds
        
        // 快速检查：如果矩形与路径边界不相交，返回空数组
        if !rect.intersects(pathBounds) {
            return []
        }
        
        // 计算精确的交集
        var intersections: [CGRect] = []
        
        // 简化处理：返回边界矩形的交集
        let intersectionRect = rect.intersection(pathBounds)
        if !intersectionRect.isEmpty {
            intersections.append(intersectionRect)
        }
        
        return intersections
    }
    
    /// 计算排除路径对文本布局的影响
    /// - Parameters:
    ///   - containerBounds: 容器边界
    ///   - lineRect: 当前行的矩形区域
    /// - Returns: 受影响后的有效矩形区域数组
    public func calculateExclusionRects(in containerBounds: CGRect, for lineRect: CGRect) -> [CGRect] {
        // 如果行矩形与排除路径不相交，返回原始行矩形
        guard !intersects(with: lineRect).isEmpty else {
            return [lineRect]
        }
        
        var effectiveRects: [CGRect] = []
        let paddedPath = getPaddedPath()
        let pathBounds = paddedPath.bounds
        
        switch type {
        case .inside:
            // 内部排除：文本在路径外部流动
            // 简化实现：在行矩形中创建排除区域
            if lineRect.intersects(pathBounds) {
                // 分割行矩形以避开排除路径
                if lineRect.minX < pathBounds.minX {
                    // 左侧区域
                    let leftRect = CGRect(
                        x: lineRect.minX,
                        y: lineRect.minY,
                        width: pathBounds.minX - lineRect.minX,
                        height: lineRect.height
                    )
                    effectiveRects.append(leftRect)
                }
                
                if lineRect.maxX > pathBounds.maxX {
                    // 右侧区域
                    let rightRect = CGRect(
                        x: pathBounds.maxX,
                        y: lineRect.minY,
                        width: lineRect.maxX - pathBounds.maxX,
                        height: lineRect.height
                    )
                    effectiveRects.append(rightRect)
                }
            } else {
                effectiveRects.append(lineRect)
            }
            
        case .outside:
            // 外部排除：文本只在路径内部流动
            if lineRect.intersects(pathBounds) {
                // 只保留与路径相交的部分
                let intersection = lineRect.intersection(pathBounds)
                if !intersection.isEmpty {
                    effectiveRects.append(intersection)
                }
            }
        }
        
        return effectiveRects.isEmpty ? [lineRect] : effectiveRects
    }
}

public func == (lhs: TEExclusionPath, rhs: TEExclusionPath) -> Bool {
    return lhs.path === rhs.path && lhs.padding == rhs.padding && lhs.type == rhs.type
}

// MARK: - 扩展功能

public extension TEExclusionPath {
    /// 创建多边形排除路径
    /// - Parameters:
    ///   - points: 多边形顶点数组
    ///   - padding: 内边距，默认为零
    ///   - type: 排除类型，默认为inside
    /// - Returns: 多边形排除路径
    static func polygon(points: [CGPoint], padding: UIEdgeInsets = .zero, type: ExclusionType = .inside) -> TEExclusionPath {
        guard points.count >= 3 else {
            // 如果点数不足，创建默认矩形
            return rect(CGRect(x: 0, y: 0, width: 100, height: 100), padding: padding, type: type)
        }
        
        let path = UIBezierPath()
        path.move(to: points[0])
        
        for i in 1..<points.count {
            path.addLine(to: points[i])
        }
        
        path.close()
        return TEExclusionPath(path: path, padding: padding, type: type)
    }
    
    /// 创建星形排除路径
    /// - Parameters:
    ///   - center: 星形中心点
    ///   - points: 星形顶点数
    ///   - outerRadius: 外半径
    ///   - innerRadius: 内半径
    ///   - padding: 内边距，默认为零
    ///   - type: 排除类型，默认为inside
    /// - Returns: 星形排除路径
    static func star(center: CGPoint, points: Int, outerRadius: CGFloat, innerRadius: CGFloat, padding: UIEdgeInsets = .zero, type: ExclusionType = .inside) -> TEExclusionPath {
        guard points >= 3 else {
            return circle(center: center, radius: outerRadius, padding: padding, type: type)
        }
        
        let path = UIBezierPath()
        let angleStep = CGFloat.pi * 2 / CGFloat(points)
        
        for i in 0..<points {
            let outerAngle = CGFloat(i) * angleStep - CGFloat.pi / 2
            let outerPoint = CGPoint(
                x: center.x + outerRadius * cos(outerAngle),
                y: center.y + outerRadius * sin(outerAngle)
            )
            
            let innerAngle = outerAngle + angleStep / 2
            let innerPoint = CGPoint(
                x: center.x + innerRadius * cos(innerAngle),
                y: center.y + innerRadius * sin(innerAngle)
            )
            
            if i == 0 {
                path.move(to: outerPoint)
            } else {
                path.addLine(to: outerPoint)
            }
            
            path.addLine(to: innerPoint)
        }
        
        path.close()
        return TEExclusionPath(path: path, padding: padding, type: type)
    }
    
    /// 创建圆角矩形排除路径
    /// - Parameters:
    ///   - rect: 矩形区域
    ///   - cornerRadius: 圆角半径
    ///   - padding: 内边距，默认为零
    ///   - type: 排除类型，默认为inside
    /// - Returns: 圆角矩形排除路径
    static func roundedRect(_ rect: CGRect, cornerRadius: CGFloat, padding: UIEdgeInsets = .zero, type: ExclusionType = .inside) -> TEExclusionPath {
        let path = UIBezierPath(roundedRect: rect, cornerRadius: cornerRadius)
        return TEExclusionPath(path: path, padding: padding, type: type)
    }
}

// MARK: - 数组扩展

public extension Array where Element == TEExclusionPath {
    /// 检查点是否与任何排除路径相交
    /// - Parameter point: 要检查的点
    /// - Returns: true表示点与至少一个排除路径相交
    func contains(_ point: CGPoint) -> Bool {
        return contains { $0.contains(point) }
    }
    
    /// 计算所有排除路径对指定行矩形的影响
    /// - Parameters:
    ///   - containerBounds: 容器边界
    ///   - lineRect: 行矩形
    /// - Returns: 考虑所有排除路径后的有效矩形区域
    func calculateEffectiveRects(in containerBounds: CGRect, for lineRect: CGRect) -> [CGRect] {
        var effectiveRects = [lineRect]
        
        for exclusionPath in self {
            var newEffectiveRects: [CGRect] = []
            
            for currentRect in effectiveRects {
                let excludedRects = exclusionPath.calculateExclusionRects(in: containerBounds, for: currentRect)
                newEffectiveRects.append(contentsOf: excludedRects)
            }
            
            effectiveRects = newEffectiveRects
        }
        
        return effectiveRects.isEmpty ? [lineRect] : effectiveRects
    }
    
    /// 获取所有排除路径的联合边界
    var unionBounds: CGRect {
        guard !isEmpty else { return .zero }
        
        return reduce(into: first!.paddedBounds) { unionRect, exclusionPath in
            unionRect = unionRect.union(exclusionPath.paddedBounds)
        }
    }
}

#endif
