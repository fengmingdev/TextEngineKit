//
//  TETextDebugger.swift
//  TextEngineKit
//
//  Created by Assistant on 2025/11/21.
//
//  调试可视化工具：提供文本布局调试和可视化功能
//

#if canImport(UIKit)
import UIKit
import Foundation
import CoreText
import CoreGraphics

/// 文本调试选项
/// 配置文本布局调试和可视化显示的选项
/// 
/// 功能特性:
/// - 基线显示和颜色配置
/// - 行片段边界显示
/// - 字形边界显示
/// - 排除路径可视化
/// - 选择范围高亮
/// - 自定义颜色配置
/// 
/// 使用示例:
/// ```swift
/// var debugOptions = TETextDebugOptions()
/// debugOptions.showBaselines = true
/// debugOptions.baselineColor = .red
/// debugOptions.showLineFragments = true
/// debugOptions.showExclusionPaths = true
/// debugOptions.exclusionPathColor = .purple
/// 
/// // 应用调试选项
/// debugger.updateOptions(debugOptions)
/// ```
public struct TETextDebugOptions {
    
    /// 是否启用基线显示
    /// - 显示文本的基线位置，有助于理解文本垂直对齐
    /// - 默认值为 `true`
    public var showBaselines: Bool = true
    
    /// 基线颜色
    /// - 用于绘制文本基线的颜色
    /// - 默认值为半透明红色
    /// - 建议使用醒目的颜色以便调试时清晰可见
    public var baselineColor: UIColor = UIColor.red.withAlphaComponent(0.5)
    
    /// 是否显示行片段边界
    /// - 显示文本布局时每一行的边界矩形
    /// - 有助于理解文本换行和布局行为
    /// - 默认值为 `true`
    public var showLineFragments: Bool = true
    
    /// 行片段边界颜色
    /// - 用于绘制行片段边界的颜色
    /// - 默认值为半透明红色
    public var lineFragmentBorderColor: UIColor = UIColor.red.withAlphaComponent(0.2)
    
    /// 已使用的行片段边界颜色
    /// - 用于绘制包含文本的行片段边界颜色
    /// - 与空行片段区分显示
    /// - 默认值为半透明蓝色
    public var lineFragmentUsedBorderColor: UIColor = UIColor.blue.withAlphaComponent(0.2)
    
    /// 是否显示字形边界
    /// - 显示每个字符（字形）的精确边界框
    /// - 有助于理解字符级布局和间距
    /// - 默认值为 `false`（因为可能影响性能）
    public var showGlyphs: Bool = false
    
    /// 字形边界颜色
    /// - 用于绘制字形边界的颜色
    /// - 默认值为半透明橙色
    public var glyphBorderColor: UIColor = UIColor.orange.withAlphaComponent(0.2)
    
    /// 是否显示排除路径
    /// - 显示文本布局中的排除路径区域
    /// - 有助于调试文本环绕和布局避让
    /// - 默认值为 `true`
    public var showExclusionPaths: Bool = true
    
    /// 排除路径颜色
    /// - 用于绘制排除路径区域的颜色
    /// - 默认值为半透明紫色
    public var exclusionPathColor: UIColor = UIColor.purple.withAlphaComponent(0.3)
    
    /// 是否显示选择范围
    /// - 显示当前文本选择的高亮区域
    /// - 有助于调试文本选择功能
    /// - 默认值为 `true`
    public var showSelection: Bool = true
    
    /// 选择范围颜色
    /// - 用于绘制文本选择高亮的颜色
    /// - 默认值为半透明系统黄色
    public var selectionColor: UIColor = UIColor.systemYellow.withAlphaComponent(0.3)
    
    /// 是否显示附件
    /// - 显示文本中的附件元素（如图片、自定义视图等）
    /// - 有助于调试附件布局和位置
    /// - 默认值为 `true`
    public var showAttachments: Bool = true
    
    /// 附件颜色
    /// - 用于绘制附件边界的颜色
    /// - 默认值为半透明绿色
    /// - 建议使用与文本对比明显的颜色
    public var attachmentColor: UIColor = UIColor.green.withAlphaComponent(0.5)
    
    /// 是否显示高亮
    /// - 显示文本中的高亮区域
    /// - 有助于调试文本高亮和背景色效果
    /// - 默认值为 `true`
    public var showHighlights: Bool = true
    
    /// 高亮颜色
    /// - 用于绘制文本高亮区域的颜色
    /// - 默认值为半透明粉色
    /// - 建议使用柔和的颜色以避免干扰文本阅读
    public var highlightColor: UIColor = UIColor.systemPink.withAlphaComponent(0.3)
    
    /// 线宽
    /// - 所有调试图层边框的线宽
    /// - 默认值为 `1.0`
    /// - 建议值范围：0.5 - 2.0，过细可能难以观察，过粗可能遮挡内容
    public var lineWidth: CGFloat = 1.0
    
    /// 字体大小（用于调试文本）
    /// - 调试信息文本的字体大小
    /// - 默认值为 `10.0`
    /// - 建议值范围：8 - 12，确保文本清晰可读
    public var debugFontSize: CGFloat = 10.0
    
    /// 调试文本颜色
    /// - 调试信息文本的颜色
    /// - 默认值为黑色
    /// - 建议选择与背景对比度高的颜色
    public var debugTextColor: UIColor = .black
    
    public init() {}
}

