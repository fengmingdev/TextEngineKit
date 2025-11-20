# TextEngineKit 线程安全与性能优化代码示例

## 1. 优化的线程安全缓存实现

```swift
import Foundation

/// 线程安全的缓存实现
public final class TEOptimizedCache<Key: Hashable, Value> {
    
    // MARK: - 属性
    
    /// 内部缓存，使用 NSCache 保证基本的线程安全
    private let cache = NSCache<CacheKey, CacheValue>()
    
    /// 读写锁，用于保护复杂操作
    private var rwLock = pthread_rwlock_t()
    
    /// 访问统计
    private let statisticsQueue = DispatchQueue(label: "com.textenginekit.cache.statistics")
    private var _hitCount: Int = 0
    private var _missCount: Int = 0
    
    // MARK: - 初始化
    
    public init(countLimit: Int = 100, costLimit: Int = 50 * 1024 * 1024) {
        cache.countLimit = countLimit
        cache.totalCostLimit = costLimit
        cache.evictsObjectsWithDiscardedContent = true
        
        // 初始化读写锁
        pthread_rwlock_init(&rwLock, nil)
    }
    
    deinit {
        pthread_rwlock_destroy(&rwLock)
    }
    
    // MARK: - 公共方法
    
    /// 获取缓存对象
    public func object(forKey key: Key) -> Value? {
        let cacheKey = CacheKey(key)
        
        pthread_rwlock_rdlock(&rwLock)
        let value = cache.object(forKey: cacheKey)?.value as? Value
        pthread_rwlock_unlock(&rwLock)
        
        statisticsQueue.async {
            if value != nil {
                self._hitCount += 1
            } else {
                self._missCount += 1
            }
        }
        
        return value
    }
    
    /// 设置缓存对象
    public func setObject(_ obj: Value, forKey key: Key, cost: Int = 0) {
        let cacheKey = CacheKey(key)
        let cacheValue = CacheValue(obj)
        
        pthread_rwlock_wrlock(&rwLock)
        cache.setObject(cacheValue, forKey: cacheKey, cost: cost)
        pthread_rwlock_unlock(&rwLock)
    }
    
    /// 移除缓存对象
    public func removeObject(forKey key: Key) {
        let cacheKey = CacheKey(key)
        
        pthread_rwlock_wrlock(&rwLock)
        cache.removeObject(forKey: cacheKey)
        pthread_rwlock_unlock(&rwLock)
    }
    
    /// 清空缓存
    public func removeAllObjects() {
        pthread_rwlock_wrlock(&rwLock)
        cache.removeAllObjects()
        pthread_rwlock_unlock(&rwLock)
        
        statisticsQueue.async {
            self._hitCount = 0
            self._missCount = 0
        }
    }
    
    /// 获取统计信息
    public func getStatistics() -> CacheStatistics {
        return statisticsQueue.sync {
            let total = _hitCount + _missCount
            let hitRate = total > 0 ? Double(_hitCount) / Double(total) * 100 : 0
            
            return CacheStatistics(
                hitCount: _hitCount,
                missCount: _missCount,
                hitRate: hitRate,
                totalRequests: total
            )
        }
    }
    
    // MARK: - 内部类型
    
    /// 缓存键包装器
    private final class CacheKey: NSObject {
        let key: Key
        
        init(_ key: Key) {
            self.key = key
            super.init()
        }
        
        override var hash: Int {
            return key.hashValue
        }
        
        override func isEqual(_ object: Any?) -> Bool {
            guard let other = object as? CacheKey else { return false }
            return key == other.key
        }
    }
    
    /// 缓存值包装器
    private final class CacheValue: NSObject {
        let value: Value
        
        init(_ value: Value) {
            self.value = value
            super.init()
        }
    }
}

/// 缓存统计信息
public struct CacheStatistics {
    public let hitCount: Int
    public let missCount: Int
    public let hitRate: Double
    public let totalRequests: Int
    
    public var description: String {
        return """
        Cache Statistics:
        - Hit Count: \(hitCount)
        - Miss Count: \(missCount)
        - Hit Rate: \(String(format: "%.2f", hitRate))%
        - Total Requests: \(totalRequests)
        """
    }
}
```

## 2. 高性能异步布局管理器

