import Foundation
import FMLogger
#if canImport(CoreGraphics)
import CoreGraphics
#endif
#if canImport(CoreText)
import CoreText
#endif

/// 性能统计信息
public struct PerformanceStatistics {
    public let count: Int
    public let averageTime: TimeInterval
    public let minTime: TimeInterval
    public let maxTime: TimeInterval
    public let totalTime: TimeInterval
    
    public var description: String {
        return """
        Performance Statistics:
        - Total Operations: \(count)
        - Average Time: \(String(format: "%.3f", averageTime))ms
        - Min Time: \(String(format: "%.3f", minTime))ms
        - Max Time: \(String(format: "%.3f", maxTime))ms
        - Total Time: \(String(format: "%.3f", totalTime))ms
        """
    }
}

/// 配置管理服务协议
public protocol TEConfigurationManagerProtocol {
    var configuration: TEConfiguration { get set }
    func updateConfiguration(_ configuration: TEConfiguration)
    func resetToDefault()
}

/// 配置管理服务
public final class TEConfigurationManager: TEConfigurationManagerProtocol {
    
    // MARK: - 属性
    
    private var _configuration: TEConfiguration
    
    public var configuration: TEConfiguration {
        get { _configuration }
        set { _configuration = newValue }
    }
    
    // MARK: - 初始化
    
    public init(configuration: TEConfiguration = TEConfiguration()) {
        self._configuration = configuration
    }
    
    // MARK: - 公共方法
    
    public func updateConfiguration(_ configuration: TEConfiguration) {
        self.configuration = configuration
        // 安全日志：不输出具体配置内容
        FMLogger.shared.log("配置已更新", level: .info, category: "configuration", metadata: nil)
    }
    
    public func resetToDefault() {
        self.configuration = TEConfiguration()
        FMLogger.shared.log("配置已重置为默认值", level: .info, category: "configuration", metadata: nil)
    }
}

/// 日志服务协议
public protocol TETextLoggerProtocol {
    func log(_ message: String, level: TELogLevel, category: String, metadata: [String: Any]?)
}

/// 日志服务实现
public final class TETextLogger: TETextLoggerProtocol {
    
    // MARK: - 属性
    
    private let logger: FMLogger
    
    // MARK: - 初始化
    
    public init() {
        self.logger = FMLogger.shared
    }
    
    // MARK: - 公共方法
    
    public func log(_ message: String, level: TELogLevel, category: String, metadata: [String: Any]?) {
        logger.log(message, level: level.fmLogLevel, category: category, metadata: metadata)
    }
}

/// 性能监控服务协议
public protocol TEPerformanceMonitorProtocol {
    func measure<T>(operation: String, _ block: () throws -> T) rethrows -> T
    func measureAsync<T>(operation: String, _ block: @escaping () throws -> T, completion: @escaping (Result<T, Error>, TimeInterval) -> Void)
    func getStatistics() -> PerformanceStatistics
    func reset()
}

/// 性能监控服务
public final class TEPerformanceMonitor: TEPerformanceMonitorProtocol {
    
    // MARK: - 属性
    
    private let operationCount = TEAtomicCounter()
    private let statisticsQueue = DispatchQueue(label: "com.textenginekit.performance")
    private var totalTime: TimeInterval = 0
    private var minTime: TimeInterval = .greatestFiniteMagnitude
    private var maxTime: TimeInterval = 0
    
    // MARK: - 初始化
    
    public init() {
        // 初始化完成
    }
    
    // MARK: - 公共方法
    
    @discardableResult
    public func measure<T>(operation: String = "unknown", _ block: () throws -> T) rethrows -> T {
        let startTime = CFAbsoluteTimeGetCurrent()
        
        let result = try block()
        
        let duration = CFAbsoluteTimeGetCurrent() - startTime
        
        statisticsQueue.async { [weak self] in
            guard let self = self else { return }
            
            self.operationCount.increment()
            self.totalTime += duration
            self.minTime = min(self.minTime, duration)
            self.maxTime = max(self.maxTime, duration)
            
            // 记录性能日志
            FMLogger.shared.log("性能指标", level: .debug, category: "performance", metadata: [
                "operation": operation,
                "duration_ms": String(format: "%.3f", duration * 1000)
            ])
        }
        
        return result
    }
    