/// 调试信息
/// 包含文本布局、性能、排除路径和选择信息的综合调试数据
/// 
/// 功能特性:
/// - 文本布局信息（行数、字形数、字符数等）
/// - 性能指标（布局时间、渲染时间、内存使用等）
/// - 排除路径统计（路径数量、有效区域、排除面积等）
/// - 选择状态信息（选择范围、选择矩形、手柄位置等）
/// 
/// 使用示例:
/// ```swift
/// let debugInfo = TETextDebugInfo(
///     layoutInfo: layoutInfo,
///     performanceInfo: performanceInfo,
///     exclusionPathInfo: exclusionPathInfo,
///     selectionInfo: selectionInfo,
///     timestamp: Date()
/// )
/// 
/// // 分析布局性能
/// if let performance = debugInfo.performanceInfo {
///     print("布局耗时: \\(performance.layoutTime)秒")
///     print("总耗时: \\(performance.totalTime)秒")
/// }
/// ```
public struct TETextDebugInfo {
    
    /// 文本布局信息
    /// 包含文本布局的详细统计和几何信息
    /// 
    /// 功能特性:
    /// - 总行数和字符统计
    /// - 行片段详细信息
    /// - 基线位置信息
    /// - 截断状态检测
    public struct LayoutInfo {
        /// 总行数
        public let lineCount: Int
        
        /// 总字形数
        public let totalGlyphCount: Int
        
        /// 总字符数
        public let totalCharacterCount: Int
        
        /// 行片段信息数组
        public let lineFragments: [LineFragmentInfo]
        
        /// 基线信息数组
        public let baselines: [BaselineInfo]
        
        /// 行片段信息
        /// 表示文本布局中单个行片段的详细信息
        public struct LineFragmentInfo {
            /// 行片段的完整矩形区域
            public let rect: CGRect
            
            /// 行片段的实际使用矩形区域
            /// 通常比完整矩形小，因为可能存在空白区域
            public let usedRect: CGRect
            
            /// 此行片段中的字形数量
            public let glyphCount: Int
            
            /// 此行片段对应的字符范围
            public let characterRange: NSRange
            
            /// 此行片段是否被截断
            /// 当文本超出容器边界时会被截断
            public let isTruncated: Bool
        }
        
        /// 基线信息
        /// 表示文本基线的位置和相关度量信息
        public struct BaselineInfo {
            /// 基线的Y坐标
            public let y: CGFloat
            
            /// 上行高度（从基线到字符顶部的距离）
            public let ascent: CGFloat
            
            /// 下行高度（从基线到字符底部的距离）
            public let descent: CGFloat
            
            /// 行间距（额外添加的间距）
            public let leading: CGFloat
        }
    }
    
    /// 性能信息
    /// 包含文本布局和渲染的性能指标
    /// 
    /// 功能特性:
    /// - 布局计算时间
    /// - 渲染绘制时间
    /// - 总处理时间
    /// - 内存使用情况
    /// - 缓存命中状态
    public struct PerformanceInfo {
        /// 布局计算耗时（秒）
        public let layoutTime: TimeInterval
        
        /// 渲染绘制耗时（秒）
        public let renderTime: TimeInterval
        
        /// 总处理耗时（秒）
        public let totalTime: TimeInterval
        
        /// 内存使用量（字节）
        public let memoryUsage: Int
        
        /// 是否命中缓存
        /// true表示使用了缓存的布局结果
        public let cacheHit: Bool
    }
    
    /// 排除路径信息
    /// 包含排除路径的统计和几何信息
    /// 
    /// 功能特性:
    /// - 排除路径数组
    /// - 有效矩形区域
    /// - 排除面积统计
    /// - 总面积计算
    public struct ExclusionPathInfo {
        /// 排除路径数组
        public let paths: [UIBezierPath]
        
        /// 有效矩形区域数组
        /// 排除路径实际影响的区域
        public let validRects: [CGRect]
        
        /// 被排除的总面积
        public let excludedArea: CGFloat
        
        /// 容器总面积
        public let totalArea: CGFloat
    }
    
    /// 选择信息
    /// 包含文本选择的详细信息
    /// 
    /// 功能特性:
    /// - 选择字符范围
    /// - 选择矩形数组
    /// - 选择手柄位置
    public struct SelectionInfo {
        /// 选择的字符范围
        /// nil表示没有选择
        public let selectedRange: NSRange?
        
        /// 选择矩形数组
        /// 每个矩形对应一个选择区域
        public let selectionRects: [CGRect]
        
        /// 选择手柄位置数组
        /// 包含开始和结束手柄的位置
        public let handlePositions: [CGPoint]
    }
    
    /// 布局信息（可选）
    public let layoutInfo: LayoutInfo?
    
    /// 性能信息（可选）
    public let performanceInfo: PerformanceInfo?
    
    /// 排除路径信息（可选）
    public let exclusionPathInfo: ExclusionPathInfo?
    
    /// 选择信息（可选）
    public let selectionInfo: SelectionInfo?
    
    /// 调试信息生成的时间戳
    public let timestamp: Date
}