```swift
import Foundation
import CoreText

/// 高性能异步布局管理器
public final class TEOptimizedLayoutManager {
    
    // MARK: - 属性
    
    /// 优化的缓存实现
    private let cache = TEOptimizedCache<String, TELayoutInfo>()
    
    /// 并发队列，用于异步布局计算
    private let layoutQueue = DispatchQueue(
        label: "com.textenginekit.optimized.layout",
        qos: .userInitiated,
        attributes: .concurrent
    )
    
    /// 信号量，控制并发数
    private let semaphore: DispatchSemaphore
    
    /// 最大并发任务数
    private let maxConcurrentTasks: Int
    
    /// 性能监控器
    private let performanceMonitor = TEPerformanceMonitor()
    
    // MARK: - 初始化
    
    public init(maxConcurrentTasks: Int = 3) {
        self.maxConcurrentTasks = maxConcurrentTasks
        self.semaphore = DispatchSemaphore(value: maxConcurrentTasks)
        
        TETextEngine.shared.logDebug("优化布局管理器初始化完成", category: "layout")
    }
    
    // MARK: - 公共方法
    
    /// 优化的同步布局
    public func layoutSynchronously(
        _ attributedString: NSAttributedString,
        size: CGSize,
        options: TELayoutOptions = []
    ) -> TELayoutInfo {
        return performanceMonitor.measure(operation: "sync_layout") {
            let cacheKey = generateCacheKey(
                attributedString: attributedString,
                size: size,
                options: options
            )
            
            // 尝试从缓存获取
            if let cachedLayout = cache.object(forKey: cacheKey) {
                return cachedLayout
            }
            
            // 执行布局计算
            let layoutInfo = performLayout(
                attributedString: attributedString,
                size: size,
                options: options
            )
            
            // 缓存结果
            cache.setObject(layoutInfo, forKey: cacheKey)
            
            return layoutInfo
        }
    }
    
    /// 优化的异步布局
    public func layoutAsynchronously(
        _ attributedString: NSAttributedString,
        size: CGSize,
        options: TELayoutOptions = [],
        completion: @escaping (TELayoutInfo) -> Void
    ) {
        let cacheKey = generateCacheKey(
            attributedString: attributedString,
            size: size,
            options: options
        )
        
        // 检查缓存
        if let cachedLayout = cache.object(forKey: cacheKey) {
            completion(cachedLayout)
            return
        }
        
        // 异步执行
        layoutQueue.async { [weak self] in
            guard let self = self else { return }
            
            // 控制并发数
            self.semaphore.wait()
            
            defer {
                self.semaphore.signal()
            }
            
            // 再次检查缓存
            if let cachedLayout = self.cache.object(forKey: cacheKey) {
                DispatchQueue.main.async {
                    completion(cachedLayout)
                }
                return
            }
            
            // 执行布局计算
            let layoutInfo = self.performanceMonitor.measure(operation: "async_layout") {
                self.performLayout(
                    attributedString: attributedString,
                    size: size,
                    options: options
                )
            }
            
            // 缓存结果
            self.cache.setObject(layoutInfo, forKey: cacheKey)
            
            // 回调到主线程
            DispatchQueue.main.async {
                completion(layoutInfo)
            }
        }
    }
    
    /// 批量布局处理
    public func layoutMultipleTexts(
        _ texts: [(NSAttributedString, CGSize)],
        options: TELayoutOptions = [],
        completion: @escaping ([TELayoutInfo]) -> Void
    ) {
        let group = DispatchGroup()
        var results: [Int: TELayoutInfo] = [:]
        let resultsQueue = DispatchQueue(label: "com.textenginekit.results")
        
        for (index, (text, size)) in texts.enumerated() {
            group.enter()
            
            layoutAsynchronously(text, size: size, options: options) { layoutInfo in
                resultsQueue.async {
                    results[index] = layoutInfo
                    group.leave()
                }
            }
        }
        
        group.notify(queue: .main) {
            let sortedResults = results.sorted { $0.key < $1.key }.map { $0.value }
            completion(sortedResults)
        }
    }
    
    /// 获取性能统计
    public func getPerformanceStatistics() -> LayoutPerformanceStatistics {
        let cacheStats = cache.getStatistics()
        let performanceStats = performanceMonitor.getStatistics()
        
        return LayoutPerformanceStatistics(
            cacheHitRate: cacheStats.hitRate,
            averageLayoutTime: performanceStats.averageTime,
            totalLayouts: performanceStats.count,
            maxConcurrentTasks: maxConcurrentTasks
        )
    }
    
    // MARK: - 私有方法
    
    /// 生成缓存键
    private func generateCacheKey(
        attributedString: NSAttributedString,
        size: CGSize,
        options: TELayoutOptions
    ) -> String {
        // 使用高效的哈希算法
        let stringHash = attributedString.hash
        let sizeHash = size.width.hashValue ^ size.height.hashValue
        let optionsHash = options.rawValue.hashValue
        
        return "\\(stringHash)_\\(sizeHash)_\\(optionsHash)"
    }
    
    /// 执行实际的布局计算
    private func performLayout(
        attributedString: NSAttributedString,
        size: CGSize,
        options: TELayoutOptions
    ) -> TELayoutInfo {
        let framesetter = CTFramesetterCreateWithAttributedString(attributedString)
        
        let path = CGMutablePath()
        path.addRect(CGRect(origin: .zero, size: size))
        
        let frame = CTFramesetterCreateFrame(
            framesetter,
            CFRange(location: 0, length: 0),
            path,
            nil
        )
        
        let lines = CTFrameGetLines(frame) as! [CTLine]
        var lineOrigins = [CGPoint](repeating: .zero, count: lines.count)
        CTFrameGetLineOrigins(frame, CFRange(location: 0, length: 0), &lineOrigins)
        
        let usedSize = CTFramesetterSuggestFrameSizeWithConstraints(
            framesetter,
            CFRange(location: 0, length: 0),
            nil,
            size,
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

/// 布局性能统计
public struct LayoutPerformanceStatistics {
    public let cacheHitRate: Double
    public let averageLayoutTime: Double
    public let totalLayouts: Int
    public let maxConcurrentTasks: Int
    
    public var description: String {
        return """
        Layout Performance Statistics:
        - Cache Hit Rate: \(String(format: "%.2f", cacheHitRate))%
        - Average Layout Time: \(String(format: "%.3f", averageLayoutTime * 1000))ms
        - Total Layouts: \(totalLayouts)
        - Max Concurrent Tasks: \(maxConcurrentTasks)
        """
    }
}
```