    public func measureAsync<T>(
        operation: String = "unknown",
        _ block: @escaping () throws -> T,
        completion: @escaping (Result<T, Error>, TimeInterval) -> Void
    ) {
        let startTime = CFAbsoluteTimeGetCurrent()
        
        DispatchQueue.global(qos: .userInitiated).async {
            do {
                let result = try block()
                let duration = CFAbsoluteTimeGetCurrent() - startTime
                
                self.statisticsQueue.async { [weak self] in
                    guard let self = self else { return }
                    
                    self.operationCount.increment()
                    self.totalTime += duration
                    self.minTime = min(self.minTime, duration)
                    self.maxTime = max(self.maxTime, duration)
                }
                
                DispatchQueue.main.async {
                    completion(.success(result), duration)
                }
            } catch {
                let duration = CFAbsoluteTimeGetCurrent() - startTime
                DispatchQueue.main.async {
                    completion(.failure(error), duration)
                }
            }
        }
    }
    
    public func getStatistics() -> PerformanceStatistics {
        return statisticsQueue.sync {
            let count = operationCount.value
            let avgTime = count > 0 ? totalTime / Double(count) : 0
            let minTime = count > 0 ? minTime : 0
            let maxTime = count > 0 ? maxTime : 0
            
            return PerformanceStatistics(
                count: count,
                averageTime: avgTime,
                minTime: minTime,
                maxTime: maxTime,
                totalTime: totalTime
            )
        }
    }
    
    public func reset() {
        statisticsQueue.async { [weak self] in
            guard let self = self else { return }
            
            self.operationCount.reset()
            self.totalTime = 0
            self.minTime = .greatestFiniteMagnitude
            self.maxTime = 0
        }
    }
}

/// 缓存管理服务协议
public protocol TECacheManagerProtocol {
    func get<T>(_ key: String) -> T?
    func set<T>(_ value: T, forKey key: String)
    func remove(forKey key: String)
    func clear()
}

/// 缓存管理服务
public final class TECacheManager: TECacheManagerProtocol {
    
    // MARK: - 属性
    
    private let cache = NSCache<NSString, AnyObject>()
    private let configuration: TECacheConfiguration
    
    // MARK: - 初始化
    
    public init(configuration: TECacheConfiguration = .default) {
        self.configuration = configuration
        setupCache()
    }
    
    // MARK: - 公共方法
    
    public func get<T>(_ key: String) -> T? {
        return cache.object(forKey: key as NSString) as? T
    }
    
    public func set<T>(_ value: T, forKey key: String) {
        cache.setObject(value as AnyObject, forKey: key as NSString)
    }
    
    public func remove(forKey key: String) {
        cache.removeObject(forKey: key as NSString)
    }
    
    public func clear() {
        cache.removeAllObjects()
    }
    
    // MARK: - 私有方法
    
    private func setupCache() {
        cache.countLimit = configuration.countLimit
        cache.totalCostLimit = configuration.memoryLimit
        cache.evictsObjectsWithDiscardedContent = true
    }
}

/// 缓存配置
public struct TECacheConfiguration {
    let countLimit: Int
    let memoryLimit: Int
    let evictionPolicy: TEEvictionPolicy
    
    public static let `default` = TECacheConfiguration(
        countLimit: 100,
        memoryLimit: 50 * 1024 * 1024,
        evictionPolicy: .lru
    )
}

/// 缓存淘汰策略
public enum TEEvictionPolicy {
    case lru  // 最近最少使用
    case fifo // 先进先出
    case lfu  // 最少使用
}

/// 统计服务协议
public protocol TEStatisticsServiceProtocol {
    func registerProvider(_ provider: TEMetricProvider, for category: String)
    func collectAllMetrics() -> [String: [TEMetric]]
}

/// 统计服务
public final class TEStatisticsService: TEStatisticsServiceProtocol {
    
    // MARK: - 属性
    
    private var providers: [String: TEMetricProvider] = [:]
    private let providersQueue = DispatchQueue(label: "com.textenginekit.statistics", attributes: .concurrent)
    
    // MARK: - 初始化
    