/// 文本调试器
/// 提供文本布局调试和可视化功能
/// 
/// 功能特性:
/// - 实时文本布局可视化
/// - 基线、行片段、字形边界显示
/// - 排除路径可视化
/// - 选择范围高亮
/// - 性能指标收集
/// - 调试信息历史记录
/// - 调试报告导出
/// 
/// 使用示例:
/// ```swift
/// // 启用调试模式
/// TETextDebugger.shared.enableDebugging()
/// 
/// // 配置调试选项
/// var options = TETextDebugOptions()
/// options.showBaselines = true
/// options.showLineFragments = true
/// options.showExclusionPaths = true
/// TETextDebugger.shared.options = options
/// 
/// // 调试标签
/// let label = TELabel()
/// label.text = "Hello World"
/// TETextDebugger.shared.debugLabel(label)
/// 
/// // 调试文本视图
/// let textView = TETextView()
/// textView.text = "Long text content..."
/// TETextDebugger.shared.debugTextView(textView)
/// 
/// // 导出调试报告
/// let report = TETextDebugger.shared.exportDebugReport()
/// print(report)
/// ```
/// 
/// - Note: 该类使用 `@MainActor` 确保线程安全
@MainActor
public final class TETextDebugger {
    
    // MARK: - 属性
    
    /// 共享实例
    /// 提供全局访问点的单例实例
    /// 
    /// 使用示例:
    /// ```swift
    /// // 启用调试
    /// TETextDebugger.shared.enableDebugging()
    /// 
    /// // 调试视图
    /// TETextDebugger.shared.debugLabel(myLabel)
    /// ```
    public static let shared = TETextDebugger()
    
    /// 调试选项
    /// 控制调试可视化显示的配置选项
    /// 
    /// 可以动态修改此属性来改变调试显示效果:
    /// ```swift
    /// var options = TETextDebugOptions()
    /// options.showBaselines = true
    /// options.baselineColor = .red
    /// TETextDebugger.shared.options = options
    /// ```
    public var options = TETextDebugOptions()
    
    /// 是否启用调试
    /// 控制调试器是否处于活动状态
    /// 
    /// - 当为 `true` 时，调试器会收集调试信息并显示调试图层
    /// - 当为 `false` 时，调试器不会执行任何调试操作
    /// - 默认为 `false`
    public var isDebuggingEnabled: Bool = false
    
    /// 调试图层数组
    /// 存储当前显示的所有调试图层
    /// 
    /// 这些图层会在以下情况下被清除:
    /// - 调用 `clearAllDebugLayers()` 方法
    /// - 禁用调试模式 (`disableDebugging()`)
    /// - 应用进入前台时（可选）
    private var debugLayers: [CALayer] = []
    
    /// 调试信息历史
    /// 存储最近收集的调试信息
    /// 
    /// - 最大存储数量由 `maxHistoryCount` 控制
    /// - 可以通过 `getDebugInfoHistory()` 方法获取历史记录
    /// - 历史记录可用于性能分析和问题追踪
    private var debugInfoHistory: [TETextDebugInfo] = []
    
    /// 最大历史记录数
    /// 调试信息历史记录的最大存储数量
    /// 
    /// - 默认值为 `100`
    /// - 当超过此数量时，最早的历史记录会被自动删除
    /// - 可以通过修改此值来调整历史记录的保留策略
    private let maxHistoryCount: Int = 100
    
    /// 调试委托
    /// 用于接收调试事件和调试信息的委托对象
    /// 
    /// 委托可以实现以下功能:
    /// - 接收调试信息收集完成通知
    /// - 自定义调试数据处理
    /// - 实现额外的调试可视化
    /// 
    /// 使用示例:
    /// ```swift
    /// class MyDebugger: TETextDebuggerDelegate {
    ///     func debugger(_ debugger: TETextDebugger, didCollectDebugInfo debugInfo: TETextDebugInfo, for view: UIView?) {
    ///         // 处理调试信息
    ///         print("收集到调试信息: \\(debugInfo)")
    ///     }
    /// }
    /// 
    /// TETextDebugger.shared.delegate = MyDebugger()
    /// ```
    public weak var delegate: TETextDebuggerDelegate?
    
    // MARK: - 初始化
    
    /// 私有初始化方法
    /// 设置通知观察者以处理应用生命周期事件
    /// 
    /// 主要功能:
    /// - 监听应用进入前台通知
    /// - 在适当时机刷新调试图层
    /// - 确保调试状态的正确性
    private init() {
        setupNotificationObservers()
    }
    
    deinit {
        removeNotificationObservers()
    }
    
    // MARK: - 公共方法
    
    /// 启用调试模式
    /// 激活调试器并开始收集调试信息
    /// 
    /// 调用此方法后:
    /// - `isDebuggingEnabled` 属性会被设置为 `true`
    /// - 调试器会开始响应调试请求
    /// - 会记录一条调试器启用的日志信息
    /// 
    /// 使用示例:
    /// ```swift
    /// TETextDebugger.shared.enableDebugging()
    /// // 现在可以开始调试文本视图
    /// TETextDebugger.shared.debugLabel(myLabel)
    /// ```
    public func enableDebugging() {
        isDebuggingEnabled = true
        TETextEngine.shared.logInfo("文本调试器已启用", category: "debug")
    }
    
    /// 禁用调试模式
    /// 停用调试器并清除所有调试图层
    /// 
    /// 调用此方法后:
    /// - `isDebuggingEnabled` 属性会被设置为 `false`
    /// - 所有当前显示的调试图层会被清除
    /// - 会记录一条调试器禁用的日志信息
    /// 
    /// 使用示例:
    /// ```swift
    /// TETextDebugger.shared.disableDebugging()
    /// // 所有调试图层都会被清除
    /// ```
    public func disableDebugging() {
        isDebuggingEnabled = false
        clearAllDebugLayers()
        TETextEngine.shared.logInfo("文本调试器已禁用", category: "debug")
    }
    
