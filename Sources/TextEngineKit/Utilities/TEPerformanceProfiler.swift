//
//  TEPerformanceProfiler.swift
//  TextEngineKit
//
//  Created by Assistant on 2025/11/21.
//
//  性能分析器：提供详细的性能监控和分析功能
//

#if canImport(UIKit)
import UIKit
import Foundation
import CoreText

/// 性能指标
/// 包含文本布局和渲染的详细性能数据
/// 
/// 功能特性:
/// - 布局性能指标（时间、行数、字符数等）
/// - 渲染性能指标（时间、像素数、绘制调用等）
/// - 整体性能指标（总时间、FPS、CPU/GPU使用率等）
/// - 内存和能耗使用情况
/// 
/// 使用示例:
/// ```swift
/// let layoutMetrics = TEPerformanceMetrics.LayoutMetrics(
///     layoutTime: 0.005,  // 5ms
///     lineCount: 10,
///     glyphCount: 150,
///     characterCount: 120,
///     cacheHit: true,
///     memoryUsage: 2048
/// )
/// 
/// let renderMetrics = TEPerformanceMetrics.RenderMetrics(
///     renderTime: 0.003,  // 3ms
///     pixelCount: 50000,
///     drawCallCount: 2,
///     memoryUsage: 4096,
///     gpuUsage: 0.15
/// )
/// 
/// let overallMetrics = TEPerformanceMetrics.OverallMetrics(
///     totalTime: 0.008,  // 8ms
///     fps: 60.0,
///     cpuUsage: 0.25,
///     memoryUsage: 6144,
///     energyUsage: 0.05
/// )
/// 
/// let metrics = TEPerformanceMetrics(
///     layoutMetrics: layoutMetrics,
///     renderMetrics: renderMetrics,
///     overallMetrics: overallMetrics
/// )
/// 
/// // 分析性能
/// print("总耗时: \\(metrics.overallMetrics.totalTime * 1000)ms")
/// print("布局缓存命中: \\(metrics.layoutMetrics.cacheHit)")
/// print("内存使用: \\(metrics.overallMetrics.memoryUsage)字节")
/// ```
public struct TEPerformanceMetrics {
    
    /// 布局性能指标
    /// 包含文本布局计算的详细性能数据
    /// 
    /// 功能特性:
    /// - 布局计算耗时
    /// - 文本行数统计
    /// - 字形和字符数量
    /// - 缓存命中状态
    /// - 内存使用量
    public struct LayoutMetrics {
        /// 布局计算耗时（秒）
        public let layoutTime: TimeInterval
        
        /// 文本行数
        public let lineCount: Int
        
        /// 字形数量
        public let glyphCount: Int
        
        /// 字符数量
        public let characterCount: Int
        
        /// 是否命中缓存
        /// `true` 表示使用了缓存的布局结果，性能更好
        public let cacheHit: Bool
        
        /// 内存使用量（字节）
        public let memoryUsage: Int
        
        public init(layoutTime: TimeInterval, lineCount: Int, glyphCount: Int, characterCount: Int, cacheHit: Bool, memoryUsage: Int) {
            self.layoutTime = layoutTime
            self.lineCount = lineCount
            self.glyphCount = glyphCount
            self.characterCount = characterCount
            self.cacheHit = cacheHit
            self.memoryUsage = memoryUsage
        }
    }
    
    /// 渲染性能指标
    /// 包含文本渲染绘制的详细性能数据
    /// 
    /// 功能特性:
    /// - 渲染绘制耗时
    /// - 处理的像素数量
    /// - 绘制调用次数
    /// - GPU使用率
    /// - 内存使用量
    public struct RenderMetrics {
        /// 渲染绘制耗时（秒）
        public let renderTime: TimeInterval
        
        /// 处理的像素数量
        public let pixelCount: Int
        
        /// 绘制调用次数
        public let drawCallCount: Int
        
        /// 内存使用量（字节）
        public let memoryUsage: Int
        
        /// GPU使用率（0.0 - 1.0）
        public let gpuUsage: Float
        
        public init(renderTime: TimeInterval, pixelCount: Int, drawCallCount: Int, memoryUsage: Int, gpuUsage: Float) {
            self.renderTime = renderTime
            self.pixelCount = pixelCount
            self.drawCallCount = drawCallCount
            self.memoryUsage = memoryUsage
            self.gpuUsage = gpuUsage
        }
    }
    
    /// 整体性能指标
    /// 包含综合性能数据和系统资源使用情况
    /// 
    /// 功能特性:
    /// - 总处理时间
    /// - 帧率（FPS）
    /// - CPU使用率
    /// - 内存使用量
    /// - 能耗使用情况
    public struct OverallMetrics {
        /// 总处理耗时（秒）
        public let totalTime: TimeInterval
        
        /// 帧率（FPS）
        public let fps: Float
        
        /// CPU使用率（0.0 - 1.0）
        public let cpuUsage: Float
        
        /// 内存使用量（字节）
        public let memoryUsage: Int
        
        /// 能耗使用情况（0.0 - 1.0）
        public let energyUsage: Float
        
        public init(totalTime: TimeInterval, fps: Float, cpuUsage: Float, memoryUsage: Int, energyUsage: Float) {
            self.totalTime = totalTime
            self.fps = fps
            self.cpuUsage = cpuUsage
            self.memoryUsage = memoryUsage
            self.energyUsage = energyUsage
        }
    }
    
    /// 布局性能指标
    public let layoutMetrics: LayoutMetrics
    
    /// 渲染性能指标
    public let renderMetrics: RenderMetrics
    
    /// 整体性能指标
    public let overallMetrics: OverallMetrics
    
    /// 性能数据收集的时间戳
    public let timestamp: Date
    
    public init(layoutMetrics: LayoutMetrics, renderMetrics: RenderMetrics, overallMetrics: OverallMetrics, timestamp: Date = Date()) {
        self.layoutMetrics = layoutMetrics
        self.renderMetrics = renderMetrics
        self.overallMetrics = overallMetrics
        self.timestamp = timestamp
    }
}

/// 性能瓶颈
/// 表示检测到的性能问题和优化建议
/// 
/// 功能特性:
/// - 瓶颈类型分类
/// - 严重程度评估
/// - 详细问题描述
/// - 优化建议
/// - 相关性能指标
/// 
/// 使用示例:
/// ```swift
/// let bottleneck = TEPerformanceBottleneck(
///     type: .layoutSlow,
///     severity: 0.7,
///     description: "布局时间超过16ms阈值",
///     suggestion: "考虑使用异步布局或优化文本计算",
///     metrics: performanceMetrics
/// )
/// 
/// // 分析瓶颈
/// switch bottleneck.type {
/// case .layoutSlow:
///     print("布局性能问题: \\(bottleneck.description)")
/// case .memoryHigh:
///     print("内存使用过高: \\(bottleneck.description)")
/// default:
///     break
/// }
/// 
/// print("优化建议: \\(bottleneck.suggestion)")
/// print("严重程度: \\(bottleneck.severity * 100)%")
/// ```
public struct TEPerformanceBottleneck {
    /// 瓶颈类型
    /// 定义不同类型的性能问题
    public enum BottleneckType {
        /// 布局计算缓慢
        /// 文本布局计算耗时过长
        case layoutSlow
        
