// 
//  TEServiceRegistrations.swift 
//  TextEngineKit 
// 
//  Created by fengming on 2025/11/17. 
// 
//  服务注册：在依赖注入容器中注册各核心服务与协议；包含引擎协议与布局结构体。 
// 
import Foundation
import FMLogger
#if canImport(CoreGraphics)
import CoreGraphics
#endif

public extension TEContainer {
    func registerTextEngineServices() {
        // Configuration Service
        register(TEConfigurationManagerProtocol.self) {
            TEConfigurationManager()
        }
        
        // Logging Service
        register(TETextLoggerProtocol.self) {
            TETextLogger()
        }
        
        // Performance Monitoring Service
        register(TEPerformanceMonitorProtocol.self) {
            TEPerformanceMonitor()
        }
        
        // Cache Service
        register(TECacheManagerProtocol.self) {
            TECacheManager()
        }
        
        // Statistics Service
        register(TEStatisticsServiceProtocol.self) {
            TEStatisticsService()
        }
        
        // Layout Service
        register(TELayoutServiceProtocol.self) {
            TELayoutService()
        }
        
        // Rendering Service
        register(TERenderingServiceProtocol.self) {
            TERenderingService()
        }
        
        // Parsing Service
        register(TEParsingServiceProtocol.self) {
            TEParsingService()
        }
        
        // Platform Service
        register(TEPlatformServiceProtocol.self) {
            TEPlatformService()
        }
        
        // Text Engine (Singleton)
        registerSingleton(TETextEngineProtocol.self) {
            TETextEngine()
        }
    }
}

/// 文本引擎协议
///
/// `TETextEngineProtocol` 定义了 TextEngineKit 核心引擎的接口，提供了文本处理、布局和渲染的完整生命周期管理。
/// 实现此协议的对象负责协调各个子系统（解析器、布局管理器、渲染器）来完成富文本的处理任务。
///
/// 生命周期管理：
/// - 引擎必须显式启动 (`start()`) 后才能使用
/// - 使用完毕后应该停止 (`stop()`) 以释放资源
/// - 支持健康检查来确保引擎状态正常
///
/// 使用示例：
/// ```swift
/// let engine = TETextEngine()
/// 
/// // 启动引擎
/// do {
///     try engine.start()
///     print("引擎启动成功")
/// } catch {
///     print("引擎启动失败: \(error)")
/// }
/// 
/// // 处理文本
/// let result = engine.processText("# Hello World", options: nil)
/// switch result {
/// case .success(let attributedString):
///     print("处理成功，结果长度: \(attributedString.length)")
/// case .failure(let error):
///     print("处理失败: \(error)")
/// }
/// 
/// // 停止引擎
/// engine.stop()
/// ```
public protocol TETextEngineProtocol {
    /// 引擎配置
    ///
    /// 包含缓存策略、并发设置、超时配置等。可以在引擎运行时动态修改，
    /// 但某些配置可能需要重启引擎才能生效。
    var configuration: TEConfiguration { get set }
    
    /// 引擎运行状态
    ///
    /// 表示引擎当前是否处于运行状态。只有运行中的引擎才能处理文本。
    /// 此属性是线程安全的，可以在任意线程读取。
    var isRunning: Bool { get }
    
    /// 启动引擎
    ///
    /// 初始化所有必要的子系统，分配资源，准备处理文本。
    /// 启动失败时会抛出 `TETextEngineError` 异常。
    ///
    /// - Throws: `TETextEngineError` 如果启动失败
    func start() throws
    
    /// 停止引擎
    ///
    /// 释放所有占用的资源，停止所有后台任务。停止后的引擎可以重新启动。
    /// 此方法不会抛出异常，即使引擎已经停止也会正常返回。
    func stop()
    
    /// 重置引擎
    ///
    /// 清除所有缓存，重置内部状态，但保持引擎运行。用于处理严重的错误状态
    /// 或需要强制刷新缓存的场景。
    func reset()
    
    /// 执行健康检查
    ///
    /// 检查引擎各个子系统的运行状态，确保所有组件正常工作。
    ///
    /// - Returns: 成功返回 `.success(true)`，失败返回包含错误信息的 `.failure`
    func performHealthCheck() -> Result<Bool, TETextEngineError>
    
    /// 处理原始文本
    ///
    /// 将原始文本字符串转换为属性化字符串，支持 Markdown 解析、链接检测等。
    ///
    /// - Parameters:
    ///   - text: 要处理的原始文本
    ///   - options: 处理选项，如果为 `nil` 则使用默认选项
    /// - Returns: 成功返回包含属性化字符串的 `.success`，失败返回 `.failure`
    func processText(_ text: String, options: TEProcessingOptions?) -> Result<NSAttributedString, TETextEngineError>
    
    /// 布局文本
    ///
    /// 对属性化字符串进行布局计算，确定每个字符的位置和行断点。
    ///
    /// - Parameters:
    ///   - attributedString: 要布局的属性化字符串
    ///   - containerSize: 容器的尺寸，用于确定布局边界
    /// - Returns: 成功返回包含布局信息的 `.success`，失败返回 `.failure`
    func layoutText(_ attributedString: NSAttributedString, containerSize: CGSize) -> Result<TETextLayout, TETextEngineError>
    
    /// 渲染文本
    ///
    /// 将布局好的文本渲染到指定的图形上下文中。
    ///
    /// - Parameters:
    ///   - layout: 包含布局信息的对象
    ///   - context: 目标图形上下文
    /// - Returns: 成功返回 `.success(())`，失败返回 `.failure`
    func renderText(_ layout: TETextLayout, in context: CGContext) -> Result<Void, TETextEngineError>
}

