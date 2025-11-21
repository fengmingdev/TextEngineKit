//
//  TETextDebugger.swift
//  TextEngineKit
//
//  Created by Assistant on 2025/11/21.
//
//  调试可视化工具：提供文本布局调试和可视化功能，参考MPITextKit设计
//

#if canImport(UIKit)
import UIKit
import Foundation
import CoreText
import CoreGraphics

/// 文本调试选项
/// 配置文本布局调试和可视化显示的选项
public struct TETextDebugOptions {
    /// 是否启用基线显示
    /// 
    /// 当设置为 `true` 时，会在文本视图中显示红色的水平基线，
    /// 帮助开发者理解文本的垂直对齐和行高计算。
    /// 
    /// 默认值为 `true`。
    /// 
    /// 使用示例:
    /// ```swift
    /// var options = TETextDebugOptions()
    /// options.showBaselines = true  // 显示文本基线
    /// ```
    public var showBaselines: Bool = true
    
    /// 基线颜色
    /// 
    /// 控制基线显示的颜色。默认使用半透明的红色 (`UIColor.red.withAlphaComponent(0.5)`)。
    /// 
    /// 使用示例:
    /// ```swift
    /// var options = TETextDebugOptions()
    /// options.baselineColor = .blue.withAlphaComponent(0.7)  // 使用蓝色基线
    /// ```
    public var baselineColor: UIColor = UIColor.red.withAlphaComponent(0.5)
    
    /// 是否显示行片段边界
    /// 
    /// 当设置为 `true` 时，会显示每个行片段的完整边界矩形（红色）
    /// 和实际使用矩形（蓝色），帮助分析文本换行和布局行为。
    /// 
    /// 默认值为 `true`。
    /// 
    /// 使用示例:
    /// ```swift
    /// var options = TETextDebugOptions()
    /// options.showLineFragments = true  // 显示行片段边界
    /// ```
    public var showLineFragments: Bool = true
    
    /// 行片段边界颜色
    /// 
    /// 控制行片段完整边界的显示颜色。默认使用半透明的红色。
    /// 
    /// 使用示例:
    /// ```swift
    /// var options = TETextDebugOptions()
    /// options.lineFragmentBorderColor = .green.withAlphaComponent(0.3)  // 使用绿色边界
    /// ```
    public var lineFragmentBorderColor: UIColor = UIColor.red.withAlphaComponent(0.2)
    
    /// 已使用的行片段边界颜色
    /// 
    /// 控制行片段实际使用区域的显示颜色。默认使用半透明的蓝色。
    /// 这个区域通常比完整矩形小，因为可能存在空白区域。
    /// 
    /// 使用示例:
    /// ```swift
    /// var options = TETextDebugOptions()
    /// options.lineFragmentUsedBorderColor = .orange.withAlphaComponent(0.4)  // 使用橙色
    /// ```
    public var lineFragmentUsedBorderColor: UIColor = UIColor.blue.withAlphaComponent(0.2)
    
    /// 是否显示字形边界
    /// 
    /// 当设置为 `true` 时，会显示每个字形的边界矩形，
    /// 用于精确的字符级布局分析。由于可能影响性能，默认关闭。
    /// 
    /// 默认值为 `false`。
    /// 
    /// 使用示例:
    /// ```swift
    /// var options = TETextDebugOptions()
    /// options.showGlyphs = true  // 启用字形边界显示（性能开销较大）
    /// ```
    public var showGlyphs: Bool = false
    
    /// 字形边界颜色
    /// 
    /// 控制字形边界矩形的显示颜色。默认使用半透明的橙色。
    /// 
    /// 使用示例:
    /// ```swift
    /// var options = TETextDebugOptions()
    /// options.glyphBorderColor = .purple.withAlphaComponent(0.5)  // 使用紫色字形边界
    /// ```
    public var glyphBorderColor: UIColor = UIColor.orange.withAlphaComponent(0.2)
    
