import Foundation
import CoreGraphics

#if canImport(AppKit)
import AppKit
#endif

/// 文本高亮
/// 用于创建可交互的文本高亮区域
public final class TETextHighlight: NSObject, NSCopying, NSSecureCoding {
    
    // MARK: - 类型定义
    
    /// 高亮颜色
    public var color: TEColor?
    
    /// 高亮背景颜色
    public var backgroundColor: TEColor?
    
    /// 高亮边框
    public var border: TETextBorder?
    
    /// 高亮阴影
    public var shadow: TETextShadow?
    
    /// 点击动作
    public var tapAction: ((TEView, NSAttributedString, NSRange, CGRect) -> Void)?
    
    /// 长按动作
    public var longPressAction: ((TEView, NSAttributedString, NSRange, CGRect) -> Void)?
    
    /// 用户信息
    public var userInfo: [String: Any]?
    
    /// 高亮持续时间
    public var highlightDuration: TimeInterval = 0.15
    
    /// 是否启用高亮动画
    public var enableAnimation: Bool = true
    
    // MARK: - 初始化
    
    public override init() {
        super.init()
    }
    
    /// 便利初始化
    public convenience init(color: TEColor? = nil, backgroundColor: TEColor? = nil) {
        self.init()
        self.color = color
        self.backgroundColor = backgroundColor
    }
    
    // MARK: - NSCopying
    
    public func copy(with zone: NSZone? = nil) -> Any {
        let highlight = TETextHighlight()
        highlight.color = color
        highlight.backgroundColor = backgroundColor
        highlight.border = border?.copy() as? TETextBorder
        highlight.shadow = shadow?.copy() as? TETextShadow
        highlight.tapAction = tapAction
        highlight.longPressAction = longPressAction
        highlight.userInfo = userInfo
        highlight.highlightDuration = highlightDuration
        highlight.enableAnimation = enableAnimation
        return highlight
    }
    
    // MARK: - NSSecureCoding
    
    public static var supportsSecureCoding: Bool { return true }
    
    public func encode(with coder: NSCoder) {
        coder.encode(color, forKey: "color")
        coder.encode(backgroundColor, forKey: "backgroundColor")
        coder.encode(border, forKey: "border")
        coder.encode(shadow, forKey: "shadow")
        coder.encode(userInfo as NSDictionary?, forKey: "userInfo")
        coder.encode(highlightDuration, forKey: "highlightDuration")
        coder.encode(enableAnimation, forKey: "enableAnimation")
    }
    
    public required init?(coder: NSCoder) {
        super.init()
        color = coder.decodeObject(of: TEColor.self, forKey: "color")
        backgroundColor = coder.decodeObject(of: TEColor.self, forKey: "backgroundColor")
        border = coder.decodeObject(of: TETextBorder.self, forKey: "border")
        shadow = coder.decodeObject(of: TETextShadow.self, forKey: "shadow")
        userInfo = coder.decodeObject(of: NSDictionary.self, forKey: "userInfo") as? [String: Any]
        highlightDuration = coder.decodeDouble(forKey: "highlightDuration")
        enableAnimation = coder.decodeBool(forKey: "enableAnimation")
    }
    
    // MARK: - 公共方法
    
    /// 创建简单高亮
    /// - Parameter backgroundColor: 背景颜色
    /// - Returns: 高亮对象
    public static func simpleHighlight(backgroundColor: TEColor) -> TETextHighlight {
        return TETextHighlight(backgroundColor: backgroundColor)
    }
    
    /// 创建彩色高亮
    /// - Parameters:
    ///   - color: 文本颜色
    ///   - backgroundColor: 背景颜色
    /// - Returns: 高亮对象
    public static func colorHighlight(color: TEColor, backgroundColor: TEColor) -> TETextHighlight {
        return TETextHighlight(color: color, backgroundColor: backgroundColor)
    }
    
    /// 创建边框高亮
    /// - Parameters:
    ///   - borderColor: 边框颜色
    ///   - borderWidth: 边框宽度
    /// - Returns: 高亮对象
    public static func borderHighlight(borderColor: TEColor, borderWidth: CGFloat = 1) -> TETextHighlight {
        let highlight = TETextHighlight()
        let border = TETextBorder()
        border.color = borderColor
        border.width = borderWidth
        highlight.border = border
        return highlight
    }
    