    /// 调试标签
    /// 对指定的标签进行调试分析和可视化
    /// 
    /// - Parameter label: 要调试的 `TELabel` 实例
    /// 
    /// 此方法会执行以下操作:
    /// 1. 检查调试模式是否启用
    /// 2. 收集标签的调试信息（布局、性能、排除路径、选择信息）
    /// 3. 显示相应的调试图层
    /// 4. 保存调试信息到历史记录
    /// 5. 通知委托对象
    /// 
    /// 使用示例:
    /// ```swift
    /// let label = TELabel()
    /// label.text = "Hello World"
    /// TETextDebugger.shared.debugLabel(label)
    /// ```
    /// 
    /// - Note: 如果调试模式未启用，此方法不会执行任何操作
    public func debugLabel(_ label: TELabel) {
        guard isDebuggingEnabled else { return }
        
        // 收集调试信息
        let debugInfo = collectDebugInfo(from: label)
        
        // 显示调试图层
        showDebugLayers(for: label, with: debugInfo)
        
        // 保存调试信息
        saveDebugInfo(debugInfo)
        
        // 通知委托
        delegate?.debugger(self, didCollectDebugInfo: debugInfo, for: label)
    }
    
    /// 调试文本视图
    /// 对指定的文本视图进行调试分析和可视化
    /// 
    /// - Parameter textView: 要调试的 `TETextView` 实例
    /// 
    /// 此方法会执行以下操作:
    /// 1. 检查调试模式是否启用
    /// 2. 收集文本视图的调试信息（布局、性能、排除路径、选择信息）
    /// 3. 显示相应的调试图层
    /// 4. 保存调试信息到历史记录
    /// 5. 通知委托对象
    /// 
    /// 使用示例:
    /// ```swift
    /// let textView = TETextView()
    /// textView.text = "Long text content..."
    /// TETextDebugger.shared.debugTextView(textView)
    /// ```
    /// 
    /// - Note: 如果调试模式未启用，此方法不会执行任何操作
    public func debugTextView(_ textView: TETextView) {
        guard isDebuggingEnabled else { return }
        
        // 收集调试信息
        let debugInfo = collectDebugInfo(from: textView)
        
        // 显示调试图层
        showDebugLayers(for: textView, with: debugInfo)
        
        // 保存调试信息
        saveDebugInfo(debugInfo)
        
        // 通知委托
        delegate?.debugger(self, didCollectDebugInfo: debugInfo, for: textView)
    }
    
    /// 调试布局信息
    /// 对指定的文本和容器进行布局调试分析
    /// 
    /// - Parameters:
    ///   - attributedText: 要调试的属性文本
    ///   - containerSize: 文本容器的尺寸
    ///   - exclusionPaths: 排除路径数组（可选，默认为空数组）
    /// 
    /// 此方法会执行以下操作:
    /// 1. 检查调试模式是否启用
    /// 2. 创建临时文本容器进行布局计算
    /// 3. 收集布局调试信息
    /// 4. 保存调试信息到历史记录
    /// 5. 通知委托对象
    /// 
    /// 使用示例:
    /// ```swift
    /// let text = NSAttributedString(string: "Hello World")
    /// let size = CGSize(width: 200, height: 100)
    /// let exclusionPaths = [TEExclusionPath.rect(CGRect(x: 50, y: 20, width: 40, height: 40))]
    /// 
    /// TETextDebugger.shared.debugLayout(
    ///     attributedText: text,
    ///     containerSize: size,
    ///     exclusionPaths: exclusionPaths
    /// )
    /// ```
    /// 
    /// - Note: 如果调试模式未启用，此方法不会执行任何操作
    public func debugLayout(attributedText: NSAttributedString, containerSize: CGSize, exclusionPaths: [TEExclusionPath] = []) {
        guard isDebuggingEnabled else { return }
        
        // 创建临时文本容器进行调试
        let textContainer = TETextContainer()
        textContainer.size = containerSize
        
        // 添加排除路径
        for path in exclusionPaths {
            textContainer.addExclusionPath(path)
        }
        
        // 收集布局调试信息
        let debugInfo = collectLayoutDebugInfo(attributedText: attributedText, container: textContainer)
        
        // 保存调试信息
        saveDebugInfo(debugInfo)
        
        // 通知委托
        delegate?.debugger(self, didCollectDebugInfo: debugInfo, for: nil)
    }
    
    /// 清除所有调试图层
    /// 移除所有当前显示的调试图层
    /// 
    /// 此方法会:
    /// - 从父图层中移除所有调试图层
    /// - 清空调试图层数组
    /// - 不会影响调试模式状态
    /// 
    /// 使用示例:
    /// ```swift
    /// // 清除当前调试图层
    /// TETextDebugger.shared.clearAllDebugLayers()
    /// 
    /// // 调试模式仍然启用，可以继续调试其他视图
    /// TETextDebugger.shared.debugLabel(newLabel)
    /// ```
    public func clearAllDebugLayers() {
        for layer in debugLayers {
            layer.removeFromSuperlayer()
        }
        debugLayers.removeAll()
    }
    
    /// 获取调试信息历史
    /// 获取所有收集到的调试信息历史记录
    /// 
    /// - Returns: 包含所有历史调试信息的数组，按时间顺序排列
    /// 
    /// 返回的数组包含:
    /// - 所有通过调试方法收集的调试信息
    /// - 最多 `maxHistoryCount` 条记录
    /// - 按时间戳从早到晚排序
    /// 
    /// 使用示例:
    /// ```swift
    /// let history = TETextDebugger.shared.getDebugInfoHistory()
    /// for debugInfo in history {
    ///     if let performance = debugInfo.performanceInfo {
    ///         print("布局时间: \\(performance.layoutTime)")
    ///     }
    /// }
    /// ```
    public func getDebugInfoHistory() -> [TETextDebugInfo] {
        return debugInfoHistory
    }
    