    /// 是否显示排除路径
    /// 
    /// 当设置为 `true` 时，会显示所有排除路径的形状和范围，
    /// 帮助分析文本如何围绕图像或其他元素进行排版。
    /// 
    /// 默认值为 `true`。
    /// 
    /// 使用示例:
    /// ```swift
    /// var options = TETextDebugOptions()
    /// options.showExclusionPaths = true  // 显示排除路径
    /// ```
    public var showExclusionPaths: Bool = true
    
    /// 排除路径颜色
    /// 
    /// 控制排除路径的显示颜色。默认使用半透明的紫色。
    /// 
    /// 使用示例:
    /// ```swift
    /// var options = TETextDebugOptions()
    /// options.exclusionPathColor = .red.withAlphaComponent(0.4)  // 使用红色排除路径
    /// ```
    public var exclusionPathColor: UIColor = UIColor.purple.withAlphaComponent(0.3)
    
    /// 是否显示选择范围
    /// 
    /// 当设置为 `true` 时，会显示当前文本选择的高亮区域，
    /// 包括选择矩形和选择手柄位置。
    /// 
    /// 默认值为 `true`。
    /// 
    /// 使用示例:
    /// ```swift
    /// var options = TETextDebugOptions()
    /// options.showSelection = true  // 显示文本选择范围
    /// ```
    public var showSelection: Bool = true
    
    /// 选择范围颜色
    /// 
    /// 控制选择范围的显示颜色。默认使用半透明的系统黄色。
    /// 
    /// 使用示例:
    /// ```swift
    /// var options = TETextDebugOptions()
    /// options.selectionColor = .systemBlue.withAlphaComponent(0.3)  // 使用蓝色选择范围
    /// ```
    public var selectionColor: UIColor = UIColor.systemYellow.withAlphaComponent(0.3)
    
    /// 是否显示附件
    /// 
    /// 当设置为 `true` 时，会显示文本附件（如图像、自定义视图）的边界矩形，
    /// 帮助分析附件布局和文本环绕效果。
    /// 
    /// 默认值为 `true`。
    /// 
    /// 使用示例:
    /// ```swift
    /// var options = TETextDebugOptions()
    /// options.showAttachments = true  // 显示文本附件
    /// ```
    public var showAttachments: Bool = true
    
    /// 附件颜色
    /// 
    /// 控制附件边界矩形的显示颜色。默认使用半透明的绿色。
    /// 
    /// 使用示例:
    /// ```swift
    /// var options = TETextDebugOptions()
    /// options.attachmentColor = .blue.withAlphaComponent(0.6)  // 使用蓝色附件边界
    /// ```
    public var attachmentColor: UIColor = UIColor.green.withAlphaComponent(0.5)
    
    /// 是否显示高亮
    /// 
    /// 当设置为 `true` 时，会显示文本高亮区域（如搜索高亮、语法高亮等），
    /// 帮助分析高亮效果的布局和覆盖范围。
    /// 
    /// 默认值为 `true`。
    /// 
    /// 使用示例:
    /// ```swift
    /// var options = TETextDebugOptions()
    /// options.showHighlights = true  // 显示文本高亮
    /// ```
    public var showHighlights: Bool = true
    
    /// 高亮颜色
    /// 
    /// 控制高亮区域的显示颜色。默认使用半透明的系统粉色。
    /// 
    /// 使用示例:
    /// ```swift
    /// var options = TETextDebugOptions()
    /// options.highlightColor = .systemTeal.withAlphaComponent(0.4)  // 使用蓝绿色高亮
    /// ```
    public var highlightColor: UIColor = UIColor.systemPink.withAlphaComponent(0.3)
    
    /// 线宽
    /// 
    /// 控制所有调试线条的宽度。默认值为 `1.0`。
    /// 
    /// 使用示例:
    /// ```swift
    /// var options = TETextDebugOptions()
    /// options.lineWidth = 2.0  // 使用更粗的线条
    /// ```
    public var lineWidth: CGFloat = 1.0
    
