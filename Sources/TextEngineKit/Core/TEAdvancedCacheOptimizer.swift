// 
//  TEAdvancedCacheOptimizer.swift 
//  TextEngineKit 
// 
//  Created by fengming on 2025/11/17. 
// 
//  高级缓存优化：提供缓存成本估算与命中策略优化，提升布局与渲染性能。 
// 
import Foundation

/// 高级缓存策略优化器
/// 提供多层级、智能缓存策略，显著提升性能
public actor TEAdvancedCacheOptimizer {
    
    // MARK: - 缓存策略定义
    
    /// 缓存策略
    public enum TECacheStrategy {
        case lru(capacity: Int)              // 最近最少使用
        case lfu(capacity: Int)              // 最不经常使用
        case fifo(capacity: Int)              // 先进先出
        case adaptive(capacity: Int)          // 自适应策略
        case timeBased(ttl: TimeInterval)    // 基于时间
        case hybrid(lruCapacity: Int, ttl: TimeInterval) // 混合策略
    }
    
    /// 缓存层级
    public enum TECacheLevel: Int, CaseIterable {
        case memory = 0      // 内存缓存（最快）
        case disk = 1        // 磁盘缓存（中等）
        case network = 2     // 网络缓存（最慢）
        
        var description: String {
            switch self {
            case .memory: return "内存缓存"
            case .disk: return "磁盘缓存"
            case .network: return "网络缓存"
            }
        }
        
        var typicalLatency: TimeInterval {
            switch self {
            case .memory: return 0.001  // 1ms
            case .disk: return 0.01     // 10ms
            case .network: return 0.1   // 100ms
            }
        }
    }
    
    /// 缓存统计信息
    public struct TECacheStatistics {
        var totalRequests: Int
        var cacheHits: Int
        var cacheMisses: Int
        var hitRate: Double
        var averageResponseTime: TimeInterval
        var memoryUsage: Int
        var diskUsage: Int
        var evictionCount: Int
        var errorCount: Int
        
        public var description: String {
            return """
            缓存统计信息:
            - 总请求数: \(totalRequests)
            - 缓存命中: \(cacheHits)
            - 缓存未命中: \(cacheMisses)
            - 命中率: \(String(format: "%.2f%%", hitRate * 100))
            - 平均响应时间: \(String(format: "%.3fms", averageResponseTime * 1000))
            - 内存使用: \(formatBytes(memoryUsage))
            - 磁盘使用: \(formatBytes(diskUsage))
            - 淘汰次数: \(evictionCount)
            - 错误次数: \(errorCount)
            """
        }
        
        private func formatBytes(_ bytes: Int) -> String {
            let formatter = ByteCountFormatter()
            formatter.countStyle = .file
            return formatter.string(fromByteCount: Int64(bytes))
        }
    }
    
    /// 缓存条目
    private class TECacheEntry {
        let key: String
        let value: Any
        let size: Int
        let creationTime: Date
        var lastAccessTime: Date
        var accessCount: Int
        let level: TECacheLevel
        
        init(key: String, value: Any, size: Int, level: TECacheLevel) {
            self.key = key
            self.value = value
            self.size = size
            self.creationTime = Date()
            self.lastAccessTime = Date()
            self.accessCount = 1
            self.level = level
        }
        
        func recordAccess() {
            lastAccessTime = Date()
            accessCount += 1
        }
        
        var age: TimeInterval {
            return Date().timeIntervalSince(creationTime)
        }
        
        var timeSinceLastAccess: TimeInterval {
            return Date().timeIntervalSince(lastAccessTime)
        }
    }
    
    // MARK: - 属性
    
    private var logger: TETextLoggerProtocol?
    private var performanceMonitor: TEPerformanceMonitorProtocol?
    
    /// 单例实例
    public nonisolated static let shared = TEAdvancedCacheOptimizer()
    
    /// 内存缓存
    private var memoryCache: [String: TECacheEntry] = [:]
    
    /// 磁盘缓存路径
    private let diskCacheDirectory: URL
    
    /// 缓存策略
    private var cacheStrategy: TECacheStrategy
    
    /// 内存缓存大小限制
    private let memoryCacheLimit: Int
    
    /// 磁盘缓存大小限制
    private let diskCacheLimit: Int
    
    /// 统计信息
    private var statistics: TECacheStatistics
    
    /// 缓存命中记录
    private var hitRecords: [String: Date] = [:]
    
    /// 后台清理任务
    private var cleanupTimer: Timer?
    private var cleanupTask: Task<Void, Never>?
    
    // MARK: - 初始化
    
    private init() {
        // 设置缓存目录
        let chosenDirectory: URL
        if let cachesDirectory = FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask).first {
            let target = cachesDirectory.appendingPathComponent("TextEngineKitCache")
            do {
                try FileManager.default.createDirectory(at: target, withIntermediateDirectories: true)
                chosenDirectory = target
            } catch {
                let fallback = URL(fileURLWithPath: NSTemporaryDirectory()).appendingPathComponent("TextEngineKitCache")
                _ = try? FileManager.default.createDirectory(at: fallback, withIntermediateDirectories: true)
                chosenDirectory = fallback
            }
        } else {
            let fallback = URL(fileURLWithPath: NSTemporaryDirectory()).appendingPathComponent("TextEngineKitCache")
            _ = try? FileManager.default.createDirectory(at: fallback, withIntermediateDirectories: true)
            chosenDirectory = fallback
        }
        diskCacheDirectory = chosenDirectory
        
        // 默认配置
        self.cacheStrategy = .hybrid(lruCapacity: 100, ttl: 300) // 100项容量，5分钟TTL
        self.memoryCacheLimit = 50 * 1024 * 1024 // 50MB
        self.diskCacheLimit = 200 * 1024 * 1024 // 200MB
        
        // 初始化统计信息
        self.statistics = TECacheStatistics(
            totalRequests: 0,
            cacheHits: 0,
            cacheMisses: 0,
            hitRate: 0.0,
            averageResponseTime: 0.0,
            memoryUsage: 0,
            diskUsage: 0,
            evictionCount: 0,
            errorCount: 0
        )
        
        // 初始化依赖注入属性将在需要时进行
        // 延迟启动后台清理任务
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) { [weak self] in
            guard let self = self else { return }
            Task {
                await self.startCleanupTimer()
                await self.logInitialization()
            }
        }
    }
    
    /// 记录初始化日志
    private func logInitialization() async {
        if logger == nil {
            logger = await TEContainer.shared.resolve(TETextLoggerProtocol.self)
        }
        logger?.log("高级缓存优化器初始化完成", level: .info, category: "cache.optimizer", metadata: nil)
    }
    
    /// 获取性能监控器
    private func getPerformanceMonitor() async -> TEPerformanceMonitorProtocol? {
        if performanceMonitor == nil {
            performanceMonitor = await TEContainer.shared.resolve(TEPerformanceMonitorProtocol.self)
        }
        return performanceMonitor
    }
    
    deinit {
        cleanupTimer?.invalidate()
        cleanupTask?.cancel()
    }
    
    // MARK: - 缓存操作
    
    /// 获取缓存值
    /// - Parameters:
    ///   - key: 缓存键
    ///   - level: 缓存层级
    /// - Returns: 缓存值
    public func get<T>(_ key: String, level: TECacheLevel = .memory) async -> T? {
        let startTime = CFAbsoluteTimeGetCurrent()
        
        await updateStatistics { stats in
            var newStats = stats
            newStats.totalRequests += 1
            return newStats
        }
        
        // 尝试从指定层级开始查找
        let levelIndex = level.rawValue
        for cacheLevel in TECacheLevel.allCases where cacheLevel.rawValue >= levelIndex {
            if let value = await getFromLevel(key, level: cacheLevel) as? T {
                let responseTime = CFAbsoluteTimeGetCurrent() - startTime
                await recordHit(key: key, level: cacheLevel, responseTime: responseTime)
                return value
            }
        }
        
        // 未命中
        let responseTime = CFAbsoluteTimeGetCurrent() - startTime
        await recordMiss(key: key, responseTime: responseTime)
        return nil
    }
    
    /// 设置缓存值
    /// - Parameters:
    ///   - key: 缓存键
    ///   - value: 缓存值
    ///   - level: 缓存层级
    public func set<T>(_ key: String, value: T, level: TECacheLevel = .memory) async {
        let size = estimateSize(of: value)
        let entry = TECacheEntry(key: key, value: value, size: size, level: level)
        
        switch level {
        case .memory:
            await setInMemoryCache(entry)
        case .disk:
            await setInDiskCache(entry)
        case .network:
            // 网络缓存通常不由本地管理
            logger?.log("网络缓存不支持本地设置", level: .warning, category: "cache.optimizer", metadata: nil)
        }
        
        logger?.log("缓存设置完成: \(key) (大小: \(size) 字节, 层级: \(level.description))", level: .debug, category: "cache.optimizer", metadata: nil)
    }
    
    /// 删除缓存
    /// - Parameter key: 缓存键
    public func remove(_ key: String) async {
        // 从内存缓存删除
        memoryCache.removeValue(forKey: key)
        
        // 从磁盘缓存删除
        let diskPath = diskCachePath(for: key)
        try? FileManager.default.removeItem(at: diskPath)
        
        // 从命中记录删除
        hitRecords.removeValue(forKey: key)
        
        logger?.log("缓存删除完成: \(key)", level: .debug, category: "cache.optimizer", metadata: nil)
    }
    
    /// 清空缓存
    /// - Parameter level: 要清空的缓存层级，nil表示清空所有
    public func clear(level: TECacheLevel? = nil) async {
        if let level = level {
            await clearLevel(level)
        } else {
            // 清空所有层级
            for level in TECacheLevel.allCases {
                await clearLevel(level)
            }
        }
        
        logger?.log("缓存清空完成 (层级: \(level?.description ?? "所有"))", level: .info, category: "cache.optimizer", metadata: nil)
    }
    
    // MARK: - 缓存策略管理
    
    /// 更新缓存策略
    /// - Parameter strategy: 新策略
    public func updateStrategy(_ strategy: TECacheStrategy) async {
        self.cacheStrategy = strategy
        
        // 根据新策略调整现有缓存
        await adjustCacheForNewStrategy()
        
        logger?.log("缓存策略更新: \(String(describing: strategy))", level: .info, category: "cache.optimizer", metadata: nil)
    }
    
    /// 获取当前策略
    /// - Returns: 当前缓存策略
    public func getCurrentStrategy() -> TECacheStrategy {
        return cacheStrategy
    }
    
    // MARK: - 性能优化
    
    /// 预热缓存（内部使用，非泛型版本）
    private func preheatGet(_ key: String, level: TECacheLevel = .memory) async {
        let startTime = CFAbsoluteTimeGetCurrent()
        
        await updateStatistics { stats in
            var newStats = stats
            newStats.totalRequests += 1
            return newStats
        }
        
        // 尝试从指定层级开始查找
        let allLevels = TECacheLevel.allCases
        let startIndex = allLevels.firstIndex(of: level) ?? 0
        for i in startIndex..<allLevels.count {
            let cacheLevel = allLevels[i]
            if let _ = await getFromLevel(key, level: cacheLevel) {
                let responseTime = CFAbsoluteTimeGetCurrent() - startTime
                await recordHit(key: key, level: cacheLevel, responseTime: responseTime)
                return
            }
        }
        
        // 未命中
        let responseTime = CFAbsoluteTimeGetCurrent() - startTime
        await recordMiss(key: key, responseTime: responseTime)
    }
    
    /// 预热缓存
    /// - Parameter keys: 要预热的键列表
    public func preheatCache(_ keys: [String]) async {
        logger?.log("开始缓存预热，键数量: \(keys.count)", level: .info, category: "cache.optimizer", metadata: nil)
        
        // 使用 TaskGroup 进行并发预热
        await withTaskGroup(of: Void.self) { group in
            for key in keys {
                group.addTask {
                    _ = await self.get(key, level: .memory) as String?
                }
            }
        }
        
        logger?.log("缓存预热完成", level: .info, category: "cache.optimizer", metadata: nil)
    }
    
    /// 批量获取（优化性能）
    /// - Parameter keys: 键列表
    /// - Returns: 键值对字典
    public func batchGet<T>(_ keys: [String]) async -> [String: T] {
        var results: [String: T] = [:]
        
        for key in keys {
            if let value: T = await get(key) {
                results[key] = value
            }
        }
        
        logger?.log("批量获取完成，请求数: \(keys.count)，命中数: \(results.count)", level: .debug, category: "cache.optimizer", metadata: nil)
        return results
    }
    
    /// 批量设置（优化性能）
    /// - Parameter keyValuePairs: 键值对列表
    public func batchSet<T>(_ keyValuePairs: [(String, T)]) async {
        for (key, value) in keyValuePairs {
            await set(key, value: value)
        }
        
        logger?.log("批量设置完成，数量: \(keyValuePairs.count)", level: .debug, category: "cache.optimizer", metadata: nil)
    }
    
    // MARK: - 统计和监控
    
    /// 获取缓存统计信息
    /// - Returns: 统计信息
    public func getStatistics() async -> TECacheStatistics {
        return statistics
    }
    
    /// 重置统计信息
    public func resetStatistics() async {
        statistics = TECacheStatistics(
            totalRequests: 0,
            cacheHits: 0,
            cacheMisses: 0,
            hitRate: 0.0,
            averageResponseTime: 0.0,
            memoryUsage: 0,
            diskUsage: 0,
            evictionCount: 0,
            errorCount: 0
        )
        
        logger?.log("缓存统计信息已重置", level: .info, category: "cache.optimizer", metadata: nil)
    }
    
    /// 获取缓存命中率趋势
    /// - Parameter timeWindow: 时间窗口（秒）
    /// - Returns: 命中率趋势数据
    public func getHitRateTrend(timeWindow: TimeInterval = 3600) async -> [(Date, Double)] {
        let cutoffDate = Date().addingTimeInterval(-timeWindow)
        
        return hitRecords
            .filter { $0.value > cutoffDate }
            .sorted { $0.value < $1.value }
            .map { ($0.value, 1.0) } // 简化实现，实际应该计算真实的命中率
    }
    
    // MARK: - 私有方法
    
    /// 从指定层级获取缓存
    private func getFromLevel(_ key: String, level: TECacheLevel) async -> Any? {
        switch level {
        case .memory:
            return await getFromMemoryCache(key)
        case .disk:
            return getFromDiskCache(key)
        case .network:
            return getFromNetworkCache(key)
        }
    }
    
    /// 从内存缓存获取
    private func getFromMemoryCache(_ key: String) async -> Any? {
        guard let entry = memoryCache[key] else { return nil }
        
        // 检查是否过期
        if await isEntryExpired(entry) {
            memoryCache.removeValue(forKey: key)
            return nil
        }
        
        entry.recordAccess()
        return entry.value
    }
    
    /// 从磁盘缓存获取
    private func getFromDiskCache(_ key: String) -> Any? {
        let path = diskCachePath(for: key)
        
        guard FileManager.default.fileExists(atPath: path.path) else {
            return nil
        }
        
        do {
            let data = try Data(contentsOf: path)
            let unarchivedData = try NSKeyedUnarchiver.unarchiveTopLevelObjectWithData(data)
            return unarchivedData
        } catch {
            // 记录错误但不阻塞，使用 Task 进行异步日志记录
            Task {
                logger?.log("磁盘缓存读取失败: \(key) - \(error.localizedDescription)", level: .error, category: "cache.optimizer", metadata: nil)
            }
            return nil
        }
    }
    
    /// 从网络缓存获取（简化实现）
    private func getFromNetworkCache(_ key: String) -> Any? {
        // 实际实现中，这里会查询远程缓存服务
        Task {
            logger?.log("网络缓存查询: \(key)", level: .debug, category: "cache.optimizer", metadata: nil)
        }
        return nil
    }
    
    /// 设置内存缓存
    private func setInMemoryCache(_ entry: TECacheEntry) async {
        // 检查内存限制
        let currentMemoryUsage = await calculateMemoryUsage()
        if currentMemoryUsage + entry.size > memoryCacheLimit {
            await evictEntriesToMakeSpace(for: entry.size)
        }
        
        memoryCache[entry.key] = entry
        await updateMemoryUsage()
    }
    
    /// 设置磁盘缓存
    private func setInDiskCache(_ entry: TECacheEntry) async {
        let path = diskCachePath(for: entry.key)
        
        do {
            let data = try NSKeyedArchiver.archivedData(withRootObject: entry.value, requiringSecureCoding: false)
            try data.write(to: path)
            updateDiskUsage()
        } catch {
            logger?.log("磁盘缓存写入失败: \(entry.key) - \(error.localizedDescription)", level: .error, category: "cache.optimizer", metadata: nil)
        }
    }
    
    /// 清空指定层级缓存
    private func clearLevel(_ level: TECacheLevel) async {
        switch level {
        case .memory:
            memoryCache.removeAll()
        case .disk:
            try? FileManager.default.removeItem(at: diskCacheDirectory)
            try? FileManager.default.createDirectory(at: diskCacheDirectory, withIntermediateDirectories: true)
        case .network:
            // 网络缓存清空需要调用远程服务
            break
        }
    }
    
    /// 检查缓存条目是否过期
    private func isEntryExpired(_ entry: TECacheEntry) async -> Bool {
        switch cacheStrategy {
        case .timeBased(let ttl):
            return entry.age > ttl
        case .hybrid(_, let ttl):
            return entry.age > ttl
        default:
            return false
        }
    }
    
    /// 淘汰条目以腾出空间
    private func evictEntriesToMakeSpace(for requiredSize: Int) async {
        var entriesToEvict: [TECacheEntry] = []
        
        let sortedEntries = memoryCache.values.sorted { entry1, entry2 in
            switch cacheStrategy {
            case .lru, .hybrid:
                return entry1.timeSinceLastAccess < entry2.timeSinceLastAccess
            case .lfu:
                return entry1.accessCount < entry2.accessCount
            case .fifo:
                return entry1.creationTime > entry2.creationTime
            case .adaptive:
                // 结合多种因素的自适应策略
                let score1 = calculateAdaptiveScore(for: entry1)
                let score2 = calculateAdaptiveScore(for: entry2)
                return score1 < score2
            case .timeBased:
                return entry1.age < entry2.age
            }
        }
        
        var freedSpace = 0
        for entry in sortedEntries {
            if freedSpace >= requiredSize {
                break
            }
            entriesToEvict.append(entry)
            freedSpace += entry.size
        }
        
        for entry in entriesToEvict {
            memoryCache.removeValue(forKey: entry.key)
        }
        
        await updateStatistics { stats in
            var newStats = stats
            newStats.evictionCount += entriesToEvict.count
            return newStats
        }
        
        logger?.log("淘汰条目: \(entriesToEvict.count)，释放空间: \(entriesToEvict.reduce(0) { $0 + $1.size }) 字节", level: .debug, category: "cache.optimizer", metadata: nil)
    }
    
    /// 计算自适应分数
    private func calculateAdaptiveScore(for entry: TECacheEntry) -> Double {
        let ageWeight = 0.3
        let accessWeight = 0.4
        let frequencyWeight = 0.3
        
        let ageScore = min(entry.age / 3600.0, 1.0) // 归一化到1小时
        let accessScore = min(entry.timeSinceLastAccess / 3600.0, 1.0)
        let frequencyScore = 1.0 / Double(max(entry.accessCount, 1))
        
        return ageWeight * ageScore + accessWeight * accessScore + frequencyWeight * frequencyScore
    }
    
    /// 调整缓存以适应新策略
    private func adjustCacheForNewStrategy() async {
        // 根据新策略重新评估现有缓存条目
        var keysToRemove: [String] = []
        for entry in memoryCache.values {
            if await isEntryExpired(entry) {
                keysToRemove.append(entry.key)
            }
        }
        for key in keysToRemove {
            memoryCache.removeValue(forKey: key)
        }
    }
    
    /// 计算内存使用量
    private func calculateMemoryUsage() async -> Int {
        return memoryCache.values.reduce(0) { $0 + $1.size }
    }
    
    /// 更新内存使用量统计
    private func updateMemoryUsage() async {
        let usage = await calculateMemoryUsage()
        await updateStatistics { stats in
            var newStats = stats
            newStats.memoryUsage = usage
            return newStats
        }
    }
    
    /// 更新磁盘使用量统计
    private func updateDiskUsage() {
        // 计算磁盘使用量的实现
        // 这里简化处理
        statistics.diskUsage = 0
    }
    
    /// 获取磁盘缓存路径
    private func diskCachePath(for key: String) -> URL {
        let safeKey = key.replacingOccurrences(of: "/", with: "_")
        return diskCacheDirectory.appendingPathComponent("\(safeKey).cache")
    }
    
    /// 估算对象大小（简化实现）
    private func estimateSize(of value: Any) -> Int {
        // 实际实现中应该使用更精确的大小估算方法
        return 1024 // 默认1KB
    }
    
    /// 记录缓存命中
    private func recordHit(key: String, level: TECacheLevel, responseTime: TimeInterval) async {
        await updateStatistics { stats in
            var newStats = stats
            newStats.cacheHits += 1
            newStats.hitRate = Double(newStats.cacheHits) / Double(newStats.totalRequests)
            return newStats
        }
        
        hitRecords[key] = Date()
        
        logger?.log("缓存命中: \(key) (层级: \(level.description), 响应时间: \(String(format: "%.3fms", responseTime * 1000)))", level: .debug, category: "cache.optimizer", metadata: nil)
    }
    
    /// 记录缓存未命中
    private func recordMiss(key: String, responseTime: TimeInterval) async {
        await updateStatistics { stats in
            var newStats = stats
            newStats.cacheMisses += 1
            newStats.hitRate = Double(newStats.cacheHits) / Double(newStats.totalRequests)
            
            // 更新平均响应时间
            let totalTime = newStats.averageResponseTime * Double(newStats.totalRequests - 1) + responseTime
            newStats.averageResponseTime = totalTime / Double(newStats.totalRequests)
            
            return newStats
        }
        
        logger?.log("缓存未命中: \(key) (响应时间: \(String(format: "%.3fms", responseTime * 1000)))", level: .debug, category: "cache.optimizer", metadata: nil)
    }
    
    /// 更新统计信息
    private func updateStatistics(_ update: (TECacheStatistics) -> TECacheStatistics) async {
        statistics = update(statistics)
    }
    
    /// 启动后台清理定时器
    private func startCleanupTimer() async {
        cleanupTask = Task {
            while !Task.isCancelled {
                try? await Task.sleep(nanoseconds: 60_000_000_000)
                await performBackgroundCleanup()
            }
        }
    }
    
    /// 执行后台清理
    private func performBackgroundCleanup() async {
        logger?.log("执行后台缓存清理", level: .debug, category: "cache.optimizer", metadata: nil)
        
        // 清理过期条目
        var expiredCount = 0
        for entry in memoryCache.values {
            if await isEntryExpired(entry) {
                memoryCache.removeValue(forKey: entry.key)
                expiredCount += 1
            }
        }
        
        if expiredCount > 0 {
            logger?.log("清理过期条目: \(expiredCount)", level: .debug, category: "cache.optimizer", metadata: nil)
        }
        
        // 更新统计信息
        await updateMemoryUsage()
        await updateDiskUsage()
    }
}