    public init() {
        // 初始化完成
    }
    
    // MARK: - 公共方法
    
    public func registerProvider(_ provider: TEMetricProvider, for category: String) {
        providersQueue.async(flags: .barrier) { [weak self] in
            self?.providers[category] = provider
        }
    }
    
    public func collectAllMetrics() -> [String: [TEMetric]] {
        return providersQueue.sync {
            var result: [String: [TEMetric]] = [:]
            
            for (category, provider) in providers {
                result[category] = provider.getMetrics()
            }
            
            return result
        }
    }
}

/// 布局服务协议
public protocol TELayoutServiceProtocol {
    func layout(_ text: NSAttributedString, container: TETextContainer, options: TELayoutOptions) -> TELayoutInfo
}

/// 布局服务
public final class TELayoutService: TELayoutServiceProtocol {
    
    // MARK: - 属性
    
    private var cacheManager: TECacheManagerProtocol?
    private var performanceMonitor: TEPerformanceMonitorProtocol?
    
    // MARK: - 初始化
    
    public init() {
        // 依赖注入初始化
        Task {
            self.cacheManager = await TEContainer.shared.resolve(TECacheManagerProtocol.self)
            self.performanceMonitor = await TEContainer.shared.resolve(TEPerformanceMonitorProtocol.self)
        }
    }
    
    // MARK: - 公共方法
    
    public func layout(_ text: NSAttributedString, container: TETextContainer, options: TELayoutOptions) -> TELayoutInfo {
        guard let performanceMonitor = performanceMonitor, let cacheManager = cacheManager else {
            // 如果依赖未初始化，直接执行布局计算
            return performLayout(text: text, container: container, options: options)
        }
        
        return performanceMonitor.measure(operation: "layout") {
            // 生成缓存键
            let cacheKey = generateCacheKey(text: text, container: container, options: options)
            
            // 尝试从缓存获取
            if let cachedLayout = cacheManager.get(cacheKey) as TELayoutInfo? {
                return cachedLayout
            }
            
            // 执行实际布局计算
            let layoutInfo = performLayout(text: text, container: container, options: options)
            
            // 缓存结果
            cacheManager.set(layoutInfo, forKey: cacheKey)
            
            return layoutInfo
        }
    }
    
    // MARK: - 私有方法
    
    private func generateCacheKey(text: NSAttributedString, container: TETextContainer, options: TELayoutOptions) -> String {
        let textHash = text.hash
        let containerHash = container.size.width.hashValue ^ container.size.height.hashValue
        let optionsHash = options.rawValue.hashValue
        
        return "\(textHash)_\(containerHash)_\(optionsHash)"
    }
    
    private func performLayout(text: NSAttributedString, container: TETextContainer, options: TELayoutOptions) -> TELayoutInfo {
        let framesetter = CTFramesetterCreateWithAttributedString(text)
        
        let path = CGMutablePath()
        path.addRect(CGRect(origin: .zero, size: container.size))
        
        let frame = CTFramesetterCreateFrame(
            framesetter,
            CFRange(location: 0, length: 0),
            path,
            nil
        )
        
        let cfLines = CTFrameGetLines(frame)
        let lines = (cfLines as NSArray as? [CTLine]) ?? []
        var lineOrigins = [CGPoint](repeating: .zero, count: lines.count)
        CTFrameGetLineOrigins(frame, CFRange(location: 0, length: 0), &lineOrigins)
        
        let usedSize = CTFramesetterSuggestFrameSizeWithConstraints(
            framesetter,
            CFRange(location: 0, length: 0),
            nil,
            container.size,
            nil
        )
        
        return TELayoutInfo(
            frame: frame,
            lines: lines,
            lineOrigins: lineOrigins,
            size: CTFrameGetVisibleStringRange(frame),
            usedSize: usedSize
        )
    }
}

/// 渲染服务协议
public protocol TERenderingServiceProtocol {
    func render(_ layout: TELayoutInfo, context: CGContext, options: TERenderOptions)
}

/// 渲染服务
public final class TERenderingService: TERenderingServiceProtocol {
    
    // MARK: - 属性
    
    private var performanceMonitor: TEPerformanceMonitorProtocol?
    