    /// 创建阴影高亮
    /// - Parameters:
    ///   - shadowColor: 阴影颜色
    ///   - shadowOffset: 阴影偏移
    ///   - shadowRadius: 阴影半径
    /// - Returns: 高亮对象
    public static func shadowHighlight(shadowColor: TEColor, shadowOffset: CGSize, shadowRadius: CGFloat) -> TETextHighlight {
        let highlight = TETextHighlight()
        let shadow = TETextShadow(color: shadowColor, offset: shadowOffset, radius: shadowRadius)
        highlight.shadow = shadow
        return highlight
    }
    
    /// 创建渐变高亮
    /// - Parameters:
    ///   - startColor: 开始颜色
    ///   - endColor: 结束颜色
    ///   - direction: 渐变方向
    /// - Returns: 高亮对象
    public static func gradientHighlight(startColor: TEColor, endColor: TEColor, direction: TEGradientDirection = .horizontal) -> TETextHighlight {
        let highlight = TETextHighlight()
        // 这里可以添加渐变背景色的实现
        highlight.backgroundColor = startColor // 简化实现，实际应该创建渐变背景
        return highlight
    }
    
    /// 创建点击高亮
    /// - Parameters:
    ///   - backgroundColor: 背景颜色
    ///   - tapAction: 点击动作
    /// - Returns: 高亮对象
    public static func tapHighlight(backgroundColor: TEColor, tapAction: @escaping (TEView, NSAttributedString, NSRange, CGRect) -> Void) -> TETextHighlight {
        let highlight = TETextHighlight()
        highlight.backgroundColor = backgroundColor
        highlight.tapAction = tapAction
        return highlight
    }
    
    /// 创建长按高亮
    /// - Parameters:
    ///   - backgroundColor: 背景颜色
    ///   - longPressAction: 长按动作
    /// - Returns: 高亮对象
    public static func longPressHighlight(backgroundColor: TEColor, longPressAction: @escaping (TEView, NSAttributedString, NSRange, CGRect) -> Void) -> TETextHighlight {
        let highlight = TETextHighlight()
        highlight.backgroundColor = backgroundColor
        highlight.longPressAction = longPressAction
        return highlight
    }
    
    /// 绘制高亮
    /// - Parameters:
    ///   - context: 图形上下文
    ///   - rect: 绘制矩形
    ///   - isHighlighted: 是否高亮状态
    func draw(in context: CGContext, rect: CGRect, isHighlighted: Bool) {
        guard isHighlighted else { return }
        
        context.saveGState()
        
        // 绘制背景
        if let backgroundColor = backgroundColor {
            context.setFillColor(backgroundColor.cgColor)
            context.fill(rect)
        }
        
        // 绘制边框
        if let border = border {
            border.draw(in: context, rect: rect, lineOrigin: rect.origin, lineAscent: rect.height, lineDescent: 0, lineHeight: rect.height)
        }
        
        // 应用阴影
        if let shadow = shadow {
            context.setShadow(offset: shadow.offset, blur: shadow.radius, color: shadow.color?.cgColor)
        }
        
        context.restoreGState()
    }
    
    /// 执行点击动作
    /// - Parameters:
    ///   - containerView: 容器视图
    ///   - text: 文本
    ///   - range: 范围
    ///   - rect: 矩形
    func performTapAction(containerView: TEView, text: NSAttributedString, range: NSRange, rect: CGRect) {
        tapAction?(containerView, text, range, rect)
    }
    
    /// 执行长按动作
    /// - Parameters:
    ///   - containerView: 容器视图
    ///   - text: 文本
    ///   - range: 范围
    ///   - rect: 矩形
    func performLongPressAction(containerView: TEView, text: NSAttributedString, range: NSRange, rect: CGRect) {
        longPressAction?(containerView, text, range, rect)
    }
}

// MARK: - 渐变方向

/// 渐变方向
public enum TEGradientDirection {
    case horizontal    // 水平渐变
    case vertical      // 垂直渐变
    case diagonal      // 对角渐变
    case radial        // 径向渐变
}

// MARK: - 高亮管理器

/// 文本高亮管理器
/// 管理文本中的高亮区域和交互
public final class TEHighlightManager {
    
    // MARK: - 属性
    
    /// 高亮数组
    private var highlights: [TEHighlightRange] = []
    
