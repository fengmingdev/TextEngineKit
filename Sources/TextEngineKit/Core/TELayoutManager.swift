import Foundation
import CoreText
import CoreGraphics

/// 文本布局管理器
/// 负责异步文本布局计算和缓存管理
public final class TELayoutManager {
    
    // MARK: - 属性
    
    /// 布局缓存
    private var layoutCache = NSCache<NSString, TELayoutInfo>()
    private var externalCache: TECacheManagerProtocol?
    
    /// 异步布局队列
    private let layoutQueue: DispatchQueue
    
    /// 最大并发任务数
    private let maxConcurrentTasks: Int
    
    /// 信号量，控制并发数
    private let semaphore: DispatchSemaphore
    
    /// 线程安全锁
    private let lock = NSLock()
    
    /// 布局统计信息
    private var layoutStatistics = TELayoutStatistics()

    private var cancelledTasks = Set<UUID>()
    
    // MARK: - 初始化
    
    public init(maxConcurrentTasks: Int = 3) {
        self.maxConcurrentTasks = maxConcurrentTasks
        self.semaphore = DispatchSemaphore(value: maxConcurrentTasks)
        self.layoutQueue = DispatchQueue(
            label: "com.textenginekit.layout",
            qos: .userInitiated,
            attributes: .concurrent
        )
        
        setupCache()
        Task { [weak self] in
            self?.externalCache = await TEContainer.shared.resolveOptional(TECacheManagerProtocol.self)
        }
        TETextEngine.shared.logDebug("布局管理器初始化完成，最大并发任务数: \(maxConcurrentTasks)", category: "layout")
    }
    
    // MARK: - 公共方法
    
    /// 同步布局计算
    /// - Parameters:
    ///   - attributedString: 属性字符串
    ///   - size: 布局尺寸
    ///   - options: 布局选项
    /// - Returns: 布局信息
    public func layoutSynchronously(
        _ attributedString: NSAttributedString,
        size: CGSize,
        options: TELayoutOptions = []
    ) -> TELayoutInfo {
        let container = TETextContainer(size: size)
        return layoutSynchronously(attributedString, container: container, options: options)
    }
    
    /// 同步布局计算（支持自定义容器）
    /// - Parameters:
    ///   - attributedString: 属性字符串
    ///   - container: 文本容器
    ///   - options: 布局选项
    /// - Returns: 布局信息
    public func layoutSynchronously(
        _ attributedString: NSAttributedString,
        container: TETextContainer,
        options: TELayoutOptions = []
    ) -> TELayoutInfo {
        let startTime = CFAbsoluteTimeGetCurrent()
        let cacheKey = generateCacheKey(attributedString: attributedString, container: container, options: options)
        
        // 检查缓存
        if let ec = externalCache, let cachedLayout: TELayoutInfo = ec.get(cacheKey as String) {
            let duration = (CFAbsoluteTimeGetCurrent() - startTime) * 1000
            TETextEngine.shared.logLayoutPerformance(
                operation: "sync_layout_cache_hit",
                textLength: attributedString.length,
                duration: duration,
                cacheHit: true
            )
            updateStatistics(hit: true, duration: duration)
            return cachedLayout
        }
        if let cachedLayout = layoutCache.object(forKey: cacheKey) {
            let duration = (CFAbsoluteTimeGetCurrent() - startTime) * 1000
            TETextEngine.shared.logLayoutPerformance(
                operation: "sync_layout_cache_hit",
                textLength: attributedString.length,
                duration: duration,
                cacheHit: true
            )
            updateStatistics(hit: true, duration: duration)
            return cachedLayout
        }
        
        // 执行布局计算
        let layoutInfo = performLayout(attributedString: attributedString, container: container, options: options)
        
        // 缓存结果（设置估算成本）
        let cost = attributedString.length * 2 + layoutInfo.lineCount * 256
        if let ec = externalCache {
            ec.set(layoutInfo, forKey: (cacheKey as String))
        } else {
            layoutCache.setObject(layoutInfo, forKey: cacheKey, cost: cost)
        }
        
        let duration = (CFAbsoluteTimeGetCurrent() - startTime) * 1000
        TETextEngine.shared.logLayoutPerformance(
            operation: "sync_layout",
            textLength: attributedString.length,
            duration: duration,
            cacheHit: false
        )
        updateStatistics(hit: false, duration: duration)
        
        return layoutInfo
    }
    