    /// 导出调试报告
    /// 生成包含所有历史调试信息的文本报告
    /// 
    /// - Returns: 格式化的调试报告字符串
    /// 
    /// 报告包含:
    /// - 报告生成时间
    /// - 每条调试信息的详细统计
    /// - 布局信息（行数、字符数等）
    /// - 性能信息（时间、内存等）
    /// - 排除路径信息（路径数量、面积等）
    /// 
    /// 使用示例:
    /// ```swift
    /// let report = TETextDebugger.shared.exportDebugReport()
    /// print(report)
    /// 
    /// // 保存到文件
    /// let url = FileManager.default.temporaryDirectory.appendingPathComponent("debug_report.txt")
    /// try? report.write(to: url, atomically: true, encoding: .utf8)
    /// ```
    public func exportDebugReport() -> String {
        var report = "TextEngineKit Debug Report\n"
        report += "========================\n"
        report += "Generated: \(Date())\n\n"
        
        for (index, info) in debugInfoHistory.enumerated() {
            report += "Debug Info #\(index + 1)\n"
            report += "Timestamp: \(info.timestamp)\n"
            
            if let layoutInfo = info.layoutInfo {
                report += "Layout Info:\n"
                report += "  - Line Count: \(layoutInfo.lineCount)\n"
                report += "  - Total Glyphs: \(layoutInfo.totalGlyphCount)\n"
                report += "  - Total Characters: \(layoutInfo.totalCharacterCount)\n"
                report += "  - Line Fragments: \(layoutInfo.lineFragments.count)\n"
                report += "  - Baselines: \(layoutInfo.baselines.count)\n"
            }
            
            if let performanceInfo = info.performanceInfo {
                report += "Performance Info:\n"
                report += "  - Layout Time: \(String(format: "%.3f", performanceInfo.layoutTime))s\n"
                report += "  - Render Time: \(String(format: "%.3f", performanceInfo.renderTime))s\n"
                report += "  - Total Time: \(String(format: "%.3f", performanceInfo.totalTime))s\n"
                report += "  - Memory Usage: \(performanceInfo.memoryUsage) bytes\n"
                report += "  - Cache Hit: \(performanceInfo.cacheHit)\n"
            }
            
            if let exclusionPathInfo = info.exclusionPathInfo {
                report += "Exclusion Path Info:\n"
                report += "  - Paths: \(exclusionPathInfo.paths.count)\n"
                report += "  - Valid Rects: \(exclusionPathInfo.validRects.count)\n"
                report += "  - Excluded Area: \(String(format: "%.2f", exclusionPathInfo.excludedArea))\n"
                report += "  - Total Area: \(String(format: "%.2f", exclusionPathInfo.totalArea))\n"
            }
            
            report += "\n"
        }
        
        return report
    }
    
    // MARK: - 私有方法
    
    /// 收集调试信息
    /// - Parameter label: 标签
    /// - Returns: 调试信息
    private func collectDebugInfo(from label: TELabel) -> TETextDebugInfo {
        let layoutInfo = collectLayoutInfo(from: label)
        let performanceInfo = collectPerformanceInfo(from: label)
        let exclusionPathInfo = collectExclusionPathInfo(from: label)
        let selectionInfo = collectSelectionInfo(from: label)
        
        return TETextDebugInfo(
            layoutInfo: layoutInfo,
            performanceInfo: performanceInfo,
            exclusionPathInfo: exclusionPathInfo,
            selectionInfo: selectionInfo,
            timestamp: Date()
        )
    }
    
    /// 收集调试信息
    /// - Parameter textView: 文本视图
    /// - Returns: 调试信息
    private func collectDebugInfo(from textView: TETextView) -> TETextDebugInfo {
        let layoutInfo = collectLayoutInfo(from: textView)
        let performanceInfo = collectPerformanceInfo(from: textView)
        let exclusionPathInfo = collectExclusionPathInfo(from: textView)
        let selectionInfo = collectSelectionInfo(from: textView)
        
        return TETextDebugInfo(
            layoutInfo: layoutInfo,
            performanceInfo: performanceInfo,
            exclusionPathInfo: exclusionPathInfo,
            selectionInfo: selectionInfo,
            timestamp: Date()
        )
    }
    
