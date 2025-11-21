//
//  TEExclusionPathManager.swift
//  TextEngineKit
//
//  Created by Assistant on 2025/11/21.
//
//  排除路径管理器：管理文本布局的排除路径，支持动态添加和移除
//

#if canImport(UIKit)
import UIKit
import Foundation

/// 排除路径管理器
/// 管理文本布局的排除路径，支持动态添加、移除和查询
@MainActor
public final class TEExclusionPathManager: NSObject {
    
    // MARK: - 属性
    
    /// 当前的排除路径数组
    private var exclusionPaths: [TEExclusionPath] = []
    
    /// 排除路径变化的回调
    public var onExclusionPathsChanged: (() -> Void)?
    
    // MARK: - 生命周期
    
    public override init() {
        super.init()
    }
    
    // MARK: - 公共方法
    
    /// 添加排除路径
    /// - Parameter path: 要添加的排除路径
    public func addExclusionPath(_ path: TEExclusionPath) {
        exclusionPaths.append(path)
        onExclusionPathsChanged?()
    }
    
    /// 移除排除路径
    /// - Parameter path: 要移除的排除路径
    public func removeExclusionPath(_ path: TEExclusionPath) {
        exclusionPaths.removeAll { $0 == path }
        onExclusionPathsChanged?()
    }
    
    /// 清除所有排除路径
    public func clearExclusionPaths() {
        exclusionPaths.removeAll()
        onExclusionPathsChanged?()
    }
    
    /// 获取所有排除路径
    /// - Returns: 当前的排除路径数组
    public func getAllExclusionPaths() -> [TEExclusionPath] {
        return exclusionPaths
    }
    
    /// 检查点是否与任何排除路径相交
    /// - Parameter point: 要检查的点
    /// - Returns: true表示点与至少一个排除路径相交
    public func contains(_ point: CGPoint) -> Bool {
        return exclusionPaths.contains { $0.contains(point) }
    }
    
    /// 计算排除路径对指定行矩形的影响
    /// - Parameters:
    ///   - containerBounds: 容器边界
    ///   - lineRect: 当前行的矩形区域
    /// - Returns: 受影响后的有效矩形区域数组
    public func calculateEffectiveRects(in containerBounds: CGRect, for lineRect: CGRect) -> [CGRect] {
        return exclusionPaths.calculateEffectiveRects(in: containerBounds, for: lineRect)
    }
    
    /// 获取所有排除路径的联合边界
    public var unionBounds: CGRect {
        return exclusionPaths.unionBounds
    }
    
    /// 获取排除路径数量
    public var count: Int {
        return exclusionPaths.count
    }
    
    /// 检查是否包含排除路径
    public var isEmpty: Bool {
        return exclusionPaths.isEmpty
    }
}

// MARK: - 扩展功能

public extension TEExclusionPathManager {
    
    /// 批量添加排除路径
    /// - Parameter paths: 要添加的排除路径数组
    func addExclusionPaths(_ paths: [TEExclusionPath]) {
        exclusionPaths.append(contentsOf: paths)
        onExclusionPathsChanged?()
    }
    
    /// 批量移除排除路径
    /// - Parameter paths: 要移除的排除路径数组
    func removeExclusionPaths(_ paths: [TEExclusionPath]) {
        for path in paths {
            exclusionPaths.removeAll { $0 == path }
        }
        onExclusionPathsChanged?()
    }
    
    /// 替换所有排除路径
    /// - Parameter paths: 新的排除路径数组
    func replaceAllExclusionPaths(with paths: [TEExclusionPath]) {
        exclusionPaths = paths
        onExclusionPathsChanged?()
    }
}

#endif
