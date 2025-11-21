// 
//  TEVerticalLayout.swift 
//  TextEngineKit 
// 
//  Created by fengming on 2025/11/17. 
// 
//  竖排布局：提供竖排文本的布局支持与相关计算。 
// 
import Foundation
import CoreText
import CoreGraphics
#if canImport(AppKit)
import AppKit
#endif

/// 垂直文本布局管理器
/// 支持 CJK 文本的垂直布局
public final class TEVerticalLayoutManager {
    
    // MARK: - 属性
    
    /// 布局缓存（弱值，避免持有导致内存泄漏）
    private var layoutCache = NSMapTable<NSString, TEVerticalLayoutInfo>(keyOptions: .strongMemory, valueOptions: .weakMemory)
    
    /// 垂直布局队列
    private let layoutQueue: DispatchQueue
    
    /// 线程安全锁
    private let lock = NSLock()
    
    /// 布局统计信息
    private var layoutStatistics = TEVerticalLayoutStatistics()
    
    /// 是否启用异步布局
    private let enableAsyncLayout: Bool
    
    // MARK: - 初始化
    
    public init(enableAsyncLayout: Bool = true) {
        self.enableAsyncLayout = enableAsyncLayout
        self.layoutQueue = DispatchQueue(
            label: "com.textenginekit.vertical.layout",
            qos: .userInitiated,
            attributes: .concurrent
        )
        
        setupCache()
        TETextEngine.shared.logDebug("垂直布局管理器初始化完成，异步布局: \(enableAsyncLayout)", category: "layout")
    }
    
    // MARK: - 公共方法
    
    /// 同步垂直布局计算
    /// - Parameters:
    ///   - attributedString: 属性字符串
    ///   - size: 布局尺寸
    ///   - options: 布局选项
    /// - Returns: 垂直布局信息
    public func layoutSynchronously(
        _ attributedString: NSAttributedString,
        size: CGSize,
        options: TEVerticalLayoutOptions = []
    ) -> TEVerticalLayoutInfo {
        let startTime = CFAbsoluteTimeGetCurrent()
        let cacheKey = generateCacheKey(attributedString: attributedString, size: size, options: options)
        
        // 检查缓存
        lock.lock(); let cachedLayout = layoutCache.object(forKey: cacheKey); lock.unlock()
        if let cachedLayout = cachedLayout {
            let duration = (CFAbsoluteTimeGetCurrent() - startTime) * 1000
            TETextEngine.shared.logLayoutPerformance(
                operation: "sync_vertical_layout_cache_hit",
                textLength: attributedString.length,
                duration: duration,
                cacheHit: true
            )
            updateStatistics(hit: true, duration: duration)
            return cachedLayout
        }
        
        // 执行垂直布局计算
        let layoutInfo = performVerticalLayout(attributedString: attributedString, size: size, options: options)
        
        // 缓存结果
        lock.lock(); layoutCache.setObject(layoutInfo, forKey: cacheKey); lock.unlock()
        
        let duration = (CFAbsoluteTimeGetCurrent() - startTime) * 1000
        TETextEngine.shared.logLayoutPerformance(
            operation: "sync_vertical_layout",
            textLength: attributedString.length,
            duration: duration,
            cacheHit: false
        )
        updateStatistics(hit: false, duration: duration)
        
        return layoutInfo
    }
    