    /// 字体大小（用于调试文本）
    /// 
    /// 控制调试信息文本的字体大小。默认值为 `10.0`。
    /// 设置为 `0` 可禁用调试文本显示。
    /// 
    /// 使用示例:
    /// ```swift
    /// var options = TETextDebugOptions()
    /// options.debugFontSize = 12.0  // 使用更大的调试文本
    /// ```
    public var debugFontSize: CGFloat = 10.0
    
    /// 调试文本颜色
    /// 
    /// 控制调试信息文本的颜色。默认值为黑色。
    /// 
    /// 使用示例:
    /// ```swift
    /// var options = TETextDebugOptions()
    /// options.debugTextColor = .white  // 使用白色调试文本（适合深色背景）
    /// ```
    public var debugTextColor: UIColor = .black
    
    public init() {}
}

/// 调试信息
/// 包含文本布局、性能、排除路径和选择信息的综合调试数据
public struct TETextDebugInfo {
    /// 布局信息
    public let layoutInfo: LayoutInfo
    
    /// 性能信息
    public let performanceInfo: PerformanceInfo
    
    /// 排除路径信息
    public let exclusionPathInfo: ExclusionPathInfo
    
    /// 选择信息
    public let selectionInfo: SelectionInfo
    
    /// 布局信息结构
    public struct LayoutInfo {
        /// 文本容器信息
        public let container: ContainerInfo
        
        /// 行片段信息数组
        public let lineFragments: [LineFragmentInfo]
        
        /// 基线信息数组
        public let baselines: [BaselineInfo]
        
        /// 字形信息数组（如果启用）
        public let glyphs: [GlyphInfo]
        
        /// 附件信息数组
        public let attachments: [AttachmentInfo]
        
        /// 高亮信息数组
        public let highlights: [HighlightInfo]
    }
    
    /// 容器信息
    public struct ContainerInfo {
        /// 容器大小
        public let size: CGSize
        
        /// 内边距
        public let insets: UIEdgeInsets
        
        /// 排除路径数量
        public let exclusionPathCount: Int
        
        /// 文本对齐方式
        public let alignment: NSTextAlignment
        
        /// 行间距
        public let lineSpacing: CGFloat
        
        /// 段落间距
        public let paragraphSpacing: CGFloat
    }
    
    /// 行片段信息
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
    
    /// 字形信息
    public struct GlyphInfo {
        /// 字形的边界矩形
        public let rect: CGRect
        
        /// 字形对应的字符索引
        public let characterIndex: Int
        
        /// 字形ID
        public let glyphID: CGGlyph
        
        /// 字体信息
        public let font: UIFont
    }
    
    /// 附件信息
    public struct AttachmentInfo {
        /// 附件的边界矩形
        public let rect: CGRect
        
        /// 附件类型
        public let type: String
        
        /// 附件的图像（如果有）
        public let image: UIImage?
        
        /// 附件的文件路径（如果有）
        public let filePath: String?
    }
    
    /// 高亮信息
    public struct HighlightInfo {
        /// 高亮的边界矩形数组
        public let rects: [CGRect]
        
        /// 高亮的颜色
        public let color: UIColor
        
        /// 高亮对应的字符范围
        public let characterRange: NSRange
        
        /// 高亮类型（背景色、下划线等）
        public let type: String
    }
    
    /// 性能信息
    /// 包含文本布局和渲染的性能指标
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
    public struct SelectionInfo {
        /// 选择的字符范围
        /// nil表示没有选择
        public let selectedRange: NSRange?
        
        /// 选择矩形数组
        /// 每个矩形对应一个选择区域
        public let selectionRects: [CGRect]
        
        /// 选择手柄位置
        public let handlePositions: (start: CGPoint, end: CGPoint)?
        
        /// 选择颜色
        public let selectionColor: UIColor
    }
}

/// 文本调试器委托
public protocol TETextDebuggerDelegate: AnyObject {
    /// 调试信息更新时调用
    func debugger(_ debugger: TETextDebugger, didUpdateDebugInfo info: TETextDebugInfo)
    
    /// 调试模式状态改变时调用
    func debugger(_ debugger: TETextDebugger, didChangeDebuggingState isDebugging: Bool)
}