    /// 异步布局计算
    /// - Parameters:
    ///   - attributedString: 属性字符串
    ///   - size: 布局尺寸
    ///   - options: 布局选项
    ///   - completion: 完成回调
    public func layoutAsynchronously(
        _ attributedString: NSAttributedString,
        size: CGSize,
        options: TELayoutOptions = [],
        completion: @escaping (TELayoutInfo) -> Void
    ) {
        let container = TETextContainer(size: size)
        layoutAsynchronously(attributedString, container: container, options: options, completion: completion)
    }
    
    /// 异步布局计算（支持自定义容器）
    /// - Parameters:
    ///   - attributedString: 属性字符串
    ///   - container: 文本容器
    ///   - options: 布局选项
    ///   - completion: 完成回调
    public func layoutAsynchronously(
        _ attributedString: NSAttributedString,
        container: TETextContainer,
        options: TELayoutOptions = [],
        completion: @escaping (TELayoutInfo) -> Void
    ) {
        let startTime = CFAbsoluteTimeGetCurrent()
        let cacheKey = generateCacheKey(attributedString: attributedString, container: container, options: options)
        
        // 检查缓存
        if let ec = externalCache, let cached: TELayoutInfo = ec.get(cacheKey as String) {
            let duration = (CFAbsoluteTimeGetCurrent() - startTime) * 1000
            TETextEngine.shared.logLayoutPerformance(
                operation: "async_layout_cache_hit",
                textLength: attributedString.length,
                duration: duration,
                cacheHit: true
            )
            updateStatistics(hit: true, duration: duration)
            completion(cached)
            return
        }
        if let cachedLayout = layoutCache.object(forKey: cacheKey) {
            let duration = (CFAbsoluteTimeGetCurrent() - startTime) * 1000
            TETextEngine.shared.logLayoutPerformance(
                operation: "async_layout_cache_hit",
                textLength: attributedString.length,
                duration: duration,
                cacheHit: true
            )
            updateStatistics(hit: true, duration: duration)
            completion(cachedLayout)
            return
        }
        
        // 异步执行布局
        layoutQueue.async { [weak self] in
            guard let self = self else { return }
            
            self.semaphore.wait()
            
            let threadStartTime = CFAbsoluteTimeGetCurrent()
            
            // 再次检查缓存（双重检查）
            if let cachedLayout = self.layoutCache.object(forKey: cacheKey) {
                self.semaphore.signal()
                _ = (CFAbsoluteTimeGetCurrent() - threadStartTime) * 1000
                DispatchQueue.main.async {
                    completion(cachedLayout)
                }
                return
            }
            
            // 执行布局计算
            let layoutInfo = self.performLayout(attributedString: attributedString, container: container, options: options)
            
            // 缓存结果（设置估算成本）
            let cost = attributedString.length * 2 + layoutInfo.lineCount * 256
                if let ec = self.externalCache {
                    ec.set(layoutInfo, forKey: (cacheKey as String))
                } else {
                    self.layoutCache.setObject(layoutInfo, forKey: cacheKey, cost: cost)
                }
            
            self.semaphore.signal()
            
            let duration = (CFAbsoluteTimeGetCurrent() - threadStartTime) * 1000
            TETextEngine.shared.logLayoutPerformance(
                operation: "async_layout",
                textLength: attributedString.length,
                duration: duration,
                cacheHit: false
            )
            self.updateStatistics(hit: false, duration: duration)
            
            DispatchQueue.main.async {
                completion(layoutInfo)
            }
        }
    }

    /// 可取消的异步布局计算，返回取消标识
    public func layoutAsynchronouslyCancelable(
        _ attributedString: NSAttributedString,
        size: CGSize,
        options: TELayoutOptions = [],
        completion: @escaping (TELayoutInfo) -> Void
    ) -> UUID {
        let id = UUID()
        let container = TETextContainer(size: size)
        layoutAsynchronously(attributedString, container: container, options: options) { [weak self] info in
            guard let self = self else { return }
            self.lock.lock(); defer { self.lock.unlock() }
            if self.cancelledTasks.contains(id) { return }
            completion(info)
        }
        return id
    }

    /// 取消异步布局
    public func cancelLayout(task id: UUID) {
        lock.lock(); cancelledTasks.insert(id); lock.unlock()
    }
    