// MARK: - 缓存优化扩展

extension TEAdvancedCacheOptimizer {
    
    /// 智能缓存建议
    public struct CacheRecommendation {
        let key: String
        let shouldCache: Bool
        let recommendedLevel: TECacheLevel
        let estimatedTTL: TimeInterval?
        let reason: String
    }
    
    /// 生成缓存建议
    public func generateCacheRecommendation(for key: String, accessPattern: AccessPattern) async -> CacheRecommendation {
        switch accessPattern {
        case .frequent(let frequency):
            if frequency > 10 {
                return CacheRecommendation(
                    key: key,
                    shouldCache: true,
                    recommendedLevel: .memory,
                    estimatedTTL: 600, // 10分钟
                    reason: "高频访问，建议内存缓存"
                )
            } else {
                return CacheRecommendation(
                    key: key,
                    shouldCache: true,
                    recommendedLevel: .disk,
                    estimatedTTL: 1800, // 30分钟
                    reason: "中等频率访问，建议磁盘缓存"
                )
            }
            
        case .temporal(let duration):
            if duration < 60 {
                return CacheRecommendation(
                    key: key,
                    shouldCache: true,
                    recommendedLevel: .memory,
                    estimatedTTL: duration * 2,
                    reason: "临时数据，短期内存缓存"
                )
            } else {
                return CacheRecommendation(
                    key: key,
                    shouldCache: true,
                    recommendedLevel: .disk,
                    estimatedTTL: duration,
                    reason: "长期数据，磁盘缓存"
                )
            }
            
        case .critical:
            return CacheRecommendation(
                key: key,
                shouldCache: true,
                recommendedLevel: .memory,
                estimatedTTL: nil, // 不过期
                reason: "关键数据，永久内存缓存"
            )
            
        case .ephemeral:
            return CacheRecommendation(
                key: key,
                shouldCache: false,
                recommendedLevel: .memory,
                estimatedTTL: 0,
                reason: "临时数据，不建议缓存"
            )
        }
    }
    