    // MARK: - 初始化
    
    public init() {
        // 依赖注入初始化
        Task {
            self.performanceMonitor = await TEContainer.shared.resolve(TEPerformanceMonitorProtocol.self)
        }
    }
    
    // MARK: - 公共方法
    
    public func render(_ layout: TELayoutInfo, context: CGContext, options: TERenderOptions) {
        guard let performanceMonitor = performanceMonitor else {
            // 如果依赖未初始化，直接执行渲染逻辑
            CTFrameDraw(layout.frame, context)
            return
        }
        
        performanceMonitor.measure(operation: "render") {
            // 执行渲染逻辑
            CTFrameDraw(layout.frame, context)
        }
    }
}

/// 解析服务协议
public protocol TEParsingServiceProtocol {
    func parse(_ text: String, parserType: TEParserType) -> NSAttributedString
}

/// 解析服务
public final class TEParsingService: TEParsingServiceProtocol {
    
    // MARK: - 属性
    
    private let parsers: [TEParserType: TETextParser] = [
        .markdown: TEMarkdownParser(),
        .emoji: TEEmojiParser(),
        .composite: TECompositeParser(parsers: [TEMarkdownParser(), TEEmojiParser()])
    ]
    
    // MARK: - 初始化
    
    public init() {
        // 初始化完成
    }
    
    // MARK: - 公共方法
    
    public func parse(_ text: String, parserType: TEParserType) -> NSAttributedString {
        guard let parser = parsers[parserType] else {
            return NSAttributedString(string: text)
        }
        
        return parser.parse(text)
    }
}

/// 平台服务协议
public protocol TEPlatformServiceProtocol {
    func getPlatformInfo() -> TEPlatformInfo
    func isFeatureAvailable(_ feature: TEPlatformFeature) -> Bool
}

/// 平台服务
public final class TEPlatformService: TEPlatformServiceProtocol {
    
    // MARK: - 初始化
    
    public init() {
        // 初始化完成
    }
    
    // MARK: - 公共方法
    
    public func getPlatformInfo() -> TEPlatformInfo {
        return TEPlatformInfo(
            platform: TEPlatform.current,
            version: TEPlatform.systemVersion,
            isSimulator: TEPlatform.isSimulator
        )
    }
    
    public func isFeatureAvailable(_ feature: TEPlatformFeature) -> Bool {
        switch feature {
        case .richTextClipboard:
            if #available(iOS 14.0, macOS 11.0, *) {
                return true
            } else {
                return false
            }
        }
    }
}

/// 平台信息
public struct TEPlatformInfo {
    public let platform: String
    public let version: String
    public let isSimulator: Bool
}

/// 平台特性
public enum TEPlatformFeature {
    case richTextClipboard
}

/// 解析器类型
public enum TEParserType {
    case markdown
    case emoji
    case composite
}

/// 性能指标
public struct TEMetric {
    let operation: String
    let duration: TimeInterval
    let metadata: [String: Any]?
    
    var description: String {
        return "\(operation) 耗时 \(String(format: "%.3f", duration))ms"
    }
}

/// 指标提供者协议
public protocol TEMetricProvider {
    func getMetrics() -> [TEMetric]
}

/// 原子计数器
private final class TEAtomicCounter {
    private let counter = UnsafeMutablePointer<Int32>.allocate(capacity: 1)
    
    init() {
        counter.pointee = 0
    }
    
    deinit {
        counter.deallocate()
    }
    
    func increment() {
        OSAtomicIncrement32(counter)
    }
    
    func add(_ value: Int) {
        for _ in 0..<value {
            increment()
        }
    }
    
    var value: Int {
        return Int(counter.pointee)
    }
    
    func reset() {
        counter.pointee = 0
    }
}

/// 线程安全属性包装器
@propertyWrapper
public struct ThreadSafe<T> {
    private var value: T
    private let lock = NSLock()
    
    public init(wrappedValue: T) {
        self.value = wrappedValue
    }
    
    public var wrappedValue: T {
        get {
            lock.lock()
            defer { lock.unlock() }
            return value
        }
        set {
            lock.lock()
            defer { lock.unlock() }
            value = newValue
        }
    }
}