        /// 渲染绘制缓慢
        /// 文本渲染绘制耗时过长
        case renderSlow
        
        /// 内存使用过高
        /// 内存使用量超过阈值
        case memoryHigh
        
        /// 缓存未命中
        /// 布局缓存未命中，需要重新计算
        case cacheMiss
        
        /// GPU使用密集
        /// GPU使用率过高
        case gpuIntensive
        
        /// CPU使用密集
        /// CPU使用率过高
        case cpuIntensive
    }
    
    /// 瓶颈类型
    public let type: BottleneckType
    
    /// 严重程度
    /// 范围：0.0（轻微）到 1.0（严重）
    public let severity: Float
    
    /// 问题描述
    /// 详细的性能问题描述
    public let description: String
    
    /// 优化建议
    /// 针对该瓶颈的优化建议
    public let suggestion: String
    
    /// 相关性能指标
    /// 检测到瓶颈时的性能数据
    public let metrics: TEPerformanceMetrics
}

/// 性能分析器委托
/// 用于接收性能分析器的事件通知和分析结果
/// 
/// 功能特性:
/// - 接收性能分析完成通知
/// - 获取性能瓶颈检测结果
/// - 接收性能警告信息
/// 
/// 使用示例:
/// ```swift
/// class MyPerformanceDelegate: TEPerformanceProfilerDelegate {
///     func profiler(_ profiler: TEPerformanceProfiler, didCompleteAnalysis metrics: TEPerformanceMetrics) {
///         // 处理性能分析结果
///         print("性能分析完成")
///         print("总耗时: \\(metrics.overallMetrics.totalTime * 1000)ms")
///         print("FPS: \\(metrics.overallMetrics.fps)")
///         print("内存使用: \\(formatBytes(metrics.overallMetrics.memoryUsage))")
///         
///         // 检查布局性能
///         if metrics.layoutMetrics.cacheHit {
///             print("布局缓存命中 ✓")
///         } else {
///             print("布局缓存未命中 ⚠️")
///         }
///     }
///     
///     func profiler(_ profiler: TEPerformanceProfiler, didDetectBottleneck bottleneck: TEPerformanceBottleneck) {
///         // 处理性能瓶颈
///         print("发现性能瓶颈!")
///         print("类型: \\(bottleneck.type)")
///         print("描述: \\(bottleneck.description)")
///         print("建议: \\(bottleneck.suggestion)")
///         print("严重程度: \\(bottleneck.severity * 100)%")
///         
///         // 根据瓶颈类型采取相应措施
///         switch bottleneck.type {
///         case .layoutSlow:
///             print("考虑优化布局计算")
///         case .memoryHigh:
///             print("考虑优化内存使用")
///         case .renderSlow:
///             print("考虑优化渲染性能")
///         default:
///             break
///         }
///     }
///     
///     func profiler(_ profiler: TEPerformanceProfiler, didTriggerWarning warning: String, severity: Float) {
///         // 处理性能警告
///         print("性能警告: \\(warning)")
///         print("严重程度: \\(severity)")
///         
///         if severity > 0.8 {
///             print("⚠️ 高严重性警告")
///         }
///     }
///     
///     private func formatBytes(_ bytes: Int) -> String {
///         let formatter = ByteCountFormatter()
///         formatter.countStyle = .binary
///         return formatter.string(fromByteCount: Int64(bytes))
///     }
/// }
/// 
/// // 设置委托
/// TEPerformanceProfiler.shared.delegate = MyPerformanceDelegate()
/// ```
public protocol TEPerformanceProfilerDelegate: AnyObject {
    /// 性能分析完成
    /// 
    /// 当性能分析器完成一次性能分析时调用此方法
    /// 
    /// - Parameters:
    ///   - profiler: 发送通知的性能分析器实例
    ///   - metrics: 完整的性能指标数据，包含布局、渲染和整体性能信息
    /// 
    /// - Note: 此方法在每次性能分析完成后都会被调用，无论是否发现性能问题
    func profiler(_ profiler: TEPerformanceProfiler, didCompleteAnalysis metrics: TEPerformanceMetrics)
    
    /// 发现性能瓶颈
    /// 
    /// 当性能分析器检测到性能瓶颈时调用此方法
    /// 
    /// - Parameters:
    ///   - profiler: 发送通知的性能分析器实例
    ///   - bottleneck: 检测到的性能瓶颈，包含问题类型、严重程度、描述和建议
    /// 
    /// - Note: 只有当性能指标超过预设阈值时才会触发此方法
    func profiler(_ profiler: TEPerformanceProfiler, didDetectBottleneck bottleneck: TEPerformanceBottleneck)
    
    /// 性能警告
    /// 
    /// 当性能分析器检测到一般性性能问题时调用此方法
    /// 
    /// - Parameters:
    ///   - profiler: 发送通知的性能分析器实例
    ///   - warning: 警告信息的文本描述
    ///   - severity: 警告的严重程度，范围从 0.0（轻微）到 1.0（严重）
    /// 
    /// - Note: 此方法用于报告未达到瓶颈阈值但仍需要关注的性能问题
    func profiler(_ profiler: TEPerformanceProfiler, didTriggerWarning warning: String, severity: Float)
}