/// 文本调试器
/// 提供文本布局的可视化调试功能，参考MPITextKit设计
/// 
/// `TETextDebugger` 是一个强大的文本布局调试工具，提供多种可视化选项来帮助开发者
/// 理解和优化文本布局。它支持实时显示基线、行片段、字形、排除路径、选择范围、
/// 附件和高亮等文本布局元素。
/// 
/// 功能特性:
/// - 实时文本布局可视化
/// - 多种调试元素显示（基线、行片段、字形等）
/// - 性能监控集成
/// - 可配置的显示选项
/// - 委托模式支持状态更新
/// - 线程安全的 `@MainActor` 实现
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
/// options.baselineColor = .red
/// TETextDebugger.shared.updateOptions(options)
/// 
/// // 调试标签
/// let label = TELabel()
/// TETextDebugger.shared.debugLabel(label)
/// 
/// // 设置委托接收调试信息更新
/// class MyViewController: UIViewController, TETextDebuggerDelegate {
///     func viewDidLoad() {
///         super.viewDidLoad()
///         TETextDebugger.shared.delegate = self
///     }
///     
///     func debugger(_ debugger: TETextDebugger, didUpdateDebugInfo info: TETextDebugInfo) {
///         print("布局时间: \\(info.performanceInfo.layoutTime)s")
///         print("渲染时间: \\(info.performanceInfo.renderTime)s")
///     }
/// }
/// ```
/// 
/// - Important: 此类使用 `@MainActor` 注解，确保所有操作都在主线程执行。
/// - Note: 使用单例模式，通过 `TETextDebugger.shared` 访问共享实例。
/// - SeeAlso: `TETextDebugOptions`, `TETextDebugInfo`, `TETextDebuggerDelegate`
@MainActor
public final class TETextDebugger: NSObject {
    
    // MARK: - 属性
    
    /// 共享实例
    /// 
    /// `TETextDebugger` 使用单例模式，通过此属性访问全局共享实例。
    /// 
    /// 使用示例:
    /// ```swift
    /// let debugger = TETextDebugger.shared
    /// debugger.enableDebugging()
    /// ```
    public static let shared = TETextDebugger()
    
    /// 调试选项
    /// 
    /// 控制调试器的行为和显示效果。可以通过 `updateOptions(_:)` 方法动态更新。
    /// 
    /// 使用示例:
    /// ```swift
    /// var options = TETextDebugOptions()
    /// options.showBaselines = true
    /// options.baselineColor = .red
    /// TETextDebugger.shared.updateOptions(options)
    /// ```
    public var options = TETextDebugOptions()
    
    /// 委托
    /// 
    /// 接收调试信息更新和调试状态变化的通知。设置为 `nil` 可禁用委托回调。
    /// 
    /// 使用示例:
    /// ```swift
    /// class MyController: TETextDebuggerDelegate {
    ///     func viewDidLoad() {
    ///         TETextDebugger.shared.delegate = self
    ///     }
    /// }
    /// ```
    public weak var delegate: TETextDebuggerDelegate?
    
    /// 是否正在调试
    private var isDebugging = false
    
    /// 调试图层字典
    private var debugLayers: [UIView: [CALayer]] = [:]
    
    /// 性能分析器
    private let performanceProfiler = TEPerformanceProfiler.shared
    
    // MARK: - 生命周期
    
    private override init() {
        super.init()
    }
    
    deinit {}
    
    // MARK: - 公共方法
    
    /// 启用调试模式
    /// 
    /// 启动文本布局调试功能，开始性能监控，并通知委托调试状态变化。
    /// 如果调试模式已经启用，此方法不会产生任何效果。
    /// 
    /// 使用示例:
    /// ```swift
    /// TETextDebugger.shared.enableDebugging()
    /// ```
    /// 
    /// - Note: 此方法会自动启动性能分析器。
    /// - SeeAlso: `disableDebugging()`, `refreshDebugging()`
    public func enableDebugging() {
        guard !isDebugging else { return }
        
        isDebugging = true
        delegate?.debugger(self, didChangeDebuggingState: true)
        
        // 启动性能监控
        performanceProfiler.startProfiling()
    }
    