/// 文本处理选项结构体
///
/// `TEProcessingOptions` 提供了对文本处理过程的细粒度控制，
/// 包括异步处理、并发度、缓存策略和超时设置。
///
/// 主要用途：
/// - 控制文本处理的性能特征
/// - 调整并发度以平衡性能和资源使用
/// - 启用或禁用结果缓存
/// - 设置处理超时时间
///
/// 使用示例：
/// ```swift
/// // 高性能异步处理
/// let highPerformanceOptions = TEProcessingOptions(
///     enableAsync: true,
///     maxConcurrency: 8,
///     cacheResult: true,
///     timeout: 60.0
/// )
/// 
/// // 低内存占用处理
/// let lowMemoryOptions = TEProcessingOptions(
///     enableAsync: false,
///     maxConcurrency: 1,
///     cacheResult: false,
///     timeout: 30.0
/// )
/// 
/// // 使用自定义选项处理文本
/// let result = engine.processText("# Hello World", options: highPerformanceOptions)
/// ```
public struct TEProcessingOptions {
    /// 是否启用异步处理
    ///
    /// 当设置为 `true` 时，文本处理会在后台线程执行，不会阻塞当前线程。
    /// 当设置为 `false` 时，处理会同步执行，适用于对延迟敏感的场景。
    /// 默认值为 `true`。
    public var enableAsync: Bool
    
    /// 最大并发数
    ///
    /// 控制同时可以处理的最大任务数量。较高的值可以提高吞吐量，
    /// 但会消耗更多内存和 CPU 资源。建议根据设备性能和文本复杂度调整。
    /// 默认值为 `4`。
    public var maxConcurrency: Int
    
    /// 是否缓存处理结果
    ///
    /// 当设置为 `true` 时，处理结果会被缓存，相同的输入会直接返回缓存结果，
    /// 显著提高重复处理的性能。当设置为 `false` 时，每次都会重新处理。
    /// 默认值为 `true`。
    public var cacheResult: Bool
    
    /// 处理超时时间（秒）
    ///
    /// 设置文本处理的最大允许时间。超过此时间仍未完成的处理会被取消，
    /// 并返回超时错误。设置为 `0` 表示不设置超时限制。
    /// 默认值为 `30.0` 秒。
    public var timeout: TimeInterval
    
    /// 创建处理选项实例
    ///
    /// - Parameters:
    ///   - enableAsync: 是否启用异步处理，默认为 `true`
    ///   - maxConcurrency: 最大并发数，默认为 `4`
    ///   - cacheResult: 是否缓存结果，默认为 `true`
    ///   - timeout: 超时时间（秒），默认为 `30.0`
    public init(enableAsync: Bool = true, 
                maxConcurrency: Int = 4,
                cacheResult: Bool = true,
                timeout: TimeInterval = 30.0) {
        self.enableAsync = enableAsync
        self.maxConcurrency = maxConcurrency
        self.cacheResult = cacheResult
        self.timeout = timeout
    }
}

/// 文本布局结构体
///
/// `TETextLayout` 封装了文本布局的所有相关信息，包括属性化字符串、容器尺寸、
/// 布局管理器和文本存储。这个结构体是文本渲染的核心数据结构。
///
/// 主要用途：
/// - 在文本处理和渲染之间传递布局信息
/// - 缓存布局结果以提高性能
/// - 提供统一的布局数据接口
///
/// 使用示例：
/// ```swift
/// // 创建布局
/// let attributedString = NSAttributedString(string: "Hello World")
/// let containerSize = CGSize(width: 200, height: 100)
/// 
/// let layoutResult = engine.layoutText(attributedString, containerSize: containerSize)
/// 
/// switch layoutResult {
/// case .success(let textLayout):
///     // 使用布局信息进行渲染
///     print("布局成功，字符串长度: \(textLayout.attributedString.length)")
///     print("容器尺寸: \(textLayout.containerSize)")
///     print("布局管理器: \(textLayout.layoutManager)")
///     
///     // 渲染到图形上下文
///     let renderResult = engine.renderText(textLayout, in: context)
///     // ...
///     
/// case .failure(let error):
///     print("布局失败: \(error)")
/// }
/// ```
public struct TETextLayout {
    /// 属性化字符串
    ///
    /// 包含文本内容和所有样式属性的 `NSAttributedString` 实例。
    /// 这是布局计算的基础数据。
    public let attributedString: NSAttributedString
    
    /// 容器尺寸
    ///
    /// 文本容器的尺寸，定义了文本布局的边界。布局管理器会确保文本
    /// 内容适应这个尺寸，必要时进行换行处理。
    public let containerSize: CGSize
    
    /// 文本容器
    ///
    /// 负责管理文本布局的容器对象，包含布局配置和约束信息。
    public let textContainer: TETextContainer
    
    /// 布局管理器
    ///
    /// 执行实际布局计算的布局管理器，包含了所有布局结果和缓存信息。
    public let layoutManager: TELayoutManager
    
    /// 文本存储
    ///
    /// 可选的文本存储对象，用于管理文本内容的变更通知。
    /// 在某些高级场景下使用，通常为 `nil`。
    public let textStorage: Any?
    
    /// 创建文本布局实例
    ///
    /// - Parameters:
    ///   - attributedString: 属性化字符串
    ///   - containerSize: 容器尺寸
    ///   - textContainer: 文本容器
    ///   - layoutManager: 布局管理器
    ///   - textStorage: 可选的文本存储对象，默认为 `nil`
    public init(attributedString: NSAttributedString,
                containerSize: CGSize,
                textContainer: TETextContainer,
                layoutManager: TELayoutManager,
                textStorage: Any? = nil) {
        self.attributedString = attributedString
        self.containerSize = containerSize
        self.textContainer = textContainer
        self.layoutManager = layoutManager
        self.textStorage = textStorage
    }
}