    /// 当前高亮索引
    private var currentHighlightIndex: Int?
    
    /// 激活的高亮范围集合
    private struct ActiveRange {
        let range: NSRange
        let start: Date
        let duration: TimeInterval
        let animate: Bool
    }
    private var activeRanges: [ActiveRange] = []
    
    /// 高亮代理
    public weak var delegate: TEHighlightManagerDelegate?
    
    /// 是否启用高亮
    public var isHighlightEnabled: Bool = true
    
    /// 长按手势识别器
    private var longPressGestureRecognizer: TELongPressGestureRecognizer?
    
    /// 容器视图
    private weak var containerView: TEView?
    
    // MARK: - 初始化
    
    public init() {
        TETextEngine.shared.logDebug("高亮管理器初始化完成", category: "highlight")
    }
    
    // MARK: - 公共方法
    
    /// 添加高亮
    /// - Parameters:
    ///   - highlight: 高亮对象
    ///   - range: 范围
    public func addHighlight(_ highlight: TETextHighlight, range: NSRange) {
        let highlightRange = TEHighlightRange(highlight: highlight, range: range)
        highlights.append(highlightRange)
        
        TETextEngine.shared.logDebug("添加高亮: range=\(range), highlight=\(highlight)", category: "highlight")
    }
    
    /// 移除高亮
    /// - Parameter range: 范围
    public func removeHighlight(in range: NSRange) {
        highlights.removeAll { highlightRange in
            return NSIntersectionRange(highlightRange.range, range).length > 0
        }
        
        TETextEngine.shared.logDebug("移除高亮范围: \(range)", category: "highlight")
    }
    
    /// 清除所有高亮
    public func clearHighlights() {
        highlights.removeAll()
        currentHighlightIndex = nil
        
        TETextEngine.shared.logDebug("清除所有高亮", category: "highlight")
    }
    
    /// 获取指定位置的高亮
    /// - Parameter index: 字符索引
    /// - Returns: 高亮对象
    public func highlight(at index: Int) -> TETextHighlight? {
        guard isHighlightEnabled else { return nil }
        
        for highlightRange in highlights {
            if NSLocationInRange(index, highlightRange.range) {
                return highlightRange.highlight
            }
        }
        
        return nil
    }
    
    /// 获取指定范围的所有高亮
    /// - Parameter range: 范围
    /// - Returns: 高亮数组
    public func highlights(in range: NSRange) -> [TETextHighlight] {
        guard isHighlightEnabled else { return [] }
        
        return highlights.compactMap { highlightRange in
            if NSIntersectionRange(highlightRange.range, range).length > 0 {
                return highlightRange.highlight
            }
            return nil
        }
    }
    
    /// 设置容器视图
    /// - Parameter view: 容器视图
    public func setupContainerView(_ view: TEView) {
        containerView = view
        setupGestureRecognizers()
    }
    
    /// 处理点击
    /// - Parameters:
    ///   - point: 点击点
    ///   - text: 文本
    ///   - textRect: 文本矩形
    /// - Returns: 是否处理了点击
    public func handleTap(at point: CGPoint, in text: NSAttributedString, textRect: CGRect) -> Bool {
        guard isHighlightEnabled, let containerView = containerView else { return false }
        
        // 找到点击位置对应的字符索引
        let characterIndex = characterIndex(at: point, in: text, textRect: textRect)
        guard characterIndex != NSNotFound else { return false }
        
        // 找到对应的高亮
        guard let highlight = highlight(at: characterIndex) else { return false }
        
        // 获取高亮范围
        guard let highlightRange = highlights.first(where: { NSLocationInRange(characterIndex, $0.range) }) else { return false }
        
        // 计算高亮矩形
        let highlightRect = boundingRect(for: highlightRange.range, in: text, textRect: textRect)
        
        // 执行点击动作
        highlight.performTapAction(
            containerView: containerView,
            text: text,
            range: highlightRange.range,
            rect: highlightRect
        )
        // 标记激活并在持续时间后清除
        setActive(range: highlightRange.range, duration: highlight.highlightDuration)
        #if canImport(UIKit)
        containerView.setNeedsDisplay()
        #elseif canImport(AppKit)
        containerView.setNeedsDisplay(containerView.bounds)
        #endif
        
        // 通知代理
        delegate?.highlightManager(self, didTapHighlight: highlight, at: highlightRange.range)
        
        return true
    }
    