    /// 异步垂直布局计算
    /// - Parameters:
    ///   - attributedString: 属性字符串
    ///   - size: 布局尺寸
    ///   - options: 布局选项
    ///   - completion: 完成回调
    public func layoutAsynchronously(
        _ attributedString: NSAttributedString,
        size: CGSize,
        options: TEVerticalLayoutOptions = [],
        completion: @escaping (TEVerticalLayoutInfo) -> Void
    ) {
        guard enableAsyncLayout else {
            // 如果禁用异步布局，使用同步方式
            let layoutInfo = layoutSynchronously(attributedString, size: size, options: options)
            completion(layoutInfo)
            return
        }
        
        let startTime = CFAbsoluteTimeGetCurrent()
        let cacheKey = generateCacheKey(attributedString: attributedString, size: size, options: options)
        
        // 检查缓存
        lock.lock(); let cachedLayout = layoutCache.object(forKey: cacheKey); lock.unlock()
        if let cachedLayout = cachedLayout {
            let duration = (CFAbsoluteTimeGetCurrent() - startTime) * 1000
            TETextEngine.shared.logLayoutPerformance(
                operation: "async_vertical_layout_cache_hit",
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
            
            let threadStartTime = CFAbsoluteTimeGetCurrent()
            
            // 再次检查缓存（双重检查）
            self.lock.lock(); let cachedLayout = self.layoutCache.object(forKey: cacheKey); self.lock.unlock()
            if let cachedLayout = cachedLayout {
                _ = (CFAbsoluteTimeGetCurrent() - threadStartTime) * 1000
                DispatchQueue.main.async {
                    completion(cachedLayout)
                }
                return
            }
            
            // 执行垂直布局计算
            let layoutInfo = self.performVerticalLayout(attributedString: attributedString, size: size, options: options)
            
            // 缓存结果
            self.lock.lock(); self.layoutCache.setObject(layoutInfo, forKey: cacheKey); self.lock.unlock()
            
            let duration = (CFAbsoluteTimeGetCurrent() - threadStartTime) * 1000
            TETextEngine.shared.logLayoutPerformance(
                operation: "async_vertical_layout",
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
    
    /// 检查文本是否适合垂直布局
    /// - Parameter text: 文本
    /// - Returns: 是否适合垂直布局
    public func isTextSuitableForVerticalLayout(_ text: String) -> Bool {
        // 检查是否主要包含 CJK 字符
        let cjkCharacterSet = CharacterSet(charactersIn:
            "\u{4E00}-\u{9FFF}" +     // CJK Unified Ideographs
            "\u{3040}-\u{309F}" +     // Hiragana
            "\u{30A0}-\u{30FF}" +     // Katakana
            "\u{AC00}-\u{D7AF}" +     // Hangul Syllables
            "\u{1100}-\u{11FF}" +     // Hangul Jamo
            "\u{3000}-\u{303F}"       // CJK Symbols and Punctuation
        )
        
        let cjkCount = text.unicodeScalars.filter { cjkCharacterSet.contains($0) }.count
        let totalCount = text.count
        
        // 如果 CJK 字符占比超过 30%，认为适合垂直布局
        return totalCount > 0 && Double(cjkCount) / Double(totalCount) > 0.3
    }
    
    /// 转换文本为垂直方向
    /// - Parameter text: 输入文本
    /// - Returns: 垂直方向文本
    public func convertToVerticalText(_ text: String) -> String {
        // 简单的垂直文本转换
        // 实际应用中可能需要更复杂的转换逻辑
        return text.map { String($0) }.joined(separator: "\n")
    }
    
    /// 清除布局缓存
    public func clearCache() {
        lock.lock()
        defer { lock.unlock() }
        
        layoutCache.removeAllObjects()
        TETextEngine.shared.logDebug("垂直布局缓存已清除", category: "layout")
    }
    
    /// 获取布局统计信息
    /// - Returns: 统计信息
    public func getStatistics() -> TEVerticalLayoutStatistics {
        lock.lock()
        defer { lock.unlock() }
        return layoutStatistics
    }
    
    // MARK: - 私有方法
    
    /// 设置缓存属性
    private func setupCache() {}
    
    /// 生成缓存键
    /// - Parameters:
    ///   - attributedString: 属性字符串
    ///   - size: 布局尺寸
    ///   - options: 布局选项
    /// - Returns: 缓存键
    private func generateCacheKey(
        attributedString: NSAttributedString,
        size: CGSize,
        options: TEVerticalLayoutOptions
    ) -> NSString {
        let stringHash = attributedString.hash
        let sizeHash = size.width.hashValue ^ size.height.hashValue
        let optionsHash = options.rawValue.hashValue
        
        return "vertical_\(stringHash)_\(sizeHash)_\(optionsHash)" as NSString
    }
    
    /// 执行垂直布局计算
    /// - Parameters:
    ///   - attributedString: 属性字符串
    ///   - size: 布局尺寸
    ///   - options: 布局选项
    /// - Returns: 垂直布局信息
    private func performVerticalLayout(
        attributedString: NSAttributedString,
        size: CGSize,
        options: TEVerticalLayoutOptions
    ) -> TEVerticalLayoutInfo {
        let verticalAttributedString = createVerticalAttributedString(from: attributedString, options: options)
        let framesetter = CTFramesetterCreateWithAttributedString(verticalAttributedString)
        let path = createVerticalPath(size: size, options: options)
        let frame = CTFramesetterCreateFrame(framesetter, CFRange(location: 0, length: 0), path, nil)
        let cfLines = CTFrameGetLines(frame)
        let lines = (cfLines as NSArray as? [CTLine]) ?? []
        var lineOrigins = [CGPoint](repeating: .zero, count: lines.count)
        CTFrameGetLineOrigins(frame, CFRange(location: 0, length: 0), &lineOrigins)
        let adjustedOrigins = adjustLineOriginsForVerticalLayout(lines: lines, size: size, options: options)
        let usedSize = CTFramesetterSuggestFrameSizeWithConstraints(
            framesetter,
            CFRange(location: 0, length: 0),
            nil,
            size,
            nil
        )
        return TEVerticalLayoutInfo(
            frame: frame,
            lines: lines,
            lineOrigins: adjustedOrigins,
            size: CTFrameGetVisibleStringRange(frame),
            usedSize: usedSize,
            isVertical: true,
            writingDirection: options.contains(.rightToLeft) ? .rightToLeft : .leftToRight,
            containerSize: size
        )
    }
    
    /// 创建垂直属性字符串
    /// - Parameter attributedString: 水平属性字符串
    /// - Returns: 垂直属性字符串
    private func createVerticalAttributedString(from attributedString: NSAttributedString, options: TEVerticalLayoutOptions) -> NSAttributedString {
        let result = NSMutableAttributedString(attributedString: attributedString)
        result.addAttribute(kCTVerticalFormsAttributeName as NSAttributedString.Key, value: true, range: NSRange(location: 0, length: result.length))
        result.addAttribute(kCTWritingDirectionAttributeName as NSAttributedString.Key, value: [1], range: NSRange(location: 0, length: result.length))
        if options.contains(.rotateCharacters) {
            let text = result.string
            let pattern = options.contains(.preservePunctuation) ? "[A-Za-z0-9]+" : "[A-Za-z0-9\\p{P}]+"
            if let regex = try? NSRegularExpression(pattern: pattern, options: []) {
                let range = NSRange(location: 0, length: (text as NSString).length)
                let matches = regex.matches(in: text, options: [], range: range)
                for m in matches { result.addAttribute(TEAttributeKey.glyphTransform, value: CGAffineTransform(rotationAngle: .pi/2), range: m.range) }
            }
        }
        return result
    }
    
    /// 创建垂直路径
    /// - Parameters:
    ///   - size: 布局尺寸
    ///   - options: 布局选项
    /// - Returns: 垂直路径
    private func createVerticalPath(size: CGSize, options: TEVerticalLayoutOptions) -> CGPath {
        let path = CGMutablePath()
        path.addRect(CGRect(x: 0, y: 0, width: size.width, height: size.height))
        return path
    }
    
    /// 调整行原点以适应垂直布局
    /// - Parameters:
    ///   - origins: 原始行原点
    ///   - size: 布局尺寸
    ///   - options: 布局选项
    /// - Returns: 调整后的行原点
    private func adjustLineOriginsForVerticalLayout(lines: [CTLine], size: CGSize, options: TEVerticalLayoutOptions) -> [CGPoint] {
        guard !lines.isEmpty else { return [] }
        var result: [CGPoint] = []
        var x: CGFloat = options.contains(.rightToLeft) ? size.width : 0
        var y: CGFloat = size.height
        var colMaxWidth: CGFloat = 0
        for line in lines {
            var ascent: CGFloat = 0
            var descent: CGFloat = 0
            var leading: CGFloat = 0
            let width = CGFloat(CTLineGetTypographicBounds(line, &ascent, &descent, &leading))
            let height = ascent + descent + leading
            if y - height < 0 {
                if options.contains(.rightToLeft) { x -= (colMaxWidth + 4) } else { x += (colMaxWidth + 4) }
                y = size.height
                colMaxWidth = 0
            }
            result.append(CGPoint(x: x, y: y - descent))
            y -= (height + 8)
            colMaxWidth = max(colMaxWidth, width)
        }
        return result
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

// MARK: - 垂直布局选项

/// 垂直布局选项
public struct TEVerticalLayoutOptions: OptionSet {
    public let rawValue: Int
    
    public init(rawValue: Int) {
        self.rawValue = rawValue
    }
    
    /// 从右到左布局
    public static let rightToLeft = TEVerticalLayoutOptions(rawValue: 1 << 0)
    
    /// 旋转字符
    public static let rotateCharacters = TEVerticalLayoutOptions(rawValue: 1 << 1)
    
    /// 保持标点符号方向
    public static let preservePunctuation = TEVerticalLayoutOptions(rawValue: 1 << 2)
    
    /// 紧凑布局
    public static let compactLayout = TEVerticalLayoutOptions(rawValue: 1 << 3)
}

// MARK: - 垂直布局信息

/// 垂直布局信息
    public final class TEVerticalLayoutInfo: NSObject {
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
    
    /// 是否为垂直布局
    public let isVertical: Bool
    
    /// 书写方向
    public let writingDirection: TEWritingDirection

    public let containerSize: CGSize
    
    /// 初始化方法
    public init(
        frame: CTFrame,
        lines: [CTLine],
        lineOrigins: [CGPoint],
        size: CFRange,
        usedSize: CGSize,
        isVertical: Bool,
        writingDirection: TEWritingDirection,
        containerSize: CGSize
    ) {
        self.frame = frame
        self.lines = lines
        self.lineOrigins = lineOrigins
        self.size = size
        self.usedSize = usedSize
        self.isVertical = isVertical
        self.writingDirection = writingDirection
        self.containerSize = containerSize
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
        let clampedWidth = min(CGFloat(width), containerSize.width)
        let clampedX = max(0, min(origin.x, containerSize.width - clampedWidth))
        return CGRect(
            x: clampedX,
            y: origin.y - descent,
            width: clampedWidth,
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
        
        for (index, _) in lines.enumerated() {
            let rect = rectForLine(at: index)
            minX = min(minX, rect.minX)
            minY = min(minY, rect.minY)
            maxX = max(maxX, rect.maxX)
            maxY = max(maxY, rect.maxY)
        }
        let widthRaw = max(0, maxX - minX)
        let width = min(containerSize.width, widthRaw)
        return CGRect(x: 0, y: minY, width: width, height: maxY - minY)
    }
}

// MARK: - 垂直布局统计信息

/// 垂直布局统计信息
public struct TEVerticalLayoutStatistics {
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
        垂直布局统计:
        - 总布局次数: \(totalLayoutCount)
        - 缓存命中率: \(String(format: "%.1f", cacheHitRate))%
        - 平均布局时间: \(String(format: "%.3f", averageLayoutTime))ms
        - 最大布局时间: \(String(format: "%.3f", maxLayoutTime))ms
        - 最小布局时间: \(String(format: "%.3f", minLayoutTime))ms
        """
    }
}

// MARK: - 书写方向

/// 书写方向
public enum TEWritingDirection {
    case leftToRight
    case rightToLeft
    case topToBottom
    case bottomToTop
}

// MARK: - 垂直文本视图

/// 垂直文本视图
/// 支持 CJK 文本的垂直显示
public final class TEVerticalTextView: TEView {
    
    // MARK: - 属性
    
    /// 垂直布局管理器
    private let layoutManager = TEVerticalLayoutManager()
    
    /// 垂直文本渲染器
    private let renderer = TEVerticalTextRenderer()
    
    /// 文本容器
    private let textContainer = TEView()
    
    /// 属性文本
    private var _attributedText: NSAttributedString?
    
    private let highlightManager = TEHighlightManager()
    public weak var highlightDelegate: TEHighlightManagerDelegate? {
        didSet { highlightManager.delegate = highlightDelegate }
    }
    public var isHighlightEnabled: Bool {
        get { highlightManager.isHighlightEnabled }
        set { highlightManager.isHighlightEnabled = newValue }
    }

    /// 布局信息
    private var layoutInfo: TEVerticalLayoutInfo?
    
    /// 布局选项
    public var layoutOptions: TEVerticalLayoutOptions = []
    
    /// 渲染选项
    public var renderOptions: TVerticalRenderOptions = []
    
    /// 是否启用异步布局
    public var enableAsyncLayout: Bool = true
    
    /// 是否启用异步渲染
    public var enableAsyncRendering: Bool = true
    
    /// 文本对齐方式
    public var textAlignment: TEVerticalTextAlignment = .center
    
    /// 行间距
    public var lineSpacing: CGFloat = 8.0
    
    /// 字符间距
    public var characterSpacing: CGFloat = 4.0
    
    // MARK: - 初始化
    
    public override init(frame: CGRect) {
        super.init(frame: frame)
        setupView()
    }
    
    public required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupView()
    }
    
    private func setupView() {
        // 设置背景色
        #if canImport(UIKit)
        backgroundColor = .systemBackground
        #elseif canImport(AppKit)
        self.layer?.backgroundColor = TEColor.systemBackground.cgColor
        #endif
        
        // 添加文本容器
        #if canImport(UIKit)
        addSubview(textContainer)
        #elseif canImport(AppKit)
        self.addSubview(textContainer)
        #endif
        
        // 设置文本容器约束
        textContainer.translatesAutoresizingMaskIntoConstraints = false
        TENSLayoutConstraint.activate([
            textContainer.topAnchor.constraint(equalTo: topAnchor),
            textContainer.leadingAnchor.constraint(equalTo: leadingAnchor),
            textContainer.trailingAnchor.constraint(equalTo: trailingAnchor),
            textContainer.bottomAnchor.constraint(equalTo: bottomAnchor)
        ])
        
        TETextEngine.shared.logDebug("垂直文本视图初始化完成", category: "ui")

        // 设置高亮管理器
        highlightManager.setupContainerView(self)
        // 将高亮激活与进度提供给渲染器
        renderer.highlightStateProvider = { [weak self] range in
            guard let self = self else { return false }
            return self.highlightManager.isRangeActive(range)
        }
        renderer.highlightProgressProvider = { [weak self] range in
            guard let self = self else { return 0 }
            return self.highlightManager.highlightProgress(for: range)
        }
        setupGestureRecognizers()
    }
    
    // MARK: - 公共属性
    
    /// 属性文本
    public var attributedText: NSAttributedString? {
        get { return _attributedText }
        set {
            _attributedText = newValue
            performLayout()
        }
    }
    
    /// 纯文本
    public var text: String? {
        get { return _attributedText?.string }
        set {
            if let text = newValue {
                attributedText = NSAttributedString(string: text)
            } else {
                attributedText = nil
            }
        }
    }
    
    // MARK: - 重写方法
    
    #if canImport(UIKit)
    public override func layoutSubviews() {
        super.layoutSubviews()
        
        if enableAsyncLayout {
            performAsyncLayout()
        } else {
            performSyncLayout()
        }
    }
    #elseif canImport(AppKit)
    public override func layout() {
        super.layout()
        
        if enableAsyncLayout {
            performAsyncLayout()
        } else {
            performSyncLayout()
        }
    }
    #endif
    
    public override func draw(_ rect: CGRect) {
        super.draw(rect)
        
        if enableAsyncRendering {
            performAsyncRendering(in: rect)
        } else {
            performSyncRendering(in: rect)
        }
    }
    
    // MARK: - 公共方法
    
    /// 检查当前文本是否适合垂直布局
    /// - Returns: 是否适合垂直布局
    public func isCurrentTextSuitableForVerticalLayout() -> Bool {
        guard let text = text else { return false }
        return layoutManager.isTextSuitableForVerticalLayout(text)
    }
    
    /// 转换当前文本为垂直方向
    public func convertCurrentTextToVertical() {
        guard let text = text else { return }
        let verticalText = layoutManager.convertToVerticalText(text)
        self.text = verticalText
    }
    
    /// 获取布局统计信息
    /// - Returns: 统计信息
    public func getLayoutStatistics() -> TEVerticalLayoutStatistics {
        return layoutManager.getStatistics()
    }
    
    /// 获取渲染统计信息
    /// - Returns: 统计信息
    public func getRenderStatistics() -> TEVerticalRenderStatistics {
        return renderer.getStatistics()
    }
    
    // MARK: - 私有方法
    
    /// 执行布局
    private func performLayout() {
        guard attributedText != nil else {
            layoutInfo = nil
            return
        }
        
        if enableAsyncLayout {
            performAsyncLayout()
        } else {
            performSyncLayout()
        }
    }
    
    /// 执行同步布局
    private func performSyncLayout() {
        guard let attributedText = attributedText else { return }
        
        let layoutInfo = layoutManager.layoutSynchronously(attributedText, size: bounds.size, options: layoutOptions)
        self.layoutInfo = layoutInfo
        
        // 更新文本容器
        updateTextContainer(with: layoutInfo)
        
        #if canImport(UIKit)
        setNeedsDisplay()
        #elseif canImport(AppKit)
        setNeedsDisplay(bounds)
        #endif
        
        TETextEngine.shared.logDebug("执行同步垂直布局: size=\(bounds.size), lines=\(layoutInfo.lineCount)", category: "ui")
    }
    
    /// 执行异步布局
    private func performAsyncLayout() {
        guard let attributedText = attributedText else { return }
        
        layoutManager.layoutAsynchronously(attributedText, size: bounds.size, options: layoutOptions) { [weak self] layoutInfo in
            guard let self = self else { return }
            
            DispatchQueue.main.async {
                self.layoutInfo = layoutInfo
                self.updateTextContainer(with: layoutInfo)
                #if canImport(UIKit)
                self.setNeedsDisplay()
                #elseif canImport(AppKit)
                self.setNeedsDisplay(self.bounds)
                #endif
                
                TETextEngine.shared.logDebug("执行异步垂直布局完成: size=\(self.bounds.size), lines=\(layoutInfo.lineCount)", category: "ui")
            }
        }
    }
    
    /// 执行同步渲染
    /// - Parameter rect: 渲染矩形
    private func performSyncRendering(in rect: CGRect) {
        guard let layoutInfo = layoutInfo else { return }
        
        guard let context = TEGetCurrentGraphicsContext() else { return }
        
        renderer.renderSynchronously(layoutInfo, in: context, rect: rect, options: renderOptions)
        
        TETextEngine.shared.logDebug("执行同步垂直渲染: size=\(rect.size)", category: "ui")
    }
    
    /// 执行异步渲染
    /// - Parameter rect: 渲染矩形
    private func performAsyncRendering(in rect: CGRect) {
        guard let layoutInfo = layoutInfo else { return }
        
        renderer.renderAsynchronously(layoutInfo, size: rect.size, options: renderOptions) { [weak self] image in
            guard self != nil else { return }
            
            DispatchQueue.main.async {
                if image != nil {
                    TETextEngine.shared.logDebug("执行异步垂直渲染完成: size=\(rect.size)", category: "ui")
                }
            }
        }
    }
    
    /// 更新文本容器
    /// - Parameter layoutInfo: 布局信息
    private func updateTextContainer(with layoutInfo: TEVerticalLayoutInfo) {
        // 这里可以根据布局信息更新文本容器的内容
        // 简化实现，实际应该根据具体的垂直布局需求来实现
        
        let boundingRect = layoutInfo.boundingRect
        textContainer.frame = boundingRect
    }
    private func setupGestureRecognizers() {
        #if canImport(UIKit)
        let tap = UITapGestureRecognizer(target: self, action: #selector(handleTap(_:)))
        addGestureRecognizer(tap)
        let longPress = UILongPressGestureRecognizer(target: self, action: #selector(handleLongPress(_:)))
        longPress.minimumPressDuration = 0.5
        addGestureRecognizer(longPress)
        #elseif canImport(AppKit)
        let click = NSClickGestureRecognizer(target: self, action: #selector(handleClick(_:)))
        self.addGestureRecognizer(click)
        let press = NSPressGestureRecognizer(target: self, action: #selector(handlePress(_:)))
        self.addGestureRecognizer(press)
        #endif
    }

    #if canImport(UIKit)
    @objc private func handleTap(_ gesture: UITapGestureRecognizer) {
        let point = gesture.location(in: self)
        if let text = attributedText, let info = layoutInfo {
            _ = highlightManager.handleTapVertical(at: point, in: text, textRect: bounds, layoutInfo: info)
        }
    }
    @objc private func handleLongPress(_ gesture: UILongPressGestureRecognizer) {
        guard gesture.state == .began else { return }
        let point = gesture.location(in: self)
        if let text = attributedText, let info = layoutInfo {
            _ = highlightManager.handleLongPressVertical(at: point, in: text, textRect: bounds, layoutInfo: info)
        }
    }
    #elseif canImport(AppKit)
    @objc private func handleClick(_ gesture: NSClickGestureRecognizer) {
        let point = gesture.location(in: self)
        if let text = attributedText, let info = layoutInfo {
            _ = highlightManager.handleTapVertical(at: point, in: text, textRect: bounds, layoutInfo: info)
        }
    }
    @objc private func handlePress(_ gesture: NSPressGestureRecognizer) {
        guard gesture.state == .began else { return }
        let point = gesture.location(in: self)
        if let text = attributedText, let info = layoutInfo {
            _ = highlightManager.handleLongPressVertical(at: point, in: text, textRect: bounds, layoutInfo: info)
        }
    }
    #endif

    
}
// MARK: - 垂直文本对齐方式

/// 垂直文本对齐方式
public enum TEVerticalTextAlignment {
    case top       // 顶部对齐
    case center    // 居中对齐
    case bottom    // 底部对齐
    case justified // 两端对齐
}

// MARK: - 垂直渲染选项

/// 垂直渲染选项
public struct TVerticalRenderOptions: OptionSet {
    public let rawValue: Int
    
    public init(rawValue: Int) {
        self.rawValue = rawValue
    }
    
    /// 抗锯齿
    public static let antialiased = TVerticalRenderOptions(rawValue: 1 << 0)
    
    /// 旋转字符
    public static let rotateCharacters = TVerticalRenderOptions(rawValue: 1 << 1)
    
    /// 保持标点符号方向
    public static let preservePunctuation = TVerticalRenderOptions(rawValue: 1 << 2)
    
    /// 高质量渲染
    public static let highQuality: TVerticalRenderOptions = [.antialiased]
    
    /// 默认渲染选项
    public static let `default`: TVerticalRenderOptions = [.antialiased]
}

// MARK: - 垂直文本渲染器

/// 垂直文本渲染器
public final class TEVerticalTextRenderer: TERendererProtocol {
    
    // MARK: - 属性
    
    /// 渲染队列
    private let renderQueue: DispatchQueue
    
    /// 渲染统计信息
    private var renderStatistics = TEVerticalRenderStatistics()
    
    /// 线程安全锁
    private let lock = NSLock()
    
    /// 是否启用异步渲染
    private let enableAsyncRendering: Bool
    
    /// 高亮状态提供者
    public var highlightStateProvider: ((NSRange) -> Bool)?
    /// 高亮进度提供者（0..1）
    public var highlightProgressProvider: ((NSRange) -> CGFloat)?
    /// 装饰混合模式
    public var decorationBlendMode: CGBlendMode = .normal

    
    
    // MARK: - 初始化
    
    public init(enableAsyncRendering: Bool = true) {
        self.enableAsyncRendering = enableAsyncRendering
        self.renderQueue = DispatchQueue(
            label: "com.textenginekit.vertical.render",
            qos: .userInitiated,
            attributes: .concurrent
        )
        
        TETextEngine.shared.logDebug("垂直文本渲染器初始化完成，异步渲染: \(enableAsyncRendering)", category: "rendering")
    }
    
    // MARK: - TERendererProtocol 适配
    public func renderSynchronously(_ text: NSAttributedString, in context: CGContext, rect: CGRect, options: TERenderOptions) {
        let lm = TEVerticalLayoutManager()
        let vOptions: TVerticalRenderOptions = options.contains(.antialiased) ? .antialiased : []
        let layout = lm.layoutSynchronously(text, size: rect.size, options: [])
        renderSynchronously(layout, in: context, rect: rect, options: vOptions)
    }
    
    
    // MARK: - 公共方法
    
    /// 同步渲染垂直文本
    /// - Parameters:
    ///   - layoutInfo: 布局信息
    ///   - context: 图形上下文
    ///   - rect: 渲染矩形
    ///   - options: 渲染选项
    public func renderSynchronously(
        _ layoutInfo: TEVerticalLayoutInfo,
        in context: CGContext,
        rect: CGRect,
        options: TVerticalRenderOptions = []
    ) {
        let startTime = CFAbsoluteTimeGetCurrent()
        
        // 应用渲染选项
        applyRenderOptions(options, to: context)
        
        // 渲染垂直文本框架
        renderVerticalLayoutInfo(layoutInfo, in: context, rect: rect)
        
        let duration = (CFAbsoluteTimeGetCurrent() - startTime) * 1000
        updateStatistics(frameCount: 1, totalDuration: duration, averageFrameTime: duration)
        
        TETextEngine.shared.logRenderingPerformance(
            frameCount: 1,
            totalDuration: duration,
            averageFrameTime: duration
        )
    }
    
    /// 异步渲染垂直文本
    /// - Parameters:
    ///   - layoutInfo: 布局信息
    ///   - size: 渲染尺寸
    ///   - options: 渲染选项
    ///   - completion: 完成回调，返回渲染后的图像
    public func renderAsynchronously(
        _ layoutInfo: TEVerticalLayoutInfo,
        size: CGSize,
        options: TVerticalRenderOptions = [],
        completion: @escaping (TEImage?) -> Void
    ) {
        guard enableAsyncRendering else {
            // 如果禁用异步渲染，使用同步方式
            let image = renderToImage(layoutInfo, size: size, options: options)
            completion(image)
            return
        }
        
        renderQueue.async { [weak self] in
            guard let self = self else {
                completion(nil)
                return
            }
            
            let startTime = CFAbsoluteTimeGetCurrent()
            
            // 创建图像上下文
            let format = TEPlatform.makeRendererFormat(scale: TEPlatform.screenScale, opaque: true, extendedRange: true)
            let renderer = TEPlatform.createGraphicsRenderer(size: size, format: format)
            let image = renderer.render { context in
                self.renderSynchronously(layoutInfo, in: context, rect: CGRect(origin: .zero, size: size), options: options)
            }
            
            let duration = (CFAbsoluteTimeGetCurrent() - startTime) * 1000
            self.updateStatistics(frameCount: 1, totalDuration: duration, averageFrameTime: duration)
            
            TETextEngine.shared.logRenderingPerformance(
                frameCount: 1,
                totalDuration: duration,
                averageFrameTime: duration
            )
            
            DispatchQueue.main.async {
                completion(image)
            }
        }
    }
    
    /// 渲染到图像
    /// - Parameters:
    ///   - layoutInfo: 布局信息
    ///   - size: 图像尺寸
    ///   - options: 渲染选项
    /// - Returns: 渲染后的图像
    public func renderToImage(
        _ layoutInfo: TEVerticalLayoutInfo,
        size: CGSize,
        options: TVerticalRenderOptions = []
    ) -> TEImage? {
        let format = TEPlatform.makeRendererFormat(scale: TEPlatform.screenScale, opaque: true, extendedRange: true)
        let renderer = TEPlatform.createGraphicsRenderer(size: size, format: format)
        
        return renderer.render { context in
            self.renderSynchronously(layoutInfo, in: context, rect: CGRect(origin: .zero, size: size), options: options)
        }
    }
    
    /// 获取渲染统计信息
    /// - Returns: 统计信息
    public func getStatistics() -> TEVerticalRenderStatistics {
        lock.lock()
        defer { lock.unlock() }
        return renderStatistics
    }
    
    // MARK: - 私有方法
    
    /// 应用渲染选项
    /// - Parameters:
    ///   - options: 渲染选项
    ///   - context: 图形上下文
    private func applyRenderOptions(_ options: TVerticalRenderOptions, to context: CGContext) {
        if options.contains(.antialiased) {
            context.setShouldAntialias(true)
        }
        
        if options.contains(.rotateCharacters) {
            // 设置字符旋转
            context.rotate(by: -.pi / 2) // 旋转 -90 度
        }
        
        if options.contains(.preservePunctuation) {
            // 保持标点符号方向
            // 这里可以添加特殊的标点符号处理逻辑
        }
    }
    
    /// 渲染垂直布局信息
    /// - Parameters:
    ///   - layoutInfo: 布局信息
    ///   - context: 图形上下文
    ///   - rect: 渲染矩形
    private func renderVerticalLayoutInfo(_ layoutInfo: TEVerticalLayoutInfo, in context: CGContext, rect: CGRect) {
        guard !layoutInfo.lines.isEmpty else { return }
        
        // 设置文本绘制模式
        context.textMatrix = .identity
        
        // 根据书写方向调整坐标系
        if layoutInfo.writingDirection == .rightToLeft {
            context.translateBy(x: rect.width, y: 0)
            context.scaleBy(x: -1.0, y: 1.0)
        }
        
        
        for (index, line) in layoutInfo.lines.enumerated() {
            let origin = layoutInfo.lineOrigins[index]
            let adjustedOrigin = CGPoint(x: origin.x + rect.origin.x, y: origin.y + rect.origin.y)
            let cfRuns = CTLineGetGlyphRuns(line)
            let runs = (cfRuns as NSArray as? [CTRun]) ?? []
            for run in runs {
                var ascent: CGFloat = 0
                var descent: CGFloat = 0
                var leading: CGFloat = 0
                let width = CGFloat(CTRunGetTypographicBounds(run, CFRange(location: 0, length: 0), &ascent, &descent, &leading))
                let runRange = CTRunGetStringRange(run)
                let offset = CTLineGetOffsetForStringIndex(line, runRange.location, nil)
                let runRect = CGRect(x: adjustedOrigin.x + CGFloat(offset), y: adjustedOrigin.y - descent, width: width, height: ascent + descent)
                let attrs = CTRunGetAttributes(run) as NSDictionary
                if let border = attrs[TEAttributeKey.textBorder] as? TETextBorder {
                    border.draw(in: context, rect: runRect, lineOrigin: adjustedOrigin, lineAscent: ascent, lineDescent: descent, lineHeight: ascent + descent)
                }
                if let bgBorder = attrs[TEAttributeKey.textBackgroundBorder] as? TETextBorder {
                    bgBorder.draw(in: context, rect: runRect, lineOrigin: adjustedOrigin, lineAscent: ascent, lineDescent: descent, lineHeight: ascent + descent)
                }
                if let highlight = attrs[TEAttributeKey.textHighlight] as? TETextHighlight {
                    let range = NSRange(location: runRange.location, length: runRange.length)
                    let isActive = highlightStateProvider?(range) ?? true
                    if isActive {
                        context.saveGState()
                        context.setBlendMode(decorationBlendMode)
                        let progress = highlightProgressProvider?(range) ?? 1
                        context.setAlpha(progress)
                        highlight.draw(in: context, rect: runRect, isHighlighted: true)
                        context.restoreGState()
                    }
                }
                var hasTransform = false
                var transform = CGAffineTransform.identity
                if let t = attrs[TEAttributeKey.glyphTransform] as? CGAffineTransform {
                    transform = t
                    hasTransform = true
                }
                context.saveGState()
                context.translateBy(x: adjustedOrigin.x + CGFloat(offset), y: adjustedOrigin.y)
                if hasTransform { context.concatenate(transform) }
                context.textPosition = .zero
                CTRunDraw(run, context, CFRange(location: 0, length: 0))
                context.restoreGState()
            }
        }
    }
    
    /// 更新统计信息
    /// - Parameters:
    ///   - frameCount: 帧数
    ///   - totalDuration: 总耗时
    ///   - averageFrameTime: 平均每帧时间
    private func updateStatistics(frameCount: Int, totalDuration: TimeInterval, averageFrameTime: TimeInterval) {
        lock.lock()
        defer { lock.unlock() }
        
        renderStatistics.totalFrameCount += frameCount
        renderStatistics.totalRenderTime += totalDuration
        renderStatistics.averageFrameTime = renderStatistics.totalRenderTime / Double(renderStatistics.totalFrameCount)
        
        if totalDuration > renderStatistics.maxFrameTime {
            renderStatistics.maxFrameTime = totalDuration
        }
        
        if renderStatistics.minFrameTime == 0 || totalDuration < renderStatistics.minFrameTime {
            renderStatistics.minFrameTime = totalDuration
        }
        
        // 计算 FPS
        if totalDuration > 0 {
            let fps = Double(frameCount) / (totalDuration / 1000.0)
            renderStatistics.averageFPS = fps
            
            if fps > renderStatistics.maxFPS {
                renderStatistics.maxFPS = fps
            }
            
            if renderStatistics.minFPS == 0 || fps < renderStatistics.minFPS {
                renderStatistics.minFPS = fps
            }
        }
    }
}

// MARK: - 垂直渲染统计信息

/// 垂直渲染统计信息
public struct TEVerticalRenderStatistics {
    /// 总帧数
    public var totalFrameCount: Int = 0
    
    /// 总渲染时间（毫秒）
    public var totalRenderTime: TimeInterval = 0
    
    /// 平均每帧时间（毫秒）
    public var averageFrameTime: TimeInterval = 0
    
    /// 最大帧时间（毫秒）
    public var maxFrameTime: TimeInterval = 0
    
    /// 最小帧时间（毫秒）
    public var minFrameTime: TimeInterval = 0
    
    /// 平均 FPS
    public var averageFPS: Double = 0
    
    /// 最大 FPS
    public var maxFPS: Double = 0
    
    /// 最小 FPS
    public var minFPS: Double = 0
    
    /// 描述信息
    public var description: String {
        return """
        垂直渲染统计:
        - 总帧数: \(totalFrameCount)
        - 平均帧时间: \(String(format: "%.3f", averageFrameTime))ms
        - 最大帧时间: \(String(format: "%.3f", maxFrameTime))ms
        - 最小帧时间: \(String(format: "%.3f", minFrameTime))ms
        - 平均 FPS: \(String(format: "%.1f", averageFPS))
        - 最大 FPS: \(String(format: "%.1f", maxFPS))
        - 最小 FPS: \(String(format: "%.1f", minFPS))
        """
    }
}
    