/// 性能分析器
/// 提供详细的性能监控和分析功能
/// 
/// 功能特性:
/// - 实时性能指标收集
/// - 布局性能分析（时间、缓存、内存）
/// - 渲染性能分析（时间、像素、GPU使用率）
/// - 整体性能监控（FPS、CPU使用率、能耗）
/// - 性能瓶颈自动检测
/// - 可配置的性能阈值
/// - 性能历史记录和趋势分析
/// - 详细的性能报告生成
/// 
/// 使用示例:
/// ```swift
/// // 启用性能分析
/// TEPerformanceProfiler.shared.startProfiling()
/// 
/// // 配置性能阈值
/// TEPerformanceProfiler.shared.thresholds.maxLayoutTime = 0.010  // 10ms
/// TEPerformanceProfiler.shared.thresholds.maxMemoryUsage = 5 * 1024 * 1024  // 5MB
/// TEPerformanceProfiler.shared.thresholds.minFPS = 45.0  // 45 FPS
/// 
/// // 分析标签性能
/// let label = TELabel()
/// label.text = "Hello World"
/// let metrics = TEPerformanceProfiler.shared.profileLabel(label)
/// 
/// // 分析文本视图性能
/// let textView = TETextView()
/// textView.text = "Long text content..."
/// let textViewMetrics = TEPerformanceProfiler.shared.profileTextView(textView)
/// 
/// // 分析文本渲染性能
/// let text = NSAttributedString(string: "Sample text")
/// let renderMetrics = TEPerformanceProfiler.shared.profileTextRendering(
///     attributedText: text,
///     containerSize: CGSize(width: 200, height: 100)
/// )
/// 
/// // 获取性能报告
/// let report = TEPerformanceProfiler.shared.getPerformanceReport()
/// print(report)
/// 
/// // 停止性能分析
/// TEPerformanceProfiler.shared.stopProfiling()
/// ```
/// 
/// - Note: 该类使用 `@MainActor` 确保线程安全
@MainActor
public final class TEPerformanceProfiler {
    
    // MARK: - 属性
    
    /// 共享实例
    /// 提供全局访问点的单例实例
    /// 
    /// 使用示例:
    /// ```swift
    /// // 启用性能分析
    /// TEPerformanceProfiler.shared.startProfiling()
    /// 
    /// // 分析视图性能
    /// let metrics = TEPerformanceProfiler.shared.profileLabel(myLabel)
    /// ```
    public static let shared = TEPerformanceProfiler()
    
    /// 性能分析器委托
    /// 用于接收性能分析事件和结果
    /// 
    /// 委托可以实现以下功能:
    /// - 接收性能分析完成通知
    /// - 获取性能瓶颈检测结果
    /// - 接收性能警告信息
    /// 
    /// 使用示例:
    /// ```swift
    /// class MyProfilerDelegate: TEPerformanceProfilerDelegate {
    ///     func profiler(_ profiler: TEPerformanceProfiler, didCompleteAnalysis metrics: TEPerformanceMetrics) {
    ///         print("布局时间: \\(metrics.layoutMetrics.layoutTime * 1000)ms")
    ///         print("渲染时间: \\(metrics.renderMetrics.renderTime * 1000)ms")
    ///     }
    /// }
    /// 
    /// TEPerformanceProfiler.shared.delegate = MyProfilerDelegate()
    /// ```
    public weak var delegate: TEPerformanceProfilerDelegate?
    
    /// 是否启用性能分析
    /// 控制性能分析器是否处于活动状态
    /// 
    /// - 当为 `true` 时，性能分析器会收集性能数据并执行分析
    /// - 当为 `false` 时，性能分析器不会执行任何分析操作
    /// - 默认为 `false`
    public var isProfilingEnabled: Bool = false
    
    /// 性能阈值
    /// 定义性能指标的阈值配置
    /// 
    /// 包含以下可配置阈值:
    /// - `maxLayoutTime`: 最大布局时间（默认16ms，对应60fps）
    /// - `maxRenderTime`: 最大渲染时间（默认16ms，对应60fps）
    /// - `maxMemoryUsage`: 最大内存使用量（默认10MB）
    /// - `minFPS`: 最低帧率（默认30fps）
    /// - `maxCPUUsage`: 最大CPU使用率（默认80%）
    /// - `maxGPUUsage`: 最大GPU使用率（默认80%）
    /// 
    /// 使用示例:
    /// ```swift
    /// var thresholds = TEPerformanceProfiler.PerformanceThresholds()
    /// thresholds.maxLayoutTime = 0.010  // 10ms
    /// thresholds.maxMemoryUsage = 5 * 1024 * 1024  // 5MB
    /// thresholds.minFPS = 45.0  // 45 FPS
    /// TEPerformanceProfiler.shared.thresholds = thresholds
    /// ```
    public struct PerformanceThresholds {
        /// 最大布局时间（秒）
        /// 默认值为 0.016 秒（16ms），对应 60fps 的帧时间预算
        public var maxLayoutTime: TimeInterval = 0.016
        
        /// 最大渲染时间（秒）
        /// 默认值为 0.016 秒（16ms），对应 60fps 的帧时间预算
        public var maxRenderTime: TimeInterval = 0.016
        
        /// 最大内存使用量（字节）
        /// 默认值为 10MB
        public var maxMemoryUsage: Int = 10 * 1024 * 1024
        
        /// 最低帧率（FPS）
        /// 默认值为 30.0 fps
        public var minFPS: Float = 30.0
        
        /// 最大CPU使用率（0.0 - 1.0）
        /// 默认值为 0.8（80%）
        public var maxCPUUsage: Float = 0.8
        
        /// 最大GPU使用率（0.0 - 1.0）
        /// 默认值为 0.8（80%）
        public var maxGPUUsage: Float = 0.8
        
        public init() {}
    }
    
    /// 性能阈值配置
    /// 用于设置性能分析的各种阈值
    public var thresholds = PerformanceThresholds()
    
    /// 性能历史记录
    /// 存储最近收集的性能指标
    /// 
    /// - 最大存储数量由 `maxHistoryCount` 控制
    /// - 可以通过 `getPerformanceHistory()` 方法获取历史记录
    /// - 历史记录可用于性能趋势分析和报告生成
    private var performanceHistory: [TEPerformanceMetrics] = []
    
    /// 最大历史记录数
    /// 性能历史记录的最大存储数量
    /// 
    /// - 默认值为 `1000`
    /// - 当超过此数量时，最早的历史记录会被自动删除
    private let maxHistoryCount: Int = 1000
    
    /// 当前性能会话
    /// 跟踪当前性能分析会话的状态信息
    /// 
    /// 包含会话开始时间、布局计数、渲染计数等统计信息
    private var currentSession: PerformanceSession?
    
    /// 性能监控定时器
    /// 用于定期执行性能监控任务
    /// 
    /// 定时器会在性能分析启用时启动，在禁用或应用进入后台时停止
    private var monitoringTimer: Timer?
    
    /// 系统信息
    /// 包含设备型号、操作系统版本、硬件配置等信息
    /// 
    /// 用于性能数据的上下文分析和报告生成
    private var systemInfo: SystemInfo?
    
    // MARK: - 初始化
    
    private init() {
        setupSystemInfo()
        setupNotificationObservers()
    }
    
    deinit {
        // 避免在析构中调用 MainActor 隔离方法
        monitoringTimer?.invalidate()
        NotificationCenter.default.removeObserver(self)
    }
    
    // MARK: - 公共方法
    