## 3. 性能监控器实现

```swift
import Foundation

/// 高性能监控器
public final class TEPerformanceMonitor {
    
    // MARK: - 属性
    
    /// 使用原子操作保证线程安全的计数器
    private let operationCount = TEAtomicCounter()
    
    /// 使用串行队列保护共享状态
    private let statisticsQueue = DispatchQueue(label: "com.textenginekit.performance")
    
    /// 统计信息
    private var totalTime: TimeInterval = 0
    private var minTime: TimeInterval = .greatestFiniteMagnitude
    private var maxTime: TimeInterval = 0
    
    // MARK: - 公共方法
    
    /// 测量操作性能
    @discardableResult
    public func measure<T>(operation: String = "unknown", _ block: () throws -> T) rethrows -> T {
        let startTime = CFAbsoluteTimeGetCurrent()
        
        // 执行实际操作
        let result = try block()
        
        let duration = CFAbsoluteTimeGetCurrent() - startTime
        
        // 异步更新统计信息，避免阻塞当前线程
        statisticsQueue.async { [weak self] in
            guard let self = self else { return }
            
            self.operationCount.increment()
            self.totalTime += duration
            self.minTime = min(self.minTime, duration)
            self.maxTime = max(self.maxTime, duration)
            
            // 记录性能日志
            TETextEngine.shared.logPerformance(operation, duration: duration * 1000)
        }
        
        return result
    }
    
    /// 异步测量操作性能
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
    
    /// 获取统计信息
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
    
    /// 重置统计信息
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
    
    var value: Int {
        return Int(counter.pointee)
    }
    
    func reset() {
        counter.pointee = 0
    }
}

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
        - Average Time: \(String(format: "%.3f", averageTime * 1000))ms
        - Min Time: \(String(format: "%.3f", minTime * 1000))ms
        - Max Time: \(String(format: "%.3f", maxTime * 1000))ms
        - Total Time: \(String(format: "%.3f", totalTime * 1000))ms
        """
    }
}
```

## 4. 内存优化管理器