    /// 清除布局缓存
    public func clearCache() {
        lock.lock()
        defer { lock.unlock() }
        
        layoutCache.removeAllObjects()
        TETextEngine.shared.logDebug("布局缓存已清除", category: "layout")
    }
    
    /// 获取布局统计信息
    /// - Returns: 统计信息
    public func getStatistics() -> TELayoutStatistics {
        lock.lock()
        defer { lock.unlock() }
        return layoutStatistics
    }
    
    /// 更新缓存大小
    /// - Parameter countLimit: 缓存大小限制
    public func updateCacheSize(countLimit: Int) {
        layoutCache.countLimit = countLimit
        TETextEngine.shared.logDebug("布局缓存大小更新为: \(countLimit)", category: "layout")
    }
    
    // MARK: - 私有方法
    
    /// 设置缓存属性
    private func setupCache() {
        layoutCache.countLimit = 100
        layoutCache.totalCostLimit = 50 * 1024 * 1024 // 50MB
        layoutCache.evictsObjectsWithDiscardedContent = true
    }
    
    /// 生成缓存键
    /// - Parameters:
    ///   - attributedString: 属性字符串
    ///   - size: 布局尺寸
    ///   - options: 布局选项
    /// - Returns: 缓存键
    private func generateCacheKey(
        attributedString: NSAttributedString,
        size: CGSize,
        options: TELayoutOptions
    ) -> NSString {
        let container = TETextContainer(size: size)
        return generateCacheKey(attributedString: attributedString, container: container, options: options)
    }
    
    /// 生成缓存键（支持容器）
    /// - Parameters:
    ///   - attributedString: 属性字符串
    ///   - container: 文本容器
    ///   - options: 布局选项
    /// - Returns: 缓存键
    private func generateCacheKey(
        attributedString: NSAttributedString,
        container: TETextContainer,
        options: TELayoutOptions
    ) -> NSString {
        let stringHash = attributedString.hash
        let sizeHash = container.size.width.hashValue ^ container.size.height.hashValue
        let optionsHash = options.rawValue.hashValue
        
        // 添加路径信息的哈希
        var pathHash = 0
        if let path = container.path {
            pathHash = path.boundingBox.hashValue
        }
        
        // 添加排除路径数量的哈希
        let exclusionHash = container.exclusionPaths.count.hashValue
        
        return "\(stringHash)_\(sizeHash)_\(optionsHash)_\(pathHash)_\(exclusionHash)" as NSString
    }
    
    /// 执行布局计算
    /// - Parameters:
    ///   - attributedString: 属性字符串
    ///   - container: 文本容器
    ///   - options: 布局选项
    /// - Returns: 布局信息
    private func performLayout(
        attributedString: NSAttributedString,
        container: TETextContainer,
        options: TELayoutOptions
    ) -> TELayoutInfo {
        let ctAttributed = TEAttributeConverter.convertAttributedString(attributedString)
        let framesetter = CTFramesetterCreateWithAttributedString(ctAttributed)
        
        // 获取有效的布局路径
        let effectivePath = container.effectivePath()
        
        // 创建框架
        let frame = CTFramesetterCreateFrame(
            framesetter,
            CFRange(location: 0, length: 0),
            effectivePath,
            nil
        )
        
        let cfLines = CTFrameGetLines(frame)
        let lines = (cfLines as NSArray as? [CTLine]) ?? []
        
        var lineOrigins = [CGPoint](repeating: .zero, count: lines.count)
        CTFrameGetLineOrigins(frame, CFRange(location: 0, length: 0), &lineOrigins)
        
        // 处理排除路径
        let filteredLines = filterLinesForExclusionPaths(lines: lines, lineOrigins: &lineOrigins, container: container)
        
        let layoutInfo = TELayoutInfo(
            frame: frame,
            lines: filteredLines,
            lineOrigins: lineOrigins,
            size: CTFrameGetVisibleStringRange(frame),
            usedSize: CTFramesetterSuggestFrameSizeWithConstraints(
                framesetter,
                CFRange(location: 0, length: 0),
                nil,
                container.size,
                nil
            ),
            exclusionPaths: container.exclusionPaths
        )

        return layoutInfo
    }
    