    /// 禁用调试模式
    /// 
    /// 停止文本布局调试功能，清除所有调试图层，停止性能监控，
    /// 并通知委托调试状态变化。如果调试模式已经禁用，此方法不会产生任何效果。
    /// 
    /// 使用示例:
    /// ```swift
    /// TETextDebugger.shared.disableDebugging()
    /// ```
    /// 
    /// - Note: 此方法会自动停止性能分析器并清除所有调试图层。
    /// - SeeAlso: `enableDebugging()`, `refreshDebugging()`
    public func disableDebugging() {
        guard isDebugging else { return }
        
        isDebugging = false
        
        // 清除所有调试图层
        clearAllDebugLayers()
        
        // 停止性能监控
        performanceProfiler.stopProfiling()
        
        delegate?.debugger(self, didChangeDebuggingState: false)
    }
    
    /// 更新调试选项
    /// 
    /// 动态更新调试器的行为和显示效果。如果调试模式当前已启用，
    /// 会自动重新应用新的选项设置。
    /// 
    /// - Parameter options: 新的调试选项配置
    /// 
    /// 使用示例:
    /// ```swift
    /// var newOptions = TETextDebugOptions()
    /// newOptions.showBaselines = false  // 隐藏基线
    /// newOptions.showLineFragments = true  // 显示行片段
    /// TETextDebugger.shared.updateOptions(newOptions)
    /// ```
    /// 
    /// - Note: 如果调试模式已启用，会自动刷新所有调试视图。
    /// - SeeAlso: `TETextDebugOptions`
    public func updateOptions(_ options: TETextDebugOptions) {
        self.options = options
        
        // 如果正在调试，重新应用选项
        if isDebugging {
            refreshDebugging()
        }
    }
    
    /// 调试标签
    /// 
    /// 对指定的 `TELabel` 应用调试可视化。会清除现有的调试图层，
    /// 获取最新的调试信息，并应用相应的可视化效果。
    /// 
    /// - Parameter label: 要调试的文本标签
    /// 
    /// 使用示例:
    /// ```swift
    /// let label = TELabel()
    /// label.text = "Hello, World!"
    /// TETextDebugger.shared.debugLabel(label)
    /// ```
    /// 
    /// - Note: 仅在调试模式启用时有效。
    /// - SeeAlso: `debugTextView(_:)`, `getDebugInfo(for:)`
    public func debugLabel(_ label: TELabel) {
        guard isDebugging else { return }
        
        // 清除现有的调试图层
        clearDebugLayers(for: label)
        
        // 获取调试信息
        let debugInfo = getDebugInfo(for: label)
        
        // 应用调试可视化
        applyDebugVisualization(to: label, with: debugInfo)
        
        delegate?.debugger(self, didUpdateDebugInfo: debugInfo)
    }
    
    /// 调试文本视图
    /// 
    /// 对指定的 `TETextView` 应用调试可视化。会清除现有的调试图层，
    /// 获取最新的调试信息，并应用相应的可视化效果。
    /// 
    /// - Parameter textView: 要调试的文本视图
    /// 
    /// 使用示例:
    /// ```swift
    /// let textView = TETextView()
    /// textView.text = "Hello, World!"
    /// TETextDebugger.shared.debugTextView(textView)
    /// ```
    /// 
    /// - Note: 仅在调试模式启用时有效。
    /// - SeeAlso: `debugLabel(_:)`, `getDebugInfo(for:)`
    public func debugTextView(_ textView: TETextView) {
        guard isDebugging else { return }
        
        // 清除现有的调试图层
        clearDebugLayers(for: textView)
        
        // 获取调试信息
        let debugInfo = getDebugInfo(for: textView)
        
        // 应用调试可视化
        applyDebugVisualization(to: textView, with: debugInfo)
        
        delegate?.debugger(self, didUpdateDebugInfo: debugInfo)
    }
    