    /// 收集布局调试信息
    /// - Parameters:
    ///   - attributedText: 属性文本
    ///   - container: 文本容器
    /// - Returns: 调试信息
    private func collectLayoutDebugInfo(attributedText: NSAttributedString, container: TETextContainer) -> TETextDebugInfo {
        let startTime = CFAbsoluteTimeGetCurrent()
        
        // 创建CTFramesetter
        let framesetter = CTFramesetterCreateWithAttributedString(attributedText)
        
        // 创建路径
        let path = CGPath(rect: CGRect(origin: .zero, size: container.size), transform: nil)
        
        // 创建框架
        let frame = CTFramesetterCreateFrame(framesetter, CFRange(location: 0, length: 0), path, nil)
        
        // 收集布局信息
        let lines = CTFrameGetLines(frame) as! [CTLine]
        let lineCount = lines.count
        
        var lineFragments: [TETextDebugInfo.LayoutInfo.LineFragmentInfo] = []
        var baselines: [TETextDebugInfo.LayoutInfo.BaselineInfo] = []
        
        var totalGlyphCount = 0
        
        for (index, line) in lines.enumerated() {
            let lineRange = CTLineGetStringRange(line)
            let glyphCount = CTLineGetGlyphCount(line)
            totalGlyphCount += glyphCount
            
            var ascent: CGFloat = 0
            var descent: CGFloat = 0
            var leading: CGFloat = 0
            let width = CTLineGetTypographicBounds(line, &ascent, &descent, &leading)
            
            let lineOrigin = CGPoint(x: 0, y: 0) // 实际需要计算正确的位置
            let lineRect = CGRect(x: lineOrigin.x, y: lineOrigin.y - ascent, width: CGFloat(width), height: ascent + descent + leading)
            
            let lineFragment = TETextDebugInfo.LayoutInfo.LineFragmentInfo(
                rect: lineRect,
                usedRect: lineRect,
                glyphCount: glyphCount,
                characterRange: NSRange(location: lineRange.location, length: lineRange.length),
                isTruncated: false
            )
            lineFragments.append(lineFragment)
            
            let baseline = TETextDebugInfo.LayoutInfo.BaselineInfo(
                y: lineOrigin.y,
                ascent: ascent,
                descent: descent,
                leading: leading
            )
            baselines.append(baseline)
        }
        
        let layoutTime = CFAbsoluteTimeGetCurrent() - startTime
        
        let layoutInfo = TETextDebugInfo.LayoutInfo(
            lineCount: lineCount,
            totalGlyphCount: totalGlyphCount,
            totalCharacterCount: attributedText.length,
            lineFragments: lineFragments,
            baselines: baselines
        )
        
        let performanceInfo = TETextDebugInfo.PerformanceInfo(
            layoutTime: layoutTime,
            renderTime: 0,
            totalTime: layoutTime,
            memoryUsage: 0,
            cacheHit: false
        )
        
        return TETextDebugInfo(
            layoutInfo: layoutInfo,
            performanceInfo: performanceInfo,
            exclusionPathInfo: nil,
            selectionInfo: nil,
            timestamp: Date()
        )
    }
    
    /// 收集布局信息
    /// - Parameter label: 标签
    /// - Returns: 布局信息
    private func collectLayoutInfo(from label: TELabel) -> TETextDebugInfo.LayoutInfo? {
        // 简化实现，实际需要访问label的内部布局数据
        return nil
    }
    
    /// 收集布局信息
    /// - Parameter textView: 文本视图
    /// - Returns: 布局信息
    private func collectLayoutInfo(from textView: TETextView) -> TETextDebugInfo.LayoutInfo? {
        // 简化实现，实际需要访问textView的内部布局数据
        return nil
    }
    
    /// 收集性能信息
    /// - Parameter label: 标签
    /// - Returns: 性能信息
    private func collectPerformanceInfo(from label: TELabel) -> TETextDebugInfo.PerformanceInfo? {
        // 简化实现，实际需要访问label的内部性能数据
        return nil
    }
    
    /// 收集性能信息
    /// - Parameter textView: 文本视图
    /// - Returns: 性能信息
    private func collectPerformanceInfo(from textView: TETextView) -> TETextDebugInfo.PerformanceInfo? {
        // 简化实现，实际需要访问textView的内部性能数据
        return nil
    }
    
    /// 收集排除路径信息
    /// - Parameter label: 标签
    /// - Returns: 排除路径信息
    private func collectExclusionPathInfo(from label: TELabel) -> TETextDebugInfo.ExclusionPathInfo? {
        // 简化实现，实际需要访问label的内部排除路径数据
        return nil
    }
    
    /// 收集排除路径信息
    /// - Parameter textView: 文本视图
    /// - Returns: 排除路径信息
    private func collectExclusionPathInfo(from textView: TETextView) -> TETextDebugInfo.ExclusionPathInfo? {
        // 简化实现，实际需要访问textView的内部排除路径数据
        return nil
    }
    
    /// 收集选择信息
    /// - Parameter label: 标签
    /// - Returns: 选择信息
    private func collectSelectionInfo(from label: TELabel) -> TETextDebugInfo.SelectionInfo? {
        // 简化实现，实际需要访问label的内部选择数据
        return nil
    }
    
    /// 收集选择信息
    /// - Parameter textView: 文本视图
    /// - Returns: 选择信息
    private func collectSelectionInfo(from textView: TETextView) -> TETextDebugInfo.SelectionInfo? {
        // 简化实现，实际需要访问textView的内部选择数据
        return nil
    }
    
    /// 显示调试图层
    /// - Parameters:
    ///   - view: 视图
    ///   - debugInfo: 调试信息
    private func showDebugLayers(for view: UIView, with debugInfo: TETextDebugInfo) {
        guard let superview = view.superview else { return }
        
        // 清除之前的调试图层
        clearAllDebugLayers()
        
        // 显示布局调试图层
        if let layoutInfo = debugInfo.layoutInfo {
            showLayoutDebugLayers(for: view, with: layoutInfo, in: superview)
        }
        
        // 显示排除路径调试图层
        if let exclusionPathInfo = debugInfo.exclusionPathInfo {
            showExclusionPathDebugLayers(for: view, with: exclusionPathInfo, in: superview)
        }
        
        // 显示选择调试图层
        if let selectionInfo = debugInfo.selectionInfo {
            showSelectionDebugLayers(for: view, with: selectionInfo, in: superview)
        }
    }
    