    /// 过滤排除路径影响的行
    /// - Parameters:
    ///   - lines: 原始行数组
    ///   - lineOrigins: 行原点数组
    ///   - container: 文本容器
    /// - Returns: 过滤后的行数组
    private func filterLinesForExclusionPaths(lines: [CTLine], lineOrigins: inout [CGPoint], container: TETextContainer) -> [CTLine] {
        guard !container.exclusionPaths.isEmpty else { return lines }
        
        var filteredLines: [CTLine] = []
        var filteredOrigins: [CGPoint] = []
        
        for index in 0..<lines.count {
            let origin = lineOrigins[index]
            let line = lines[index]
            let lineRect = calculateLineRect(line: line, origin: origin)
            var shouldExclude = false
            for exclusionPath in container.exclusionPaths {
                if exclusionPath.boundingBox.intersects(lineRect) {
                    if lineIntersectsPath(line: line, origin: origin, path: exclusionPath) {
                        shouldExclude = true
                        break
                    }
                }
            }
            
            if !shouldExclude {
                filteredLines.append(line)
                filteredOrigins.append(origin)
            }
        }
        
        lineOrigins = filteredOrigins
        return filteredLines
    }

    private func lineIntersectsPath(line: CTLine, origin: CGPoint, path: CGPath) -> Bool {
        var ascent: CGFloat = 0
        var descent: CGFloat = 0
        var leading: CGFloat = 0
        let width = CGFloat(CTLineGetTypographicBounds(line, &ascent, &descent, &leading))
        let rect = CGRect(x: origin.x, y: origin.y - descent, width: width, height: ascent + descent)
        if !path.boundingBox.intersects(rect) { return false }
        let samples = samplePoints(in: rect, count: 9)
        for p in samples {
            if path.contains(p, using: .winding, transform: .identity) { return true }
        }
        return false
    }

    private func samplePoints(in rect: CGRect, count: Int) -> [CGPoint] {
        var pts: [CGPoint] = []
        pts.append(CGPoint(x: rect.midX, y: rect.midY))
        pts.append(rect.origin)
        pts.append(CGPoint(x: rect.maxX, y: rect.minY))
        pts.append(CGPoint(x: rect.minX, y: rect.maxY))
        pts.append(CGPoint(x: rect.maxX, y: rect.maxY))
        pts.append(CGPoint(x: rect.minX, y: rect.midY))
        pts.append(CGPoint(x: rect.maxX, y: rect.midY))
        pts.append(CGPoint(x: rect.midX, y: rect.minY))
        pts.append(CGPoint(x: rect.midX, y: rect.maxY))
        return pts
    }
    
    /// 计算行的矩形区域
    /// - Parameters:
    ///   - line: 文本行
    ///   - origin: 行原点
    /// - Returns: 行矩形
    private func calculateLineRect(line: CTLine, origin: CGPoint) -> CGRect {
        var ascent: CGFloat = 0
        var descent: CGFloat = 0
        var leading: CGFloat = 0
        let width = CTLineGetTypographicBounds(line, &ascent, &descent, &leading)
        
        return CGRect(
            x: origin.x,
            y: origin.y - descent,
            width: CGFloat(width),
            height: ascent + descent + leading
        )
    }
    
    /// 更新统计信息
    /// - Parameters:
    ///   - hit: 是否命中缓存
    ///   - duration: 耗时
    private func updateStatistics(hit: Bool, duration: TimeInterval) {
        lock.lock()
        defer { lock.unlock() }
        
        if hit {
            layoutStatistics.cacheHits += 1
        } else {
            layoutStatistics.cacheMisses += 1
        }
        
        layoutStatistics.totalLayoutCount += 1
        layoutStatistics.totalLayoutTime += duration
        layoutStatistics.averageLayoutTime = layoutStatistics.totalLayoutTime / Double(layoutStatistics.totalLayoutCount)
        
        if duration > layoutStatistics.maxLayoutTime {
            layoutStatistics.maxLayoutTime = duration
        }
        
        if layoutStatistics.minLayoutTime == 0 || duration < layoutStatistics.minLayoutTime {
            layoutStatistics.minLayoutTime = duration
        }
    }
}

// MARK: - 布局选项

/// 布局选项
public struct TELayoutOptions: OptionSet {
    public let rawValue: Int
    
    public init(rawValue: Int) {
        self.rawValue = rawValue
    }
    
    /// 截断尾部
    public static let truncatesLastVisibleLine = TELayoutOptions(rawValue: 1 << 0)
    