    /// 获取调试信息
    /// 
    /// 收集指定视图的全面调试信息，包括布局、性能、排除路径和选择信息。
    /// 
    /// - Parameter view: 要分析的视图（`TELabel` 或 `TETextView`）
    /// - Returns: 包含完整调试信息的 `TETextDebugInfo` 结构体
    /// 
    /// 使用示例:
    /// ```swift
    /// let label = TELabel()
    /// let debugInfo = TETextDebugger.shared.getDebugInfo(for: label)
    /// print("布局时间: \\(debugInfo.performanceInfo.layoutTime)s")
    /// print("排除路径数量: \\(debugInfo.exclusionPathInfo.paths.count)")
    /// ```
    /// 
    /// - Note: 此方法会收集所有可用的调试信息，不受当前选项设置影响。
    /// - SeeAlso: `TETextDebugInfo`, `debugLabel(_:)`, `debugTextView(_:)`
    public func getDebugInfo(for view: UIView) -> TETextDebugInfo {
        // 布局信息
        let layoutInfo = getLayoutInfo(for: view)
        
        // 性能信息
        let performanceInfo = getPerformanceInfo(for: view)
        
        // 排除路径信息
        let exclusionPathInfo = getExclusionPathInfo(for: view)
        
        // 选择信息
        let selectionInfo = getSelectionInfo(for: view)
        
        return TETextDebugInfo(
            layoutInfo: layoutInfo,
            performanceInfo: performanceInfo,
            exclusionPathInfo: exclusionPathInfo,
            selectionInfo: selectionInfo
        )
    }
    
    /// 刷新调试
    /// 
    /// 重新应用调试可视化到所有已调试的视图。通常在更新调试选项后调用，
    /// 以确保新的设置立即生效。
    /// 
    /// 使用示例:
    /// ```swift
    /// // 更新选项后刷新调试显示
    /// TETextDebugger.shared.updateOptions(newOptions)
    /// TETextDebugger.shared.refreshDebugging()  // 立即应用新设置
    /// ```
    /// 
    /// - Note: 仅在调试模式启用时有效。
    /// - SeeAlso: `enableDebugging()`, `disableDebugging()`, `updateOptions(_:)`
    public func refreshDebugging() {
        guard isDebugging else { return }
        
        // 重新应用调试到所有已调试的视图
        for (view, _) in debugLayers {
            if let label = view as? TELabel {
                debugLabel(label)
            } else if let textView = view as? TETextView {
                debugTextView(textView)
            }
        }
    }
    
    // MARK: - 私有方法
    
    private func clearAllDebugLayers() {
        for (view, layers) in debugLayers {
            for layer in layers {
                layer.removeFromSuperlayer()
            }
        }
        debugLayers.removeAll()
    }
    
    private func clearDebugLayers(for view: UIView) {
        if let layers = debugLayers[view] {
            for layer in layers {
                layer.removeFromSuperlayer()
            }
            debugLayers.removeValue(forKey: view)
        }
    }
    
    private func applyDebugVisualization(to view: UIView, with debugInfo: TETextDebugInfo) {
        var layers: [CALayer] = []
        
        // 显示基线
        if options.showBaselines {
            let baselineLayers = createBaselineLayers(for: debugInfo.layoutInfo.baselines, in: view)
            layers.append(contentsOf: baselineLayers)
        }
        
        // 显示行片段
        if options.showLineFragments {
            let lineFragmentLayers = createLineFragmentLayers(for: debugInfo.layoutInfo.lineFragments, in: view)
            layers.append(contentsOf: lineFragmentLayers)
        }
        
        // 显示字形
        if options.showGlyphs {
            let glyphLayers = createGlyphLayers(for: debugInfo.layoutInfo.glyphs, in: view)
            layers.append(contentsOf: glyphLayers)
        }
        
        // 显示排除路径
        if options.showExclusionPaths {
            let exclusionPathLayers = createExclusionPathLayers(for: debugInfo.exclusionPathInfo, in: view)
            layers.append(contentsOf: exclusionPathLayers)
        }
        
        // 显示选择
        if options.showSelection {
            let selectionLayers = createSelectionLayers(for: debugInfo.selectionInfo, in: view)
            layers.append(contentsOf: selectionLayers)
        }
        
        // 显示附件
        if options.showAttachments {
            let attachmentLayers = createAttachmentLayers(for: debugInfo.layoutInfo.attachments, in: view)
            layers.append(contentsOf: attachmentLayers)
        }
        
        // 显示高亮
        if options.showHighlights {
            let highlightLayers = createHighlightLayers(for: debugInfo.layoutInfo.highlights, in: view)
            layers.append(contentsOf: highlightLayers)
        }
        
        // 添加到视图
        for layer in layers {
            view.layer.addSublayer(layer)
        }
        
        // 保存调试图层引用
        debugLayers[view] = layers
    }
    