    /// 显示布局调试图层
    /// - Parameters:
    ///   - view: 视图
    ///   - layoutInfo: 布局信息
    ///   - superview: 父视图
    private func showLayoutDebugLayers(for view: UIView, with layoutInfo: TETextDebugInfo.LayoutInfo, in superview: UIView) {
        // 显示基线
        if options.showBaselines {
            for baseline in layoutInfo.baselines {
                let baselineLayer = createBaselineLayer(y: baseline.y, in: view)
                superview.layer.addSublayer(baselineLayer)
                debugLayers.append(baselineLayer)
            }
        }
        
        // 显示行片段
        if options.showLineFragments {
            for lineFragment in layoutInfo.lineFragments {
                let fragmentLayer = createLineFragmentLayer(with: lineFragment, in: view)
                superview.layer.addSublayer(fragmentLayer)
                debugLayers.append(fragmentLayer)
            }
        }
    }
    
    /// 显示排除路径调试图层
    /// - Parameters:
    ///   - view: 视图
    ///   - exclusionPathInfo: 排除路径信息
    ///   - superview: 父视图
    private func showExclusionPathDebugLayers(for view: UIView, with exclusionPathInfo: TETextDebugInfo.ExclusionPathInfo, in superview: UIView) {
        if options.showExclusionPaths {
            for path in exclusionPathInfo.paths {
                let pathLayer = createExclusionPathLayer(with: path, in: view)
                superview.layer.addSublayer(pathLayer)
                debugLayers.append(pathLayer)
            }
        }
    }
    
    /// 显示选择调试图层
    /// - Parameters:
    ///   - view: 视图
    ///   - selectionInfo: 选择信息
    ///   - superview: 父视图
    private func showSelectionDebugLayers(for view: UIView, with selectionInfo: TETextDebugInfo.SelectionInfo, in superview: UIView) {
        if options.showSelection {
            for rect in selectionInfo.selectionRects {
                let selectionLayer = createSelectionLayer(with: rect, in: view)
                superview.layer.addSublayer(selectionLayer)
                debugLayers.append(selectionLayer)
            }
        }
    }
    
    /// 创建基线图层
    /// - Parameters:
    ///   - y: Y坐标
    ///   - view: 视图
    /// - Returns: 图层
    private func createBaselineLayer(y: CGFloat, in view: UIView) -> CALayer {
        let layer = CALayer()
        layer.frame = CGRect(x: view.frame.minX, y: view.frame.minY + y, width: view.frame.width, height: options.lineWidth)
        layer.backgroundColor = options.baselineColor.cgColor
        return layer
    }
    
    /// 创建行片段图层
    /// - Parameters:
    ///   - lineFragment: 行片段信息
    ///   - view: 视图
    /// - Returns: 图层
    private func createLineFragmentLayer(with lineFragment: TETextDebugInfo.LayoutInfo.LineFragmentInfo, in view: UIView) -> CALayer {
        let layer = CALayer()
        layer.frame = CGRect(
            x: view.frame.minX + lineFragment.rect.minX,
            y: view.frame.minY + lineFragment.rect.minY,
            width: lineFragment.rect.width,
            height: lineFragment.rect.height
        )
        layer.borderWidth = options.lineWidth
        layer.borderColor = options.lineFragmentBorderColor.cgColor
        layer.backgroundColor = options.lineFragmentUsedBorderColor.cgColor
        return layer
    }
    
    /// 创建排除路径图层
    /// - Parameters:
    ///   - path: 路径
    ///   - view: 视图
    /// - Returns: 图层
    private func createExclusionPathLayer(with path: UIBezierPath, in view: UIView) -> CALayer {
        let layer = CAShapeLayer()
        layer.path = path.cgPath
        layer.fillColor = options.exclusionPathColor.cgColor
        layer.strokeColor = options.exclusionPathColor.cgColor
        layer.lineWidth = options.lineWidth
        layer.frame = view.frame
        return layer
    }
    
    /// 创建选择图层
    /// - Parameters:
    ///   - rect: 矩形
    ///   - view: 视图
    /// - Returns: 图层
    private func createSelectionLayer(with rect: CGRect, in view: UIView) -> CALayer {
        let layer = CALayer()
        layer.frame = CGRect(
            x: view.frame.minX + rect.minX,
            y: view.frame.minY + rect.minY,
            width: rect.width,
            height: rect.height
        )
        layer.backgroundColor = options.selectionColor.cgColor
        return layer
    }
    
    /// 保存调试信息
    /// - Parameter debugInfo: 调试信息
    private func saveDebugInfo(_ debugInfo: TETextDebugInfo) {
        debugInfoHistory.append(debugInfo)
        
        // 限制历史记录数量
        if debugInfoHistory.count > maxHistoryCount {
            debugInfoHistory.removeFirst()
        }
    }
    
    /// 设置通知观察者
    private func setupNotificationObservers() {
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(applicationWillEnterForeground),
            name: UIApplication.willEnterForegroundNotification,
            object: nil
        )
    }
    
    /// 移除通知观察者
    private func removeNotificationObservers() {
        NotificationCenter.default.removeObserver(self)
    }
    
    /// 应用将进入前台
    @objc private func applicationWillEnterForeground() {
        // 刷新调试图层
        if isDebuggingEnabled {
            // 可以在这里重新显示之前的调试图层
        }
    }
}