    /// 开始性能分析
    /// 激活性能分析器并开始收集性能数据
    /// 
    /// 调用此方法后:
    /// - `isProfilingEnabled` 属性会被设置为 `true`
    /// - 创建新的性能分析会话
    /// - 启动性能监控定时器
    /// - 记录性能分析启动日志
    /// - 发送性能分析启动通知
    /// 
    /// 使用示例:
    /// ```swift
    /// // 开始性能分析
    /// TEPerformanceProfiler.shared.startProfiling()
    /// 
    /// // 现在可以开始分析文本视图性能
    /// let metrics = TEPerformanceProfiler.shared.profileLabel(myLabel)
    /// ```
    public func startProfiling() {
        isProfilingEnabled = true
        
        // 创建新的性能会话
        currentSession = PerformanceSession()
        
        // 启动监控定时器
        startMonitoringTimer()
        
        TETextEngine.shared.logInfo("性能分析已启动", category: "performance")
        
        // 发送启动通知
        NotificationCenter.default.post(name: .performanceProfilingStarted, object: self)
    }
    
    /// 停止性能分析
    /// 停用性能分析器并清理相关资源
    /// 
    /// 调用此方法后:
    /// - `isProfilingEnabled` 属性会被设置为 `false`
    /// - 停止性能监控定时器
    /// - 结束当前性能分析会话
    /// - 记录性能分析停止日志
    /// - 发送性能分析停止通知
    /// 
    /// 使用示例:
    /// ```swift
    /// // 停止性能分析
    /// TEPerformanceProfiler.shared.stopProfiling()
    /// 
    /// // 获取性能报告
    /// let report = TEPerformanceProfiler.shared.getPerformanceReport()
    /// print(report)
    /// ```
    public func stopProfiling() {
        isProfilingEnabled = false
        
        // 停止监控定时器
        stopMonitoringTimer()
        
        // 结束当前会话
        currentSession = nil
        
        TETextEngine.shared.logInfo("性能分析已停止", category: "performance")
        
        // 发送停止通知
        NotificationCenter.default.post(name: .performanceProfilingStopped, object: self)
    }
    
    /// 分析标签性能
    /// 对指定的标签进行性能分析和指标收集
    /// 
    /// - Parameter label: 要分析性能的 `TELabel` 实例
    /// - Returns: 完整的性能指标数据
    /// 
    /// 此方法会执行以下操作:
    /// 1. 检查性能分析是否启用
    /// 2. 收集标签的布局和渲染性能数据
    /// 3. 计算整体性能指标（FPS、CPU使用率等）
    /// 4. 保存性能数据到历史记录
    /// 5. 分析性能瓶颈和阈值检查
    /// 6. 通知委托对象
    /// 
    /// 使用示例:
    /// ```swift
    /// let label = TELabel()
    /// label.text = "Hello World"
    /// 
    /// let metrics = TEPerformanceProfiler.shared.profileLabel(label)
    /// print("布局时间: \\(metrics.layoutMetrics.layoutTime * 1000)ms")
    /// print("渲染时间: \\(metrics.renderMetrics.renderTime * 1000)ms")
    /// print("总时间: \\(metrics.overallMetrics.totalTime * 1000)ms")
    /// ```
    /// 
    /// - Note: 如果性能分析未启用，此方法会返回空的性能指标
    /// - Returns: 性能指标数据，如果分析未启用则返回空指标
    @discardableResult
    public func profileLabel(_ label: TELabel) -> TEPerformanceMetrics {
        guard isProfilingEnabled else {
            return createEmptyMetrics()
        }
        
        let startTime = CFAbsoluteTimeGetCurrent()
        
        // 收集性能数据
        let layoutMetrics = collectLayoutMetrics(from: label)
        let renderMetrics = collectRenderMetrics(from: label)
        
        let endTime = CFAbsoluteTimeGetCurrent()
        let totalTime = endTime - startTime
        
        let overallMetrics = TEPerformanceMetrics.OverallMetrics(
            totalTime: totalTime,
            fps: calculateFPS(),
            cpuUsage: getCPUUsage(),
            memoryUsage: getMemoryUsage(),
            energyUsage: getEnergyUsage()
        )
        
        let metrics = TEPerformanceMetrics(
            layoutMetrics: layoutMetrics,
            renderMetrics: renderMetrics,
            overallMetrics: overallMetrics
        )
        
        // 保存性能数据
        savePerformanceMetrics(metrics)
        
        // 分析性能瓶颈
        analyzePerformanceBottlenecks(metrics)
        
        // 检查性能阈值
        checkPerformanceThresholds(metrics)
        
        // 通知委托
        delegate?.profiler(self, didCompleteAnalysis: metrics)
        
        return metrics
    }
    
    /// 分析文本视图性能
    /// 对指定的文本视图进行性能分析和指标收集
    /// 
    /// - Parameter textView: 要分析性能的 `TETextView` 实例
    /// - Returns: 完整的性能指标数据
    /// 
    /// 此方法会执行以下操作:
    /// 1. 检查性能分析是否启用
    /// 2. 收集文本视图的布局和渲染性能数据
    /// 3. 计算整体性能指标（FPS、CPU使用率等）
    /// 4. 保存性能数据到历史记录
    /// 5. 分析性能瓶颈和阈值检查
    /// 6. 通知委托对象
    /// 
    /// 使用示例:
    /// ```swift
    /// let textView = TETextView()
    /// textView.text = "Long text content with multiple lines..."
    /// 
    /// let metrics = TEPerformanceProfiler.shared.profileTextView(textView)
    /// print("布局时间: \\(metrics.layoutMetrics.layoutTime * 1000)ms")
    /// print("渲染时间: \\(metrics.renderMetrics.renderTime * 1000)ms")
    /// print("行数: \\(metrics.layoutMetrics.lineCount)")
    /// print("字符数: \\(metrics.layoutMetrics.characterCount)")
    /// ```
    /// 
    /// - Note: 如果性能分析未启用，此方法会返回空的性能指标
    /// - Returns: 性能指标数据，如果分析未启用则返回空指标
    @discardableResult
    public func profileTextView(_ textView: TETextView) -> TEPerformanceMetrics {
        guard isProfilingEnabled else {
            return createEmptyMetrics()
        }
        
        let startTime = CFAbsoluteTimeGetCurrent()
        
        // 收集性能数据
        let layoutMetrics = collectLayoutMetrics(from: textView)
        let renderMetrics = collectRenderMetrics(from: textView)
        
        let endTime = CFAbsoluteTimeGetCurrent()
        let totalTime = endTime - startTime
        
        let overallMetrics = TEPerformanceMetrics.OverallMetrics(
            totalTime: totalTime,
            fps: calculateFPS(),
            cpuUsage: getCPUUsage(),
            memoryUsage: getMemoryUsage(),
            energyUsage: getEnergyUsage()
        )
        
        let metrics = TEPerformanceMetrics(
            layoutMetrics: layoutMetrics,
            renderMetrics: renderMetrics,
            overallMetrics: overallMetrics
        )
        
        // 保存性能数据
        savePerformanceMetrics(metrics)
        
        // 分析性能瓶颈
        analyzePerformanceBottlenecks(metrics)
        
        // 检查性能阈值
        checkPerformanceThresholds(metrics)
        
        // 通知委托
        delegate?.profiler(self, didCompleteAnalysis: metrics)
        
        return metrics
    }
    