    private func createBaselineLayers(for baselines: [TETextDebugInfo.BaselineInfo], in view: UIView) -> [CALayer] {
        var layers: [CALayer] = []
        
        for baseline in baselines {
            let layer = CALayer()
            layer.frame = CGRect(x: 0, y: baseline.y, width: view.bounds.width, height: options.lineWidth)
            layer.backgroundColor = options.baselineColor.cgColor
            
            layers.append(layer)
        }
        
        return layers
    }
    
    private func createLineFragmentLayers(for fragments: [TETextDebugInfo.LineFragmentInfo], in view: UIView) -> [CALayer] {
        var layers: [CALayer] = []
        
        for fragment in fragments {
            // 完整矩形
            let fullLayer = CALayer()
            fullLayer.frame = fragment.rect
            fullLayer.borderWidth = options.lineWidth
            fullLayer.borderColor = options.lineFragmentBorderColor.cgColor
            fullLayer.backgroundColor = options.lineFragmentBorderColor.cgColor.copy(alpha: 0.1)
            layers.append(fullLayer)
            
            // 使用矩形
            let usedLayer = CALayer()
            usedLayer.frame = fragment.usedRect
            usedLayer.borderWidth = options.lineWidth
            usedLayer.borderColor = options.lineFragmentUsedBorderColor.cgColor
            usedLayer.backgroundColor = options.lineFragmentUsedBorderColor.cgColor.copy(alpha: 0.1)
            layers.append(usedLayer)
            
            // 添加调试文本
            if options.debugFontSize > 0 {
                let textLayer = CATextLayer()
                textLayer.string = "L:\(fragment.characterRange.location)-\(fragment.characterRange.location + fragment.characterRange.length) G:\(fragment.glyphCount)"
                textLayer.fontSize = options.debugFontSize
                textLayer.foregroundColor = options.debugTextColor.cgColor
                textLayer.frame = CGRect(x: fragment.rect.origin.x + 2, y: fragment.rect.origin.y - options.debugFontSize - 2, width: 100, height: options.debugFontSize + 4)
                layers.append(textLayer)
            }
        }
        
        return layers
    }
    
    private func createGlyphLayers(for glyphs: [TETextDebugInfo.GlyphInfo], in view: UIView) -> [CALayer] {
        var layers: [CALayer] = []
        
        for glyph in glyphs {
            let layer = CALayer()
            layer.frame = glyph.rect
            layer.borderWidth = options.lineWidth
            layer.borderColor = options.glyphBorderColor.cgColor
            layer.backgroundColor = options.glyphBorderColor.cgColor.copy(alpha: 0.1)
            
            layers.append(layer)
        }
        
        return layers
    }
    
    private func createExclusionPathLayers(for exclusionPathInfo: TETextDebugInfo.ExclusionPathInfo, in view: UIView) -> [CALayer] {
        var layers: [CALayer] = []
        
        for path in exclusionPathInfo.paths {
            let shapeLayer = CAShapeLayer()
            shapeLayer.path = path.cgPath
            shapeLayer.fillColor = options.exclusionPathColor.cgColor.copy(alpha: 0.2)
            shapeLayer.strokeColor = options.exclusionPathColor.cgColor
            shapeLayer.lineWidth = options.lineWidth
            
            layers.append(shapeLayer)
        }
        
        return layers
    }
    