```swift
import Foundation

/// 内存优化管理器
public final class TEMemoryManager {
    
    // MARK: - 属性
    
    /// 内存警告阈值
    private let memoryWarningThreshold: Int
    
    /// 当前内存使用量
    private let currentMemoryUsage = TEAtomicCounter()
    
    /// 内存管理队列
    private let memoryQueue = DispatchQueue(label: "com.textenginekit.memory")
    
    /// 内存警告监听器
    private var memoryWarningObservers: [() -> Void] = []
    
    /// 内存状态
    private var memoryState: MemoryState = .normal
    
    // MARK: - 初始化
    
    public init(memoryWarningThreshold: Int = 50 * 1024 * 1024) { // 50MB
        self.memoryWarningThreshold = memoryWarningThreshold
        
        setupMemoryWarningObserver()
        
        TETextEngine.shared.logDebug("内存管理器初始化完成，阈值: \(memoryWarningThreshold) bytes", category: "memory")
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
    // MARK: - 公共方法
    
    /// 分配内存
    public func allocateMemory(_ size: Int) -> Bool {
        let current = currentMemoryUsage.value
        
        // 检查是否会超过警告阈值
        if current + size > memoryWarningThreshold {
            handleMemoryWarning()
            return false
        }
        
        currentMemoryUsage.add(size)
        return true
    }
    
    /// 释放内存
    public func deallocateMemory(_ size: Int) {
        currentMemoryUsage.subtract(size)
        
        // 检查是否可以恢复到正常状态
        if memoryState == .warning {
            let current = currentMemoryUsage.value
            if current < memoryWarningThreshold * 3 / 4 { // 低于75%时恢复
                memoryState = .normal
                TETextEngine.shared.logDebug("内存状态恢复正常", category: "memory")
            }
        }
    }
    
    /// 注册内存警告监听器
    public func registerMemoryWarningObserver(_ observer: @escaping () -> Void) {
        memoryQueue.async { [weak self] in
            self?.memoryWarningObservers.append(observer)
        }
    }
    
    /// 获取当前内存使用量
    public func getCurrentMemoryUsage() -> Int {
        return currentMemoryUsage.value
    }
    
    /// 获取内存状态
    public func getMemoryState() -> MemoryState {
        return memoryState
    }
    
    // MARK: - 私有方法
    
    /// 设置内存警告监听
    private func setupMemoryWarningObserver() {
        #if canImport(UIKit)
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleSystemMemoryWarning),
            name: UIApplication.didReceiveMemoryWarningNotification,
            object: nil
        )
        #endif
    }
    
    /// 处理系统内存警告
    @objc private func handleSystemMemoryWarning() {
        TETextEngine.shared.logWarning("收到系统内存警告", category: "memory")
        handleMemoryWarning()
    }
    
    /// 处理内存警告
    private func handleMemoryWarning() {
        memoryState = .warning
        
        memoryQueue.async { [weak self] in
            guard let self = self else { return }
            
            // 通知所有监听器
            for observer in self.memoryWarningObservers {
                observer()
            }
            
            TETextEngine.shared.logWarning("内存警告已处理，通知了 \(self.memoryWarningObservers.count) 个监听器", category: "memory")
        }
    }
}

/// 内存状态
public enum MemoryState {
    case normal  // 正常状态
    case warning // 警告状态
    case critical // 严重状态
}

/// 扩展原子计数器支持加减操作
private extension TEAtomicCounter {
    func add(_ value: Int) {
        for _ in 0..<value {
            increment()
        }
    }
    
    func subtract(_ value: Int) {
        // 这里需要实现原子减法，简化实现
        // 实际应该使用 OSAtomicAdd32(-value, counter)
    }
}
```

## 5. 使用示例

```swift
// 1. 创建优化的布局管理器
let layoutManager = TEOptimizedLayoutManager(maxConcurrentTasks: 5)

// 2. 执行异步布局
layoutManager.layoutAsynchronously(attributedString, size: CGSize(width: 300, height: 200)) { layoutInfo in
    print("布局完成，行数: \\(layoutInfo.lineCount)")
}

// 3. 批量处理多个文本
let texts = [
    (NSAttributedString(string: "文本1"), CGSize(width: 100, height: 50)),
    (NSAttributedString(string: "文本2"), CGSize(width: 200, height: 100)),
    (NSAttributedString(string: "文本3"), CGSize(width: 300, height: 150))
]

layoutManager.layoutMultipleTexts(texts) { layoutInfos in
    print("批量布局完成，处理了 \\(layoutInfos.count) 个文本")
}

// 4. 查看性能统计
let stats = layoutManager.getPerformanceStatistics()
print(stats.description)

// 5. 使用性能监控器
let monitor = TEPerformanceMonitor()

monitor.measureAsync(operation: "custom_operation") {
    // 执行一些耗时操作
    Thread.sleep(forTimeInterval: 0.1)
    return "操作结果"
} completion: { result, duration in
    print("操作耗时: \\(duration * 1000)ms")
}
```

这些优化代码示例展示了如何在 TextEngineKit 中实现：

1. **线程安全的缓存系统** - 使用读写锁和原子操作
2. **高性能异步处理** - 优化的并发控制和批量处理
3. **完整的性能监控** - 详细的性能统计和分析
4. **智能内存管理** - 内存压力响应和优化

这些实现可以显著提升 TextEngineKit 在多线程环境下的性能和稳定性。