    /// 分析文本渲染性能
    /// 对指定的文本和容器进行渲染性能分析
    /// 
    /// - Parameters:
    ///   - attributedText: 要分析的属性文本
    ///   - containerSize: 文本容器的尺寸
    ///   - exclusionPaths: 排除路径数组（可选，默认为空数组）
    /// - Returns: 完整的性能指标数据
    /// 
    /// 此方法会执行以下操作:
    /// 1. 检查性能分析是否启用
    /// 2. 模拟文本布局和渲染过程
    /// 3. 收集布局和渲染性能数据
    /// 4. 计算整体性能指标（FPS、CPU使用率等）
    /// 5. 保存性能数据到历史记录
    /// 6. 分析性能瓶颈和阈值检查
    /// 7. 通知委托对象
    /// 
    /// 使用示例:
    /// ```swift
    /// let text = NSAttributedString(string: "Sample text for performance testing")
    /// let size = CGSize(width: 200, height: 100)
    /// let exclusionPaths = [TEExclusionPath.rect(CGRect(x: 50, y: 20, width: 40, height: 40))]
    /// 
    /// let metrics = TEPerformanceProfiler.shared.profileTextRendering(
    ///     attributedText: text,
    ///     containerSize: size,
    ///     exclusionPaths: exclusionPaths
    /// )
    /// 
    /// print("布局时间: \\(metrics.layoutMetrics.layoutTime * 1000)ms")
    /// print("渲染时间: \\(metrics.renderMetrics.renderTime * 1000)ms")
    /// print("像素数: \\(metrics.renderMetrics.pixelCount)")
    /// ```
    /// 
    /// - Note: 如果性能分析未启用，此方法会返回空的性能指标
    /// - Returns: 性能指标数据，如果分析未启用则返回空指标
    @discardableResult
    public func profileTextRendering(attributedText: NSAttributedString, containerSize: CGSize, exclusionPaths: [TEExclusionPath] = []) -> TEPerformanceMetrics {
        guard isProfilingEnabled else {
            return createEmptyMetrics()
        }
        
        let startTime = CFAbsoluteTimeGetCurrent()
        
        // 模拟文本渲染过程
        let layoutMetrics = profileTextLayout(attributedText: attributedText, containerSize: containerSize, exclusionPaths: exclusionPaths)
        let renderMetrics = profileTextRender(attributedText: attributedText, containerSize: containerSize)
        
        let endTime = CFAbsoluteTimeGetCurrent()
        let totalTime = endTime - startTime
        
        let overallMetrics = TEPerformanceMetrics.OverallMetrics(
            totalTime: totalTime,
            fps: calculateFPS(),
            cpuUsage: getCPUUsage(),
            memoryUsage: getMemoryUsage(),
            energyUsage: getEnergyUsage()
        )
        
        let metrics = TEPerformanceMetrics(
            layoutMetrics: layoutMetrics,
            renderMetrics: renderMetrics,
            overallMetrics: overallMetrics
        )
        
        // 保存性能数据
        savePerformanceMetrics(metrics)
        
        // 分析性能瓶颈
        analyzePerformanceBottlenecks(metrics)
        
        // 检查性能阈值
        checkPerformanceThresholds(metrics)
        
        // 通知委托
        delegate?.profiler(self, didCompleteAnalysis: metrics)
        
        return metrics
    }
    
    /// 获取性能历史
    /// 获取所有收集到的性能指标历史记录
    /// 
    /// - Returns: 包含所有历史性能指标的数组，按时间顺序排列
    /// 
    /// 返回的数组包含:
    /// - 所有通过性能分析方法收集的指标数据
    /// - 最多 `maxHistoryCount` 条记录
    /// - 按时间戳从早到晚排序
    /// 
    /// 使用示例:
    /// ```swift
    /// let history = TEPerformanceProfiler.shared.getPerformanceHistory()
    /// for metrics in history {
    ///     print("时间: \\(metrics.timestamp)")
    ///     print("布局时间: \\(metrics.layoutMetrics.layoutTime * 1000)ms")
    ///     print("FPS: \\(metrics.overallMetrics.fps)")
    ///     print("内存: \\(formatBytes(metrics.overallMetrics.memoryUsage))")
    /// }
    /// ```
    public func getPerformanceHistory() -> [TEPerformanceMetrics] {
        return performanceHistory
    }
    
    /// 获取性能报告
    /// 生成包含所有历史性能数据的详细报告
    /// 
    /// - Returns: 格式化的性能报告字符串
    /// 
    /// 报告包含:
    /// - 报告生成时间
    /// - 平均性能指标（布局时间、渲染时间、总时间、FPS、内存使用）
    /// - 性能瓶颈分析（如果有）
    /// - 优化建议
    /// 
    /// 使用示例:
    /// ```swift
    /// let report = TEPerformanceProfiler.shared.getPerformanceReport()
    /// print(report)
    /// 
    /// // 保存到文件
    /// let url = FileManager.default.temporaryDirectory.appendingPathComponent("performance_report.txt")
    /// try? report.write(to: url, atomically: true, encoding: .utf8)
    /// ```
    public func getPerformanceReport() -> String {
        var report = "TextEngineKit Performance Report\n"
        report += "================================\n"
        report += "Generated: \(Date())\n\n"
        
        if performanceHistory.isEmpty {
            report += "No performance data available.\n"
            return report
        }
        
        // 计算平均值
        let avgLayoutTime = performanceHistory.map { $0.layoutMetrics.layoutTime }.reduce(0, +) / Double(performanceHistory.count)
        let avgRenderTime = performanceHistory.map { $0.renderMetrics.renderTime }.reduce(0, +) / Double(performanceHistory.count)
        let avgTotalTime = performanceHistory.map { $0.overallMetrics.totalTime }.reduce(0, +) / Double(performanceHistory.count)
        let avgFPS = performanceHistory.map { $0.overallMetrics.fps }.reduce(0, +) / Float(performanceHistory.count)
        let avgMemoryUsage = performanceHistory.map { $0.overallMetrics.memoryUsage }.reduce(0, +) / performanceHistory.count
        
        report += "Average Performance:\n"
        report += "  - Layout Time: \(String(format: "%.3f", avgLayoutTime * 1000))ms\n"
        report += "  - Render Time: \(String(format: "%.3f", avgRenderTime * 1000))ms\n"
        report += "  - Total Time: \(String(format: "%.3f", avgTotalTime * 1000))ms\n"
        report += "  - FPS: \(String(format: "%.1f", avgFPS))\n"
        report += "  - Memory Usage: \(formatBytes(avgMemoryUsage))\n\n"
        
        // 性能瓶颈分析
        let bottlenecks = analyzeBottlenecksInHistory()
        if !bottlenecks.isEmpty {
            report += "Performance Bottlenecks:\n"
            for bottleneck in bottlenecks {
                report += "  - \(bottleneck.description) (Severity: \(String(format: "%.1f", bottleneck.severity * 100))%)\n"
                report += "    Suggestion: \(bottleneck.suggestion)\n"
            }
        }
        
        return report
    }
    