    /// 处理长按
    /// - Parameters:
    ///   - point: 长按点
    ///   - text: 文本
    ///   - textRect: 文本矩形
    /// - Returns: 是否处理了长按
    public func handleLongPress(at point: CGPoint, in text: NSAttributedString, textRect: CGRect) -> Bool {
        guard isHighlightEnabled, let containerView = containerView else { return false }
        
        // 找到长按位置对应的字符索引
        let characterIndex = characterIndex(at: point, in: text, textRect: textRect)
        guard characterIndex != NSNotFound else { return false }
        
        // 找到对应的高亮
        guard let highlight = highlight(at: characterIndex) else { return false }
        
        // 获取高亮范围
        guard let highlightRange = highlights.first(where: { NSLocationInRange(characterIndex, $0.range) }) else { return false }
        
        // 计算高亮矩形
        let highlightRect = boundingRect(for: highlightRange.range, in: text, textRect: textRect)
        
        // 执行长按动作
        highlight.performLongPressAction(
            containerView: containerView,
            text: text,
            range: highlightRange.range,
            rect: highlightRect
        )
        setActive(range: highlightRange.range, duration: highlight.highlightDuration)
        #if canImport(UIKit)
        containerView.setNeedsDisplay()
        #elseif canImport(AppKit)
        containerView.setNeedsDisplay(containerView.bounds)
        #endif
        
        // 通知代理
        delegate?.highlightManager(self, didLongPressHighlight: highlight, at: highlightRange.range)
        
        return true
    }
    
    // MARK: - 私有方法
    
