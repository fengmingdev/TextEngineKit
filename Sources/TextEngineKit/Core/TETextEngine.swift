// 
//  TETextEngine.swift 
//  TextEngineKit 
// 
//  Created by fengming on 2025/11/17. 
// 
//  核心引擎：提供统一配置与日志系统、性能记录、生命周期管理与引擎信息。 
// 
import Foundation
import FMLogger
#if canImport(CoreGraphics)
import CoreGraphics
#endif
#if canImport(AppKit)
import AppKit
#endif
#if canImport(UIKit)
import UIKit
#endif

/// TextEngineKit 核心引擎类
/// 提供统一的配置管理和日志系统
public final class TETextEngine: TETextEngineProtocol {
    
    // MARK: - 单例实例
    
    /// 共享实例（通过 DI 容器解析，保持向后兼容）
    public static let shared: TETextEngine = {
        // 由于容器现在是 actor，我们需要异步解析，但在静态上下文中无法使用 await
        // 所以我们创建一个实例并手动注册到容器中
        let engine = TETextEngine()
        Task {
            await TEContainer.shared.registerInstance(TETextEngineProtocol.self, instance: engine)
        }
        return engine
    }()
    
    // MARK: - 属性
    
    /// 日志记录器
    private let logger: FMLogger
    
    /// 是否启用性能日志
    public var enablePerformanceLogging: Bool = false {
        didSet {
            logger.log("性能日志已\(enablePerformanceLogging ? "启用" : "禁用")", level: .info, category: "performance")
        }
    }
    
    /// 当前配置
    public var configuration: TEConfiguration
    
    // MARK: - 初始化
    
    public init() {
        // 初始化日志系统
        self.logger = FMLogger.shared
        
        // 默认配置
        self.configuration = TEConfiguration()
        
        // 记录引擎启动
        logger.log("TextEngineKit 引擎启动", level: .info, category: "lifecycle")
    }
    
    // MARK: - 公共方法
    
    /// 配置日志系统
    /// - Parameter logLevel: 日志级别
    public func configureLogging(_ logLevel: TELogLevel) {
        let config = LoggerConfiguration(
            minLevel: logLevel.fmLogLevel,
            enablePerformanceLogging: enablePerformanceLogging,
            enableConsoleColors: true
        )
        logger.updateConfiguration(config)
        
        logger.log("日志系统已配置为 \(logLevel.rawValue)", level: .info, category: "configuration")
    }
    
    /// 更新引擎配置
    /// - Parameter configuration: 新的配置
    public func updateConfiguration(_ configuration: TEConfiguration) {
        self.configuration = configuration
        logger.log("引擎配置已更新", level: .info, category: "configuration")
    }
    
    /// 获取引擎版本
    /// - Returns: 版本号
    public func version() -> String {
        return "1.0.0"
    }
    
    /// 获取引擎信息
    /// - Returns: 引擎信息字典
    public func engineInfo() -> [String: Any] {
        return [
            "version": version(),
            "platform": "iOS",
            "swift_version": "5.5+",
            "min_ios_version": "13.0",
            "performance_logging_enabled": enablePerformanceLogging,
            "configuration": configuration.description
        ]
    }
    
    // MARK: - 内部方法
    
    /// 记录性能日志
    /// - Parameters:
    ///   - operation: 操作名称
    ///   - duration: 耗时
    ///   - metadata: 额外元数据
    func logPerformance(_ operation: String, duration: TimeInterval, metadata: [String: Any]? = nil) {
        guard enablePerformanceLogging else { return }
        
        var logMetadata = metadata ?? [:]
        logMetadata["duration"] = duration
        logMetadata["operation"] = operation
        
        logger.log("性能: \(operation) 耗时 \(String(format: "%.3f", duration))ms", 
                  level: .debug, category: "performance", metadata: logMetadata)
    }
    
    /// 记录错误日志
    /// - Parameters:
    ///   - error: 错误信息
    ///   - category: 错误类别
    func logError(_ error: String, category: String = "general") {
        logger.log("错误: \(error)", level: .error, category: category)
    }
    