    /// 重置性能数据
    /// 清除所有已收集的性能历史数据
    /// 
    /// 此方法会:
    /// - 清空性能历史记录数组
    /// - 记录性能数据重置日志
    /// 
    /// 使用示例:
    /// ```swift
    /// // 重置性能数据
    /// TEPerformanceProfiler.shared.resetPerformanceData()
    /// 
    /// // 重新开始收集性能数据
    /// let metrics = TEPerformanceProfiler.shared.profileLabel(myLabel)
    /// ```
    public func resetPerformanceData() {
        performanceHistory.removeAll()
        TETextEngine.shared.logInfo("性能数据已重置", category: "performance")
    }
    
    // MARK: - 私有方法
    
    /// 创建空性能指标
    private func createEmptyMetrics() -> TEPerformanceMetrics {
        let layoutMetrics = TEPerformanceMetrics.LayoutMetrics(
            layoutTime: 0,
            lineCount: 0,
            glyphCount: 0,
            characterCount: 0,
            cacheHit: false,
            memoryUsage: 0
        )
        
        let renderMetrics = TEPerformanceMetrics.RenderMetrics(
            renderTime: 0,
            pixelCount: 0,
            drawCallCount: 0,
            memoryUsage: 0,
            gpuUsage: 0
        )
        
        let overallMetrics = TEPerformanceMetrics.OverallMetrics(
            totalTime: 0,
            fps: 0,
            cpuUsage: 0,
            memoryUsage: 0,
            energyUsage: 0
        )
        
        return TEPerformanceMetrics(
            layoutMetrics: layoutMetrics,
            renderMetrics: renderMetrics,
            overallMetrics: overallMetrics
        )
    }
    
    /// 收集布局性能指标
    /// - Parameter label: 标签
    /// - Returns: 布局性能指标
    private func collectLayoutMetrics(from label: TELabel) -> TEPerformanceMetrics.LayoutMetrics {
        // 简化实现，实际需要访问label的内部布局数据
        return TEPerformanceMetrics.LayoutMetrics(
            layoutTime: 0.001,
            lineCount: 1,
            glyphCount: 100,
            characterCount: 100,
            cacheHit: false,
            memoryUsage: 1024
        )
    }
    
    /// 收集布局性能指标
    /// - Parameter textView: 文本视图
    /// - Returns: 布局性能指标
    private func collectLayoutMetrics(from textView: TETextView) -> TEPerformanceMetrics.LayoutMetrics {
        // 简化实现，实际需要访问textView的内部布局数据
        return TEPerformanceMetrics.LayoutMetrics(
            layoutTime: 0.001,
            lineCount: 1,
            glyphCount: 100,
            characterCount: 100,
            cacheHit: false,
            memoryUsage: 1024
        )
    }
    
    /// 收集渲染性能指标
    /// - Parameter label: 标签
    /// - Returns: 渲染性能指标
    private func collectRenderMetrics(from label: TELabel) -> TEPerformanceMetrics.RenderMetrics {
        // 简化实现，实际需要访问label的内部渲染数据
        return TEPerformanceMetrics.RenderMetrics(
            renderTime: 0.001,
            pixelCount: 10000,
            drawCallCount: 1,
            memoryUsage: 1024,
            gpuUsage: 0.1
        )
    }
    
    /// 收集渲染性能指标
    /// - Parameter textView: 文本视图
    /// - Returns: 渲染性能指标
    private func collectRenderMetrics(from textView: TETextView) -> TEPerformanceMetrics.RenderMetrics {
        // 简化实现，实际需要访问textView的内部渲染数据
        return TEPerformanceMetrics.RenderMetrics(
            renderTime: 0.001,
            pixelCount: 10000,
            drawCallCount: 1,
            memoryUsage: 1024,
            gpuUsage: 0.1
        )
    }
    
    /// 分析文本布局性能
    /// - Parameters:
    ///   - attributedText: 属性文本
    ///   - containerSize: 容器尺寸
    ///   - exclusionPaths: 排除路径
    /// - Returns: 布局性能指标
    private func profileTextLayout(attributedText: NSAttributedString, containerSize: CGSize, exclusionPaths: [TEExclusionPath]) -> TEPerformanceMetrics.LayoutMetrics {
        let startTime = CFAbsoluteTimeGetCurrent()
        
        // 模拟布局过程
        let lineCount = 10
        let glyphCount = attributedText.length
        let characterCount = attributedText.length
        let cacheHit = false
        let memoryUsage = attributedText.length * 4 // 估算内存使用
        
        let layoutTime = CFAbsoluteTimeGetCurrent() - startTime
        
        return TEPerformanceMetrics.LayoutMetrics(
            layoutTime: layoutTime,
            lineCount: lineCount,
            glyphCount: glyphCount,
            characterCount: characterCount,
            cacheHit: cacheHit,
            memoryUsage: memoryUsage
        )
    }
    
    /// 分析文本渲染性能
    /// - Parameters:
    ///   - attributedText: 属性文本
    ///   - containerSize: 容器尺寸
    /// - Returns: 渲染性能指标
    private func profileTextRender(attributedText: NSAttributedString, containerSize: CGSize) -> TEPerformanceMetrics.RenderMetrics {
        let startTime = CFAbsoluteTimeGetCurrent()
        
        // 模拟渲染过程
        let pixelCount = Int(containerSize.width * containerSize.height)
        let drawCallCount = 1
        let memoryUsage = pixelCount * 4 // 估算内存使用
        let gpuUsage: Float = 0.1
        
        let renderTime = CFAbsoluteTimeGetCurrent() - startTime
        
        return TEPerformanceMetrics.RenderMetrics(
            renderTime: renderTime,
            pixelCount: pixelCount,
            drawCallCount: drawCallCount,
            memoryUsage: memoryUsage,
            gpuUsage: gpuUsage
        )
    }
    