    private func createSelectionLayers(for selectionInfo: TETextDebugInfo.SelectionInfo, in view: UIView) -> [CALayer] {
        var layers: [CALayer] = []
        
        for rect in selectionInfo.selectionRects {
            let layer = CALayer()
            layer.frame = rect
            layer.backgroundColor = selectionInfo.selectionColor.cgColor.copy(alpha: 0.3)
            layer.borderWidth = options.lineWidth
            layer.borderColor = selectionInfo.selectionColor.cgColor
            
            layers.append(layer)
        }
        
        return layers
    }
    
    private func createAttachmentLayers(for attachments: [TETextDebugInfo.AttachmentInfo], in view: UIView) -> [CALayer] {
        var layers: [CALayer] = []
        
        for attachment in attachments {
            let layer = CALayer()
            layer.frame = attachment.rect
            layer.borderWidth = options.lineWidth
            layer.borderColor = options.attachmentColor.cgColor
            layer.backgroundColor = options.attachmentColor.cgColor.copy(alpha: 0.2)
            
            layers.append(layer)
        }
        
        return layers
    }
    
    private func createHighlightLayers(for highlights: [TETextDebugInfo.HighlightInfo], in view: UIView) -> [CALayer] {
        var layers: [CALayer] = []
        
        for highlight in highlights {
            for rect in highlight.rects {
                let layer = CALayer()
                layer.frame = rect
                layer.backgroundColor = highlight.color.cgColor.copy(alpha: 0.3)
                layer.borderWidth = options.lineWidth
                layer.borderColor = highlight.color.cgColor
                
                layers.append(layer)
            }
        }
        
        return layers
    }
    
    // MARK: - 调试信息获取
    
    private func getLayoutInfo(for view: UIView) -> TETextDebugInfo.LayoutInfo {
        // 这里需要根据实际的文本视图获取布局信息
        // 暂时返回模拟数据
        
        let containerInfo = TETextDebugInfo.ContainerInfo(
            size: view.bounds.size,
            insets: .zero,
            exclusionPathCount: 0,
            alignment: .natural,
            lineSpacing: 0,
            paragraphSpacing: 0
        )
        
        let lineFragments = [
            TETextDebugInfo.LineFragmentInfo(
                rect: CGRect(x: 0, y: 0, width: view.bounds.width, height: 20),
                usedRect: CGRect(x: 0, y: 0, width: view.bounds.width * 0.8, height: 20),
                glyphCount: 50,
                characterRange: NSRange(location: 0, length: 50),
                isTruncated: false
            )
        ]
        
        let baselines = [
            TETextDebugInfo.BaselineInfo(y: 15, ascent: 12, descent: 4, leading: 2)
        ]
        
        return TETextDebugInfo.LayoutInfo(
            container: containerInfo,
            lineFragments: lineFragments,
            baselines: baselines,
            glyphs: [],
            attachments: [],
            highlights: []
        )
    }
    
    private func getPerformanceInfo(for view: UIView) -> TETextDebugInfo.PerformanceInfo {
        // 这里需要从性能分析器获取实际的性能信息
        // 暂时返回模拟数据
        return TETextDebugInfo.PerformanceInfo(
            layoutTime: 0.001,
            renderTime: 0.002,
            totalTime: 0.003,
            memoryUsage: 1024,
            cacheHit: true
        )
    }
    
    private func getExclusionPathInfo(for view: UIView) -> TETextDebugInfo.ExclusionPathInfo {
        // 这里需要从实际的文本布局获取排除路径信息
        // 暂时返回空数据
        return TETextDebugInfo.ExclusionPathInfo(
            paths: [],
            validRects: [],
            excludedArea: 0,
            totalArea: view.bounds.width * view.bounds.height
        )
    }
    
    private func getSelectionInfo(for view: UIView) -> TETextDebugInfo.SelectionInfo {
        // 这里需要从文本选择管理器获取选择信息
        // 暂时返回空数据
        return TETextDebugInfo.SelectionInfo(
            selectedRange: nil,
            selectionRects: [],
            handlePositions: nil,
            selectionColor: .systemYellow
        )
    }
}

#endif