    /// 访问模式
    public enum AccessPattern {
        case frequent(frequency: Int) // 访问频率
        case temporal(duration: TimeInterval) // 临时访问
        case critical // 关键数据
        case ephemeral // 临时数据
    }
    
    /// 缓存预热策略
    public enum PreheatStrategy {
        case sequential // 顺序预热
        case parallel(maxConcurrency: Int) // 并行预热
        case priorityBased(priorities: [String: Int]) // 基于优先级
        case adaptive(threshold: Double) // 自适应
    }
    
    /// 智能缓存预热
    public func intelligentPreheat(keys: [String], strategy: PreheatStrategy = .parallel(maxConcurrency: 4)) async {
        logger?.log("开始智能缓存预热，键数量: \(keys.count)，策略: \(String(describing: strategy))", level: .info, category: "cache.optimizer", metadata: nil)
        
        switch strategy {
        case .sequential:
            for key in keys {
                await preheatGet(key)
            }
            
        case .parallel(let maxConcurrency):
            let chunkedKeys = keys.chunked(into: maxConcurrency)
            
            await withTaskGroup(of: Void.self) { group in
                for chunk in chunkedKeys {
                    group.addTask {
                        for key in chunk {
                            await self.preheatGet(key)
                        }
                    }
                }
            }
            
        case .priorityBased(let priorities):
            let sortedKeys = keys.sorted { key1, key2 in
                let priority1 = priorities[key1] ?? 0
                let priority2 = priorities[key2] ?? 0
                return priority1 > priority2
            }
            
            await intelligentPreheat(keys: sortedKeys, strategy: .parallel(maxConcurrency: 4))
            
        case .adaptive(let threshold):
            // 基于历史访问模式自适应预热
            let highPriorityKeys = keys.filter { key in
                return hitRecords[key] != nil
            }
            
            if Double(highPriorityKeys.count) / Double(keys.count) > threshold {
                await intelligentPreheat(keys: highPriorityKeys, strategy: .parallel(maxConcurrency: 4))
            }
        }
        
        logger?.log("智能缓存预热完成", level: .info, category: "cache.optimizer", metadata: nil)
    }
    
    /// 缓存健康检查
    public func performHealthCheck() async -> Result<Bool, TETextEngineError> {
        let stats = await getStatistics()
        
        // 检查命中率
        if stats.hitRate < 0.5 && stats.totalRequests > 100 {
            return .failure(.cacheError(operation: "health_check", key: "hit_rate"))
        }
        
        // 检查响应时间
        if stats.averageResponseTime > 0.1 { // 100ms
            return .failure(.cacheError(operation: "health_check", key: "response_time"))
        }
        
        // 检查内存使用
        if stats.memoryUsage > memoryCacheLimit * 9 / 10 { // 90%使用率
            return .failure(.cacheError(operation: "health_check", key: "memory_usage"))
        }
        
        return .success(true)
    }
}

// MARK: - 数组扩展

extension Array {
    func chunked(into size: Int) -> [[Element]] {
        return stride(from: 0, to: count, by: size).map {
            Array(self[$0..<Swift.min($0 + size, count)])
        }
    }
}