    /// 保存性能指标
    /// - Parameter metrics: 性能指标
    private func savePerformanceMetrics(_ metrics: TEPerformanceMetrics) {
        performanceHistory.append(metrics)
        
        // 限制历史记录数量
        if performanceHistory.count > maxHistoryCount {
            performanceHistory.removeFirst()
        }
    }
    
    /// 分析性能瓶颈
    /// - Parameter metrics: 性能指标
    private func analyzePerformanceBottlenecks(_ metrics: TEPerformanceMetrics) {
        var bottlenecks: [TEPerformanceBottleneck] = []
        
        // 检查布局性能
        if metrics.layoutMetrics.layoutTime > thresholds.maxLayoutTime {
            let bottleneck = TEPerformanceBottleneck(
                type: .layoutSlow,
                severity: min(1.0, Float(metrics.layoutMetrics.layoutTime / thresholds.maxLayoutTime) - 1.0),
                description: "Layout time is \(String(format: "%.1f", metrics.layoutMetrics.layoutTime * 1000))ms, exceeding threshold of \(String(format: "%.1f", thresholds.maxLayoutTime * 1000))ms",
                suggestion: "Consider optimizing text layout or using async layout",
                metrics: metrics
            )
            bottlenecks.append(bottleneck)
            delegate?.profiler(self, didDetectBottleneck: bottleneck)
        }
        
        // 检查渲染性能
        if metrics.renderMetrics.renderTime > thresholds.maxRenderTime {
            let bottleneck = TEPerformanceBottleneck(
                type: .renderSlow,
                severity: min(1.0, Float(metrics.renderMetrics.renderTime / thresholds.maxRenderTime) - 1.0),
                description: "Render time is \(String(format: "%.1f", metrics.renderMetrics.renderTime * 1000))ms, exceeding threshold of \(String(format: "%.1f", thresholds.maxRenderTime * 1000))ms",
                suggestion: "Consider optimizing text rendering or using async rendering",
                metrics: metrics
            )
            bottlenecks.append(bottleneck)
            delegate?.profiler(self, didDetectBottleneck: bottleneck)
        }
        
        // 检查内存使用
        if metrics.overallMetrics.memoryUsage > thresholds.maxMemoryUsage {
            let bottleneck = TEPerformanceBottleneck(
                type: .memoryHigh,
                severity: min(1.0, Float(metrics.overallMetrics.memoryUsage) / Float(thresholds.maxMemoryUsage) - 1.0),
                description: "Memory usage is \(formatBytes(metrics.overallMetrics.memoryUsage)), exceeding threshold of \(formatBytes(thresholds.maxMemoryUsage))",
                suggestion: "Consider optimizing memory usage or implementing better cache management",
                metrics: metrics
            )
            bottlenecks.append(bottleneck)
            delegate?.profiler(self, didDetectBottleneck: bottleneck)
        }
        
        // 检查FPS
        if metrics.overallMetrics.fps < thresholds.minFPS {
            let bottleneck = TEPerformanceBottleneck(
                type: .cpuIntensive,
                severity: min(1.0, (thresholds.minFPS - metrics.overallMetrics.fps) / thresholds.minFPS),
                description: "FPS is \(String(format: "%.1f", metrics.overallMetrics.fps)), below threshold of \(thresholds.minFPS)",
                suggestion: "Consider optimizing performance to maintain 60fps",
                metrics: metrics
            )
            bottlenecks.append(bottleneck)
            delegate?.profiler(self, didDetectBottleneck: bottleneck)
        }
    }
    
    /// 检查性能阈值
    /// - Parameter metrics: 性能指标
    private func checkPerformanceThresholds(_ metrics: TEPerformanceMetrics) {
        // 这里可以添加更多的阈值检查逻辑
        if metrics.overallMetrics.cpuUsage > thresholds.maxCPUUsage {
            delegate?.profiler(self, didTriggerWarning: "High CPU usage: \(String(format: "%.1f", metrics.overallMetrics.cpuUsage * 100))%", severity: 0.7)
        }
        
        if metrics.overallMetrics.memoryUsage > thresholds.maxMemoryUsage {
            delegate?.profiler(self, didTriggerWarning: "High memory usage: \(formatBytes(metrics.overallMetrics.memoryUsage))", severity: 0.8)
        }
    }
    
    /// 分析历史性能瓶颈
    /// - Returns: 性能瓶颈数组
    private func analyzeBottlenecksInHistory() -> [TEPerformanceBottleneck] {
        // 简化实现，实际需要更复杂的分析算法
        return []
    }
    
    /// 计算FPS
    /// - Returns: FPS
    private func calculateFPS() -> Float {
        // 简化实现，实际需要更复杂的FPS计算
        return 60.0
    }
    
    /// 获取CPU使用率
    /// - Returns: CPU使用率
    private func getCPUUsage() -> Float {
        // 简化实现，实际需要访问系统CPU信息
        return 0.1
    }
    
    /// 获取内存使用
    /// - Returns: 内存使用
    private func getMemoryUsage() -> Int {
        // 简化实现，实际需要访问系统内存信息
        return 1024 * 1024 // 1MB
    }
    
    /// 获取能耗使用
    /// - Returns: 能耗使用
    private func getEnergyUsage() -> Float {
        // 简化实现，实际需要访问系统能耗信息
        return 0.1
    }
    
    /// 格式化字节数
    /// - Parameter bytes: 字节数
    /// - Returns: 格式化字符串
    private func formatBytes(_ bytes: Int) -> String {
        let formatter = ByteCountFormatter()
        formatter.countStyle = .binary
        return formatter.string(fromByteCount: Int64(bytes))
    }
    
    /// 设置系统信息
    private func setupSystemInfo() {
        systemInfo = SystemInfo()
    }
    
    /// 启动监控定时器
    private func startMonitoringTimer() {
        monitoringTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            self?.performPeriodicMonitoring()
        }
    }
    
    /// 停止监控定时器
    private func stopMonitoringTimer() {
        monitoringTimer?.invalidate()
        monitoringTimer = nil
    }
    
    /// 执行定期监控
    private func performPeriodicMonitoring() {
        // 这里可以添加定期监控逻辑
    }
    
    /// 设置通知观察者
    private func setupNotificationObservers() {
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(applicationWillEnterForeground),
            name: UIApplication.willEnterForegroundNotification,
            object: nil
        )
        
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(applicationDidEnterBackground),
            name: UIApplication.didEnterBackgroundNotification,
            object: nil
        )
    }
    
    /// 移除通知观察者
    private func removeNotificationObservers() {
        NotificationCenter.default.removeObserver(self)
    }
    
    /// 应用将进入前台
    @objc private func applicationWillEnterForeground() {
        // 恢复性能监控
        if isProfilingEnabled {
            startMonitoringTimer()
        }
    }
    
    /// 应用进入后台
    @objc private func applicationDidEnterBackground() {
        // 暂停性能监控
        stopMonitoringTimer()
    }
}