    /// 记录警告日志
    /// - Parameters:
    ///   - warning: 警告信息
    ///   - category: 警告类别
    func logWarning(_ warning: String, category: String = "general") {
        logger.log("警告: \(warning)", level: .warning, category: category)
    }
    
    /// 记录调试日志
    /// - Parameters:
    ///   - message: 调试信息
    ///   - category: 调试类别
    func logDebug(_ message: String, category: String = "general") {
        logger.log(message, level: .debug, category: category)
    }

    /// 记录信息日志
    /// - Parameters:
    ///   - message: 信息内容
    ///   - category: 分类
    public func logInfo(_ message: String, category: String = "general") {
        logger.log(message, level: .info, category: category)
    }

    /// 通用日志入口
    /// - Parameters:
    ///   - message: 日志内容
    ///   - level: 日志级别
    ///   - category: 分类
    ///   - metadata: 附加元数据
    public func log(_ message: String, level: TELogLevel, category: String = "general", metadata: [String: Any]? = nil) {
        logger.log(message, level: level.fmLogLevel, category: category, metadata: metadata)
    }
    
    /// 记录严重错误日志
    /// - Parameters:
    ///   - message: 错误信息
    ///   - category: 错误类别
    func logCritical(_ message: String, category: String = "general") {
        logger.log("严重错误: \(message)", level: .critical, category: category)
    }
    
    /// 记录布局性能日志
    /// - Parameters:
    ///   - operation: 操作名称
    ///   - textLength: 文本长度
    ///   - duration: 耗时
    ///   - cacheHit: 是否命中缓存
    public func logLayoutPerformance(operation: String, textLength: Int, duration: TimeInterval, cacheHit: Bool) {
        guard enablePerformanceLogging else { return }
        
        let metadata: [String: Any] = [
            "textLength": textLength,
            "cacheHit": cacheHit,
            "operation": operation
        ]
        
        logger.log("布局性能: \(operation) 耗时 \(String(format: "%.3f", duration))ms, 文本长度: \(textLength), 缓存命中: \(cacheHit)", 
                  level: .debug, category: "layout_performance", metadata: metadata)
    }
    
    /// 记录渲染性能日志
    /// - Parameters:
    ///   - frameCount: 帧数
    ///   - totalDuration: 总耗时
    ///   - averageFrameTime: 平均帧时间
    public func logRenderingPerformance(frameCount: Int, totalDuration: TimeInterval, averageFrameTime: TimeInterval) {
        guard enablePerformanceLogging else { return }
        
        let metadata: [String: Any] = [
            "frameCount": frameCount,
            "totalDuration": totalDuration,
            "averageFrameTime": averageFrameTime
        ]
        
        logger.log("渲染性能: 帧数\(frameCount), 总耗时\(String(format: "%.3f", totalDuration))ms, 平均帧时间\(String(format: "%.3f", averageFrameTime))ms", 
                  level: .debug, category: "rendering_performance", metadata: metadata)
    }
    
    /// 记录解析性能日志
    /// - Parameters:
    ///   - parserType: 解析器类型
    ///   - inputLength: 输入长度
    ///   - duration: 耗时
    ///   - outputLength: 输出长度
    public func logParsingPerformance(parserType: String, inputLength: Int, duration: TimeInterval, outputLength: Int) {
        guard enablePerformanceLogging else { return }
        
        let metadata: [String: Any] = [
            "parserType": parserType,
            "inputLength": inputLength,
            "outputLength": outputLength,
            "duration": duration
        ]
        
        logger.log("解析性能: \(parserType) 解析器, 输入长度\(inputLength), 输出长度\(outputLength), 耗时\(String(format: "%.3f", duration))ms", 
                  level: .debug, category: "parsing_performance", metadata: metadata)
    }
}

// MARK: - TETextEngineProtocol 实现

extension TETextEngine {
    
    public var isRunning: Bool {
        // 简化实现：始终返回 true，后续可扩展生命周期管理
        return true
    }
    
    public func start() throws {
        logger.logInfo("TextEngineKit 引擎启动", category: "lifecycle")
    }
    