    /// 使用字体下降
    public static let usesFontLeading = TELayoutOptions(rawValue: 1 << 1)
    
    /// 禁用字体切换
    public static let disablesFontFallback = TELayoutOptions(rawValue: 1 << 2)
    
    /// 包含行间距
    public static let includesLineFragmentPadding = TELayoutOptions(rawValue: 1 << 3)
}

// MARK: - 布局信息

/// 布局信息
public final class TELayoutInfo: NSObject {
    /// Core Text 框架
    public let frame: CTFrame
    
    /// 文本行数组
    public let lines: [CTLine]
    
    /// 行原点数组
    public let lineOrigins: [CGPoint]
    
    /// 可见字符串范围
    public let size: CFRange
    
    /// 实际使用尺寸
    public let usedSize: CGSize
    public let exclusionPaths: [CGPath]
    
    /// 初始化方法
    public init(
        frame: CTFrame,
        lines: [CTLine],
        lineOrigins: [CGPoint],
        size: CFRange,
        usedSize: CGSize,
        exclusionPaths: [CGPath] = []
    ) {
        self.frame = frame
        self.lines = lines
        self.lineOrigins = lineOrigins
        self.size = size
        self.usedSize = usedSize
        self.exclusionPaths = exclusionPaths
        super.init()
    }
    
    /// 总行数
    public var lineCount: Int {
        return lines.count
    }
    
    /// 获取指定行的矩形
    /// - Parameter lineIndex: 行索引
    /// - Returns: 行矩形
    public func rectForLine(at lineIndex: Int) -> CGRect {
        guard lineIndex >= 0 && lineIndex < lines.count else { return .zero }
        
        let line = lines[lineIndex]
        let origin = lineOrigins[lineIndex]
        var ascent: CGFloat = 0
        var descent: CGFloat = 0
        var leading: CGFloat = 0
        let width = CTLineGetTypographicBounds(line, &ascent, &descent, &leading)
        
        return CGRect(
            x: origin.x,
            y: origin.y - descent,
            width: CGFloat(width),
            height: ascent + descent + leading
        )
    }
    
    /// 获取整个布局的边界矩形
    public var boundingRect: CGRect {
        guard !lines.isEmpty else { return .zero }
        
        var minX: CGFloat = .greatestFiniteMagnitude
        var minY: CGFloat = .greatestFiniteMagnitude
        var maxX: CGFloat = -.greatestFiniteMagnitude
        var maxY: CGFloat = -.greatestFiniteMagnitude
        
        for (index, line) in lines.enumerated() {
            let rect = rectForLine(at: index)
            minX = min(minX, rect.minX)
            minY = min(minY, rect.minY)
            maxX = max(maxX, rect.maxX)
            maxY = max(maxY, rect.maxY)
        }
        
        return CGRect(x: minX, y: minY, width: maxX - minX, height: maxY - minY)
    }
}

// MARK: - 布局统计信息

/// 布局统计信息
public struct TELayoutStatistics {
    /// 总布局次数
    public var totalLayoutCount: Int = 0
    
    /// 缓存命中次数
    public var cacheHits: Int = 0
    
    /// 缓存未命中次数
    public var cacheMisses: Int = 0
    
    /// 总布局时间（毫秒）
    public var totalLayoutTime: TimeInterval = 0
    
    /// 平均布局时间（毫秒）
    public var averageLayoutTime: TimeInterval = 0
    
    /// 最大布局时间（毫秒）
    public var maxLayoutTime: TimeInterval = 0
    
    /// 最小布局时间（毫秒）
    public var minLayoutTime: TimeInterval = 0
    
    /// 缓存命中率
    public var cacheHitRate: Double {
        let total = cacheHits + cacheMisses
        return total > 0 ? Double(cacheHits) / Double(total) * 100 : 0
    }
    
    /// 描述信息
    public var description: String {
        return """
        布局统计:
        - 总布局次数: \(totalLayoutCount)
        - 缓存命中率: \(String(format: "%.1f", cacheHitRate))%
        - 平均布局时间: \(String(format: "%.3f", averageLayoutTime))ms
        - 最大布局时间: \(String(format: "%.3f", maxLayoutTime))ms
        - 最小布局时间: \(String(format: "%.3f", minLayoutTime))ms
        """
    }
}