    /// 设置手势识别器
    private func setupGestureRecognizers() {
        guard let containerView = containerView else { return }
        
        // 长按手势
        #if canImport(UIKit)
        let longPressGesture = UILongPressGestureRecognizer(target: self, action: #selector(handleLongPressGesture(_:)))
        longPressGesture.minimumPressDuration = 0.5
        #elseif canImport(AppKit)
        let longPressGesture = NSPressGestureRecognizer(target: self, action: #selector(handlePressGesture(_:)))
        #endif
        containerView.addGestureRecognizer(longPressGesture)
        longPressGestureRecognizer = longPressGesture
    }
    
    /// 处理长按手势
    /// - Parameter gesture: 手势识别器
    @objc private func handleLongPressGesture(_ gesture: TEGestureRecognizer) {
        #if canImport(UIKit)
        guard let longPressGesture = gesture as? UILongPressGestureRecognizer, longPressGesture.state == .began else { return }
        #elseif canImport(AppKit)
        guard let pressGesture = gesture as? NSPressGestureRecognizer, pressGesture.state == .began else { return }
        #endif
        
        // 这里需要获取文本和文本矩形，实际使用时需要外部传入
        // 简化实现，实际应该在具体的文本视图中处理
        TETextEngine.shared.logDebug("长按手势触发", category: "highlight")
    }
    
    /// 处理长按手势状态变化（AppKit专用）
    #if canImport(AppKit)
    @objc private func handlePressGesture(_ gesture: NSPressGestureRecognizer) {
        guard gesture.state == .began else { return }
        
        // 这里需要获取文本和文本矩形，实际使用时需要外部传入
        // 简化实现，实际应该在具体的文本视图中处理
        TETextEngine.shared.logDebug("长按手势触发", category: "highlight")
    }
    #endif
    
    /// 获取字符索引
    /// - Parameters:
    ///   - point: 点
    ///   - text: 文本
    ///   - textRect: 文本矩形
    /// - Returns: 字符索引
    public func characterIndex(at point: CGPoint, in text: NSAttributedString, textRect: CGRect, layoutInfo: TELayoutInfo? = nil) -> Int {
        let info: TELayoutInfo
        if let layoutInfo = layoutInfo {
            info = layoutInfo
        } else {
            let lm = TELayoutManager()
            info = lm.layoutSynchronously(text, size: textRect.size, options: [])
        }
        for (i, line) in info.lines.enumerated() {
            let origin = info.lineOrigins[i]
            let rp = CGPoint(x: point.x - origin.x, y: point.y - origin.y)
            let idx = CTLineGetStringIndexForPosition(line, rp)
            if idx != kCFNotFound { return idx }
        }
        return NSNotFound
    }
    
    /// 计算范围边界矩形
    /// - Parameters:
    ///   - range: 范围
    ///   - text: 文本
    ///   - textRect: 文本矩形
    /// - Returns: 边界矩形
    public func boundingRect(for range: NSRange, in text: NSAttributedString, textRect: CGRect, layoutInfo: TELayoutInfo? = nil) -> CGRect {
        let info: TELayoutInfo
        if let layoutInfo = layoutInfo {
            info = layoutInfo
        } else {
            let lm = TELayoutManager()
            info = lm.layoutSynchronously(text, size: textRect.size, options: [])
        }
        var result: CGRect = .null
        for (i, line) in info.lines.enumerated() {
            let origin = info.lineOrigins[i]
            let cfRuns = CTLineGetGlyphRuns(line)
            let runs = (cfRuns as NSArray as? [CTRun]) ?? []
            for run in runs {
                let rr = CTRunGetStringRange(run)
                let inter = NSIntersectionRange(NSRange(location: rr.location, length: rr.length), range)
                if inter.length > 0 {
                    var ascent: CGFloat = 0
                    var descent: CGFloat = 0
                    var leading: CGFloat = 0
                    let width = CGFloat(CTRunGetTypographicBounds(run, CFRange(location: 0, length: 0), &ascent, &descent, &leading))
                    let offset = CTLineGetOffsetForStringIndex(line, rr.location, nil)
                    let rect = CGRect(x: origin.x + CGFloat(offset), y: origin.y - descent, width: width, height: ascent + descent)
                    result = result.union(rect)
                }
            }
        }
        return result.isNull ? .zero : result
    }

    public func characterIndexVertical(at point: CGPoint, in text: NSAttributedString, textRect: CGRect, layoutInfo: TEVerticalLayoutInfo? = nil) -> Int {
        let info: TEVerticalLayoutInfo
        if let layoutInfo = layoutInfo {
            info = layoutInfo
        } else {
            let lm = TEVerticalLayoutManager()
            info = lm.layoutSynchronously(text, size: textRect.size, options: [])
        }
        for (i, line) in info.lines.enumerated() {
            let origin = info.lineOrigins[i]
            let rp = CGPoint(x: point.x - origin.x, y: point.y - origin.y)
            let idx = CTLineGetStringIndexForPosition(line, rp)
            if idx != kCFNotFound { return idx }
        }
        return NSNotFound
    }

    public func boundingRectVertical(for range: NSRange, in text: NSAttributedString, textRect: CGRect, layoutInfo: TEVerticalLayoutInfo? = nil) -> CGRect {
        let info: TEVerticalLayoutInfo
        if let layoutInfo = layoutInfo {
            info = layoutInfo
        } else {
            let lm = TEVerticalLayoutManager()
            info = lm.layoutSynchronously(text, size: textRect.size, options: [])
        }
        var result: CGRect = .null
        for (i, line) in info.lines.enumerated() {
            let origin = info.lineOrigins[i]
            let cfRuns = CTLineGetGlyphRuns(line)
            let runs = (cfRuns as NSArray as? [CTRun]) ?? []
            for run in runs {
                let rr = CTRunGetStringRange(run)
                let inter = NSIntersectionRange(NSRange(location: rr.location, length: rr.length), range)
                if inter.length > 0 {
                    var ascent: CGFloat = 0
                    var descent: CGFloat = 0
                    var leading: CGFloat = 0
                    let width = CGFloat(CTRunGetTypographicBounds(run, CFRange(location: 0, length: 0), &ascent, &descent, &leading))
                    let offset = CTLineGetOffsetForStringIndex(line, rr.location, nil)
                    let rect = CGRect(x: origin.x + CGFloat(offset), y: origin.y - descent, width: width, height: ascent + descent)
                    result = result.union(rect)
                }
            }
        }
        return result.isNull ? .zero : result
    }

    /// 设置激活范围并在指定时间后清除
    private func setActive(range: NSRange, duration: TimeInterval) {
        activeRanges.append(ActiveRange(range: range, start: Date(), duration: duration, animate: true))
        DispatchQueue.main.asyncAfter(deadline: .now() + duration) { [weak self] in
            guard let self = self else { return }
            self.activeRanges.removeAll { NSIntersectionRange($0.range, range).length > 0 }
            #if canImport(UIKit)
            self.containerView?.setNeedsDisplay()
            #elseif canImport(AppKit)
            if let view = self.containerView { view.setNeedsDisplay(view.bounds) }
            #endif
        }
    }
    
    /// 查询范围是否激活
    public func isRangeActive(_ range: NSRange) -> Bool {
        for r in activeRanges {
            if NSIntersectionRange(r.range, range).length > 0 { return true }
        }
        return false
    }

    /// 获取高亮进度 [0,1]，用于淡入淡出（1=完全显示，0=结束）
    public func highlightProgress(for range: NSRange) -> CGFloat {
        guard let entry = activeRanges.first(where: { NSIntersectionRange($0.range, range).length > 0 }) else { return 0 }
        let elapsed = Date().timeIntervalSince(entry.start)
        if !entry.animate || elapsed <= 0 { return 1 }
        let progress = max(0, 1 - elapsed / entry.duration)
        return CGFloat(progress)
    }

    /// 外部触发激活（用于视图命中后主动激活）
    public func activate(range: NSRange, duration: TimeInterval) {
        setActive(range: range, duration: duration)
    }

    public func handleTapVertical(at point: CGPoint, in text: NSAttributedString, textRect: CGRect, layoutInfo: TEVerticalLayoutInfo?) -> Bool {
        guard isHighlightEnabled, let containerView = containerView else { return false }
        let characterIndex = characterIndexVertical(at: point, in: text, textRect: textRect, layoutInfo: layoutInfo)
        guard characterIndex != NSNotFound else { return false }
        guard let highlightRange = highlights.first(where: { NSLocationInRange(characterIndex, $0.range) }) else { return false }
        let highlight = highlightRange.highlight
        let highlightRect = boundingRectVertical(for: highlightRange.range, in: text, textRect: textRect, layoutInfo: layoutInfo)
        highlight.performTapAction(containerView: containerView, text: text, range: highlightRange.range, rect: highlightRect)
        setActive(range: highlightRange.range, duration: highlight.highlightDuration)
        #if canImport(UIKit)
        containerView.setNeedsDisplay()
        #elseif canImport(AppKit)
        containerView.setNeedsDisplay(containerView.bounds)
        #endif
        delegate?.highlightManager(self, didTapHighlight: highlight, at: highlightRange.range)
        return true
    }

    public func handleLongPressVertical(at point: CGPoint, in text: NSAttributedString, textRect: CGRect, layoutInfo: TEVerticalLayoutInfo?) -> Bool {
        guard isHighlightEnabled, let containerView = containerView else { return false }
        let characterIndex = characterIndexVertical(at: point, in: text, textRect: textRect, layoutInfo: layoutInfo)
        guard characterIndex != NSNotFound else { return false }
        guard let highlightRange = highlights.first(where: { NSLocationInRange(characterIndex, $0.range) }) else { return false }
        let highlight = highlightRange.highlight
        let highlightRect = boundingRectVertical(for: highlightRange.range, in: text, textRect: textRect, layoutInfo: layoutInfo)
        highlight.performLongPressAction(containerView: containerView, text: text, range: highlightRange.range, rect: highlightRect)
        setActive(range: highlightRange.range, duration: highlight.highlightDuration)
        #if canImport(UIKit)
        containerView.setNeedsDisplay()
        #elseif canImport(AppKit)
        containerView.setNeedsDisplay(containerView.bounds)
        #endif
        delegate?.highlightManager(self, didLongPressHighlight: highlight, at: highlightRange.range)
        return true
    }
}

// MARK: - 高亮范围

/// 高亮范围
private struct TEHighlightRange {
    let highlight: TETextHighlight
    let range: NSRange
}

// MARK: - 高亮管理器代理

/// 高亮管理器代理
public protocol TEHighlightManagerDelegate: AnyObject {
    
    /// 高亮被点击
    /// - Parameters:
    ///   - manager: 高亮管理器
    ///   - highlight: 被点击的高亮
    ///   - range: 高亮范围
    func highlightManager(_ manager: TEHighlightManager, didTapHighlight highlight: TETextHighlight, at range: NSRange)
    
    /// 高亮被长按
    /// - Parameters:
    ///   - manager: 高亮管理器
    ///   - highlight: 被长按的高亮
    ///   - range: 高亮范围
    func highlightManager(_ manager: TEHighlightManager, didLongPressHighlight highlight: TETextHighlight, at range: NSRange)
}