    public func stop() {
        logger.logInfo("TextEngineKit 引擎停止", category: "lifecycle")
    }
    
    public func reset() {
        configuration = TEConfiguration()
        logger.logInfo("TextEngineKit 引擎重置", category: "lifecycle")
    }
    
    public func performHealthCheck() -> Result<Bool, TETextEngineError> {
        // 简化健康检查：始终返回成功
        return .success(true)
    }
    
    public func processText(_ text: String, options: TEProcessingOptions?) -> Result<NSAttributedString, TETextEngineError> {
        // 简化实现：直接返回纯文本属性串
        let attr = NSAttributedString(string: text)
        return .success(attr)
    }
    
    public func layoutText(_ attributedString: NSAttributedString, containerSize: CGSize) -> Result<TETextLayout, TETextEngineError> {
        // 简化实现：创建最小布局对象
        let container = TETextContainer(size: containerSize)
        let layoutManager = TELayoutManager()
        
        let layout = TETextLayout(
            attributedString: attributedString,
            containerSize: containerSize,
            textContainer: container,
            layoutManager: layoutManager,
            textStorage: nil // 移除 NSTextStorage 依赖
        )
        return .success(layout)
    }
    
    public func renderText(_ layout: TETextLayout, in context: CGContext) -> Result<Void, TETextEngineError> {
        // 简化实现：直接绘制背景与字形
        context.saveGState()
        let rect = CGRect(origin: .zero, size: layout.containerSize)
        
        // 绘制背景（简化实现）
        context.setFillColor(red: 1.0, green: 1.0, blue: 1.0, alpha: 1.0) // 白色背景
        context.fill(rect)
        
        // 绘制文本（简化实现）
        context.setFillColor(red: 0.0, green: 0.0, blue: 0.0, alpha: 1.0) // 黑色文本
        // 这里应该使用 CoreText 进行实际的文本绘制，但为简化实现，仅做占位
        
        context.restoreGState()
        return .success(())
    }
}

// MARK: - 配置相关类型

/// TextEngineKit 配置类
public struct TEConfiguration {
    
    /// 是否启用异步布局
    public var enableAsyncLayout: Bool
    
    /// 布局缓存大小
    public var layoutCacheSize: Int
    
    /// 最大并发布局任务数
    public var maxConcurrentLayoutTasks: Int
    
    /// 是否启用内存优化
    public var enableMemoryOptimization: Bool
    
    /// 内存警告阈值（字节）
    public var memoryWarningThreshold: Int
    
    /// 初始化
    public init(
        enableAsyncLayout: Bool = true,
        layoutCacheSize: Int = 100,
        maxConcurrentLayoutTasks: Int = 3,
        enableMemoryOptimization: Bool = true,
        memoryWarningThreshold: Int = 50 * 1024 * 1024 // 50MB
    ) {
        self.enableAsyncLayout = enableAsyncLayout
        self.layoutCacheSize = layoutCacheSize
        self.maxConcurrentLayoutTasks = maxConcurrentLayoutTasks
        self.enableMemoryOptimization = enableMemoryOptimization
        self.memoryWarningThreshold = memoryWarningThreshold
    }
    
    /// 配置描述
    public var description: String {
        return """
        TextEngineKit Configuration:
        - Async Layout: \(enableAsyncLayout)
        - Layout Cache Size: \(layoutCacheSize)
        - Max Concurrent Layout Tasks: \(maxConcurrentLayoutTasks)
        - Memory Optimization: \(enableMemoryOptimization)
        - Memory Warning Threshold: \(memoryWarningThreshold) bytes
        """
    }
}

/// 日志级别
public enum TELogLevel: String, CaseIterable {
    case debug = "debug"
    case info = "info"
    case warning = "warning"
    case error = "error"
    case critical = "critical"
    
    /// 对应的 FMLogLevel
    var fmLogLevel: LogLevel {
        switch self {
        case .debug:
            return .debug
        case .info:
            return .info
        case .warning:
            return .warning
        case .error:
            return .error
        case .critical:
            return .critical
        }
    }
}