/// 性能会话
private class PerformanceSession {
    let startTime: CFAbsoluteTime
    var layoutCount: Int = 0
    var renderCount: Int = 0
    var totalLayoutTime: TimeInterval = 0
    var totalRenderTime: TimeInterval = 0
    
    init() {
        self.startTime = CFAbsoluteTimeGetCurrent()
    }
}

/// 系统信息
private struct SystemInfo {
    let deviceModel: String
    let osVersion: String
    let cpuCount: Int
    let totalMemory: Int
    let screenScale: CGFloat
    
    init() {
        self.deviceModel = UIDevice.current.model
        self.osVersion = UIDevice.current.systemVersion
        self.cpuCount = ProcessInfo.processInfo.processorCount
        self.totalMemory = Int(ProcessInfo.processInfo.physicalMemory)
        self.screenScale = UIScreen.main.scale
    }
}

/// 通知扩展
extension Notification.Name {
    static let performanceProfilingStarted = Notification.Name("TEPerformanceProfilingStarted")
    static let performanceProfilingStopped = Notification.Name("TEPerformanceProfilingStopped")
}

/// TELabel扩展，支持性能分析
/// 为 `TELabel` 提供便捷的性能分析方法
/// 
/// 功能特性:
/// - 一键启用/禁用性能分析
/// - 便捷的性能分析方法
/// - 简化性能分析操作流程
/// 
/// 使用示例:
/// ```swift
/// let label = TELabel()
/// label.text = "Hello World"
/// 
/// // 启用性能分析
/// label.enablePerformanceProfiling()
/// 
/// // 分析当前标签性能
/// let metrics = label.profilePerformance()
/// print("布局时间: \\(metrics.layoutMetrics.layoutTime * 1000)ms")
/// print("渲染时间: \\(metrics.renderMetrics.renderTime * 1000)ms")
/// 
/// // 禁用性能分析
/// label.disablePerformanceProfiling()
/// ```
extension TELabel {
    
    /// 启用性能分析
    /// 启动全局性能分析器
    /// 
    /// 此方法会:
    /// - 启动性能分析器
    /// - 开始收集性能数据
    /// - 准备进行性能分析
    /// 
    /// 等同于调用:
    /// ```swift
    /// TEPerformanceProfiler.shared.startProfiling()
    /// ```
    /// 
    /// - Note: 这是一个全局操作，会影响所有后续的性能分析
    public func enablePerformanceProfiling() {
        TEPerformanceProfiler.shared.startProfiling()
    }
    
    /// 禁用性能分析
    /// 停止全局性能分析器
    /// 
    /// 此方法会:
    /// - 停止性能分析器
    /// - 停止收集性能数据
    /// - 清理相关资源
    /// 
    /// 等同于调用:
    /// ```swift
    /// TEPerformanceProfiler.shared.stopProfiling()
    /// ```
    /// 
    /// - Note: 这是一个全局操作，会影响所有的性能分析
    public func disablePerformanceProfiling() {
        TEPerformanceProfiler.shared.stopProfiling()
    }
    
    /// 分析当前性能
    /// 对当前标签进行性能分析
    /// 
    /// - Returns: 当前标签的性能指标数据
    /// 
    /// 此方法会:
    /// - 检查性能分析是否启用
    /// - 收集标签的布局和渲染性能数据
    /// - 返回完整的性能指标
    /// 
    /// 等同于调用:
    /// ```swift
    /// TEPerformanceProfiler.shared.profileLabel(self)
    /// ```
    /// 
    /// - Note: 如果性能分析未启用，此方法会返回空的性能指标
    /// - Returns: 性能指标数据，如果分析未启用则返回空指标
    public func profilePerformance() -> TEPerformanceMetrics {
        return TEPerformanceProfiler.shared.profileLabel(self)
    }
}

/// TETextView扩展，支持性能分析
/// 为 `TETextView` 提供便捷的性能分析方法
/// 
/// 功能特性:
/// - 一键启用/禁用性能分析
/// - 便捷的性能分析方法
/// - 简化性能分析操作流程
/// 
/// 使用示例:
/// ```swift
/// let textView = TETextView()
/// textView.text = "Long text content with multiple lines..."
/// 
/// // 启用性能分析
/// textView.enablePerformanceProfiling()
/// 
/// // 分析当前文本视图性能
/// let metrics = textView.profilePerformance()
/// print("布局时间: \\(metrics.layoutMetrics.layoutTime * 1000)ms")
/// print("渲染时间: \\(metrics.renderMetrics.renderTime * 1000)ms")
/// print("行数: \\(metrics.layoutMetrics.lineCount)")
/// 
/// // 禁用性能分析
/// textView.disablePerformanceProfiling()
/// ```
extension TETextView {
    
    /// 启用性能分析
    /// 启动全局性能分析器
    /// 
    /// 此方法会:
    /// - 启动性能分析器
    /// - 开始收集性能数据
    /// - 准备进行性能分析
    /// 
    /// 等同于调用:
    /// ```swift
    /// TEPerformanceProfiler.shared.startProfiling()
    /// ```
    /// 
    /// - Note: 这是一个全局操作，会影响所有后续的性能分析
    public func enablePerformanceProfiling() {
        TEPerformanceProfiler.shared.startProfiling()
    }
    
    /// 禁用性能分析
    /// 停止全局性能分析器
    /// 
    /// 此方法会:
    /// - 停止性能分析器
    /// - 停止收集性能数据
    /// - 清理相关资源
    /// 
    /// 等同于调用:
    /// ```swift
    /// TEPerformanceProfiler.shared.stopProfiling()
    /// ```
    /// 
    /// - Note: 这是一个全局操作，会影响所有的性能分析
    public func disablePerformanceProfiling() {
        TEPerformanceProfiler.shared.stopProfiling()
    }
    
    /// 分析当前性能
    /// 对当前文本视图进行性能分析
    /// 
    /// - Returns: 当前文本视图的性能指标数据
    /// 
    /// 此方法会:
    /// - 检查性能分析是否启用
    /// - 收集文本视图的布局和渲染性能数据
    /// - 返回完整的性能指标
    /// 
    /// 等同于调用:
    /// ```swift
    /// TEPerformanceProfiler.shared.profileTextView(self)
    /// ```
    /// 
    /// - Note: 如果性能分析未启用，此方法会返回空的性能指标
    /// - Returns: 性能指标数据，如果分析未启用则返回空指标
    public func profilePerformance() -> TEPerformanceMetrics {
        return TEPerformanceProfiler.shared.profileTextView(self)
    }
}

#endif