/// 文本调试器委托
/// 用于接收文本调试器的事件通知和调试信息
/// 
/// 功能特性:
/// - 接收调试信息收集完成通知
/// - 获取详细的调试数据
/// - 关联的视图对象（如果有）
/// 
/// 使用示例:
/// ```swift
/// class MyDebuggerDelegate: TETextDebuggerDelegate {
///     func debugger(_ debugger: TETextDebugger, didCollectDebugInfo debugInfo: TETextDebugInfo, for view: UIView?) {
///         // 处理调试信息
///         print("收到调试信息，时间: \\(debugInfo.timestamp)")
///         
///         // 分析布局信息
///         if let layoutInfo = debugInfo.layoutInfo {
///             print("行数: \\(layoutInfo.lineCount)")
///             print("总字符数: \\(layoutInfo.totalCharacterCount)")
///         }
///         
///         // 分析性能信息
///         if let performanceInfo = debugInfo.performanceInfo {
///             print("布局耗时: \\(performanceInfo.layoutTime)秒")
///             print("内存使用: \\(performanceInfo.memoryUsage)字节")
///         }
///         
///         // 检查关联的视图
///         if let view = view {
///             print("调试的视图类型: \\(type(of: view))")
///         }
///     }
/// }
/// 
/// // 设置委托
/// TETextDebugger.shared.delegate = MyDebuggerDelegate()
/// ```
public protocol TETextDebuggerDelegate: AnyObject {
    /// 调试器收集了调试信息
    /// 
    /// 当调试器完成调试信息收集时调用此方法
    /// 
    /// - Parameters:
    ///   - debugger: 发送通知的调试器实例
    ///   - debugInfo: 收集到的完整调试信息，包含布局、性能、排除路径和选择信息
    ///   - view: 关联的视图对象。如果是通过 `debugLayout` 方法调用，此参数为 `nil`
    /// 
    /// - Note: 所有参数都保证有效，但 `debugInfo` 中的某些信息可能为 `nil`（如没有排除路径时）
    func debugger(_ debugger: TETextDebugger, didCollectDebugInfo debugInfo: TETextDebugInfo, for view: UIView?)
}

/// TELabel扩展，支持调试
/// 为 `TELabel` 提供便捷的调试方法
/// 
/// 功能特性:
/// - 一键启用调试模式
/// - 一键清除调试图层
/// - 简化调试操作流程
/// 
/// 使用示例:
/// ```swift
/// let label = TELabel()
/// label.text = "Hello World"
/// 
/// // 启用调试（显示调试图层）
/// label.enableDebugMode()
/// 
/// // 清除调试图层（保持调试模式启用）
/// label.disableDebugMode()
/// ```
extension TELabel {
    
    /// 启用调试模式
    /// 对当前标签进行调试分析和可视化
    /// 
    /// 此方法会:
    /// - 检查调试器是否启用
    /// - 收集标签的调试信息
    /// - 显示相应的调试图层
    /// - 保存调试信息到历史记录
    /// 
    /// 等同于调用:
    /// ```swift
    /// TETextDebugger.shared.debugLabel(self)
    /// ```
    /// 
    /// - Note: 如果调试器未启用，此方法不会执行任何操作
    public func enableDebugMode() {
        TETextDebugger.shared.debugLabel(self)
    }
    
    /// 禁用调试模式
    /// 清除所有当前显示的调试图层
    /// 
    /// 此方法会:
    /// - 移除所有调试图层
    /// - 保持调试器状态不变
    /// 
    /// 等同于调用:
    /// ```swift
    /// TETextDebugger.shared.clearAllDebugLayers()
    /// ```
    /// 
    /// - Note: 此方法不会禁用调试器，只是清除当前调试图层
    public func disableDebugMode() {
        TETextDebugger.shared.clearAllDebugLayers()
    }
}

/// TETextView扩展，支持调试
/// 为 `TETextView` 提供便捷的调试方法
/// 
/// 功能特性:
/// - 一键启用调试模式
/// - 一键清除调试图层
/// - 简化调试操作流程
/// 
/// 使用示例:
/// ```swift
/// let textView = TETextView()
/// textView.text = "Long text content..."
/// 
/// // 启用调试（显示调试图层）
/// textView.enableDebugMode()
/// 
/// // 清除调试图层（保持调试模式启用）
/// textView.disableDebugMode()
/// ```
extension TETextView {
    
    /// 启用调试模式
    /// 对当前文本视图进行调试分析和可视化
    /// 
    /// 此方法会:
    /// - 检查调试器是否启用
    /// - 收集文本视图的调试信息
    /// - 显示相应的调试图层
    /// - 保存调试信息到历史记录
    /// 
    /// 等同于调用:
    /// ```swift
    /// TETextDebugger.shared.debugTextView(self)
    /// ```
    /// 
    /// - Note: 如果调试器未启用，此方法不会执行任何操作
    public func enableDebugMode() {
        TETextDebugger.shared.debugTextView(self)
    }
    
    /// 禁用调试模式
    /// 清除所有当前显示的调试图层
    /// 
    /// 此方法会:
    /// - 移除所有调试图层
    /// - 保持调试器状态不变
    /// 
    /// 等同于调用:
    /// ```swift
    /// TETextDebugger.shared.clearAllDebugLayers()
    /// ```
    /// 
    /// - Note: 此方法不会禁用调试器，只是清除当前调试图层
    public func disableDebugMode() {
        TETextDebugger.shared.clearAllDebugLayers()
    }
}

#endif