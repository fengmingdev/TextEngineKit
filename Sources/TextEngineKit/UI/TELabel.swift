// 
//  TELabel.swift 
//  TextEngineKit 
// 
//  Created by fengming on 2025/11/17. 
// 
//  富文本标签：高性能显示控件，支持异步布局与渲染、文本高亮与附件管理、交互与无障碍。 
// 
#if canImport(UIKit)
import UIKit
import Foundation

/// 富文本标签
/// 高性能的富文本显示控件
@IBDesignable
@MainActor
public final class TELabel: UILabel {
    
    // MARK: - 属性
    
    /// 富文本布局管理器
    private let layoutManager = TELayoutManager()
    
    /// 富文本渲染器
    private let renderer = TETextRenderer()
    private let asyncLayer = TEAsyncLayer()
    
    /// 高亮管理器
    private let highlightManager = TEHighlightManager()
    
    /// 附件管理器
    private let attachmentManager = TEAttachmentManager()
    
    /// 文本选择管理器
    private let selectionManager = TETextSelectionManager()
    
    /// 排除路径管理器
    private let exclusionPathManager = TEExclusionPathManager()
    
    /// 链接打开回调
    public var onLinkOpen: ((Foundation.URL) -> Void)?
    /// 复制回调
    public var onCopy: ((String) -> Void)?
    /// 查看附件回调
    public var onAttachmentView: ((TETextAttachment) -> Void)?
    /// 保存附件回调
    public var onAttachmentSave: ((TETextAttachment) -> Void)?
    private var lastLayoutInfo: TELayoutInfo?
    
    /// 是否启用异步布局
    @IBInspectable public var enableAsyncLayout: Bool = true {
        didSet {
            if enableAsyncLayout != oldValue {
                setNeedsLayout()
            }
        }
    }
    
    /// 是否启用异步渲染
    @IBInspectable public var enableAsyncRendering: Bool = true {
        didSet {
            if enableAsyncRendering != oldValue {
                setNeedsDisplay()
            }
        }
    }
    @IBInspectable public var preferAsyncRendering: Bool = true
    
    /// 布局选项
    public var layoutOptions: TELayoutOptions = []
    
    /// 渲染选项
    public var renderOptions: TERenderOptions = .default
    
    /// 高亮代理
    public weak var highlightDelegate: TEHighlightManagerDelegate? {
        didSet {
            highlightManager.delegate = highlightDelegate
        }
    }
    
    /// 选择代理
    public weak var selectionDelegate: TETextSelectionManagerDelegate? {
        didSet {
            selectionManager.delegate = selectionDelegate
        }
    }
    
    /// 是否启用高亮
    public var isHighlightEnabled: Bool {
        get { return highlightManager.isHighlightEnabled }
        set { highlightManager.isHighlightEnabled = newValue }
    }
    
    /// 是否启用文本选择
    public var isTextSelectionEnabled: Bool {
        get { return selectionManager.isSelectionEnabled }
        set { selectionManager.isSelectionEnabled = newValue }
    }
    
    /// 是否启用选择手柄
    public var isSelectionHandleEnabled: Bool {
        get { return selectionManager.isSelectionHandleEnabled }
        set { selectionManager.isSelectionHandleEnabled = newValue }
    }
    
    /// 自定义绘制代码
    public var customDrawBlock: ((CGContext, CGRect) -> Void)?
    
    // MARK: - 初始化
    
    public override init(frame: CGRect) {
        super.init(frame: frame)
        setupLabel()
    }
    
    public required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupLabel()
    }
    
    private func setupLabel() {
        // 设置默认属性
        numberOfLines = 0
        lineBreakMode = .byWordWrapping
        
        // 设置高亮管理器
        highlightManager.setupContainerView(self)
        // 将高亮激活状态提供给渲染器
        renderer.highlightStateProvider = { [weak self] range in
            guard let self = self else { return false }
            return self.highlightManager.isRangeActive(range)
        }
        renderer.highlightProgressProvider = { [weak self] range in
            guard let self = self else { return 0 }
            return self.highlightManager.highlightProgress(for: range)
        }
        
        // 设置选择管理器
        selectionManager.setupContainerView(self)
        
        // 启用用户交互
        isUserInteractionEnabled = true
        
        // 添加手势识别器
        setupGestureRecognizers()
        
        isAccessibilityElement = false
        accessibilityTraits = .staticText
        layer.addSublayer(asyncLayer)
        asyncLayer.asyncDelegate = self
        asyncLayer.contentsScale = UIScreen.main.scale
        TETextEngine.shared.logDebug("TELabel 初始化完成", category: "ui")
    }
    
    // MARK: - 重写方法
    
    public override var attributedText: NSAttributedString? {
        didSet {
            if let attributedText = attributedText {
                if Thread.isMainThread {
                    parseAttachmentsAndHighlights(in: attributedText)
                    updateSelectionManagerText(attributedText)
                    accessibilityLabel = attributedText.string
                } else {
                    TETextEngineError.threadSafetyViolation(operation: "set attributedText on TELabel").log(category: "ui")
                    DispatchQueue.main.async { [weak self] in
                        self?.parseAttachmentsAndHighlights(in: attributedText)
                        self?.updateSelectionManagerText(attributedText)
                        self?.setNeedsDisplay()
                        self?.setNeedsLayout()
                        self?.accessibilityLabel = attributedText.string
                    }
                }
            }
        }
    }
    
    public override func layoutSubviews() {
        super.layoutSubviews()
        
        if enableAsyncLayout {
            performAsyncLayout()
        } else {
            performSyncLayout()
        }
        asyncLayer.frame = bounds
    }
    
    public override func draw(_ rect: CGRect) {
        guard attributedText != nil else { super.draw(rect); return }
        if enableAsyncRendering && preferAsyncRendering {
            asyncLayer.isAsyncEnabled = true
            asyncLayer.setNeedsDisplay()
        } else {
            performSyncRendering(in: rect)
        }
    }
    
    public override func drawText(in rect: CGRect) {
        // 自定义绘制逻辑
        if let customDrawBlock = customDrawBlock {
            guard let context = UIGraphicsGetCurrentContext() else { return }
            customDrawBlock(context, rect)
        } else {
            super.drawText(in: rect)
        }
    }
    
    // MARK: - 公共方法
    
    /// 设置文本高亮
    /// - Parameters:
    ///   - highlight: 高亮对象
    ///   - range: 范围
    public func setTextHighlight(_ highlight: TETextHighlight, range: NSRange) {
        highlightManager.addHighlight(highlight, range: range)
        setNeedsDisplay()
    }
    
    /// 移除文本高亮
    /// - Parameter range: 范围
    public func removeTextHighlight(in range: NSRange) {
        highlightManager.removeHighlight(in: range)
        setNeedsDisplay()
    }
    
    /// 清除所有文本高亮
    public func clearTextHighlights() {
        highlightManager.clearHighlights()
        setNeedsDisplay()
    }
    
    /// 设置文本附件
    /// - Parameters:
    ///   - attachment: 附件
    ///   - at: 位置
    public func setTextAttachment(_ attachment: TETextAttachment, at location: Int) {
        attachmentManager.addAttachment(attachment, at: location)
        setNeedsDisplay()
    }
    
    /// 移除文本附件
    /// - Parameter location: 位置
    public func removeTextAttachment(at location: Int) {
        attachmentManager.removeAttachment(at: location)
        setNeedsDisplay()
    }
    
    /// 清除所有文本附件
    public func clearTextAttachments() {
        attachmentManager.clearAttachments()
        setNeedsDisplay()
    }
    
    /// 获取指定位置的字符索引
    /// - Parameter point: 点
    /// - Returns: 字符索引
    public func characterIndex(at point: CGPoint) -> Int {
        guard let attributedText = attributedText else { return NSNotFound }
        return highlightManager.characterIndex(at: point, in: attributedText, textRect: bounds, layoutInfo: lastLayoutInfo)
    }
    
    /// 获取指定字符索引的边界矩形
    /// - Parameter index: 字符索引
    /// - Returns: 边界矩形
    public func boundingRect(forCharacterAt index: Int) -> CGRect {
        guard let attributedText = attributedText else { return .zero }
        let range = NSRange(location: index, length: 1)
        return highlightManager.boundingRect(for: range, in: attributedText, textRect: bounds, layoutInfo: lastLayoutInfo)
    }
    
    /// 获取布局统计信息
    /// - Returns: 统计信息
    public func getLayoutStatistics() -> TELayoutStatistics {
        return layoutManager.getStatistics()
    }
    
    /// 获取渲染统计信息
    /// - Returns: 统计信息
    public func getRenderStatistics() -> TERenderStatistics {
        return renderer.getStatistics()
    }
    
    // MARK: - UILabel API 兼容性增强
    
    /// 文本对齐方式（兼容UILabel）
    public override var textAlignment: NSTextAlignment {
        get { return super.textAlignment }
        set {
            super.textAlignment = newValue
            setNeedsLayout()
            setNeedsDisplay()
        }
    }
    
    /// 字体（兼容UILabel）
    public override var font: UIFont! {
        get { return super.font }
        set {
            super.font = newValue
            setNeedsLayout()
            setNeedsDisplay()
        }
    }
    
    /// 文本颜色（兼容UILabel）
    public override var textColor: UIColor! {
        get { return super.textColor }
        set {
            super.textColor = newValue
            setNeedsDisplay()
        }
    }
    
    /// 阴影颜色（兼容UILabel）
    public override var shadowColor: UIColor? {
        get { return super.shadowColor }
        set {
            super.shadowColor = newValue
            setNeedsDisplay()
        }
    }
    
    /// 阴影偏移（兼容UILabel）
    public override var shadowOffset: CGSize {
        get { return super.shadowOffset }
        set {
            super.shadowOffset = newValue
            setNeedsDisplay()
        }
    }
    
    /// 阴影模糊半径（兼容UILabel）
    public override var shadowRadius: CGFloat {
        get { return layer.shadowRadius }
        set {
            layer.shadowRadius = newValue
            setNeedsDisplay()
        }
    }
    
    /// 首选最大布局宽度（兼容UILabel）
    public override var preferredMaxLayoutWidth: CGFloat {
        get { return super.preferredMaxLayoutWidth }
        set {
            super.preferredMaxLayoutWidth = newValue
            setNeedsLayout()
        }
    }
    
    /// 调整字体大小以适应宽度（兼容UILabel）
    public func adjustFontSizeToFitWidth() {
        guard let currentFont = font, let text = text, !text.isEmpty else { return }
        
        let minFontSize: CGFloat = 10.0
        let maxFontSize: CGFloat = currentFont.pointSize
        var bestFontSize = maxFontSize
        
        for fontSize in stride(from: maxFontSize, to: minFontSize, by: -1.0) {
            let testFont = currentFont.withSize(fontSize)
            let textSize = (text as NSString).size(withAttributes: [.font: testFont])
            
            if textSize.width <= bounds.width && textSize.height <= bounds.height {
                bestFontSize = fontSize
                break
            }
        }
        
        font = currentFont.withSize(bestFontSize)
    }
    
    /// 获取指定点的字符索引（类似UITextView）
    public func characterIndex(at point: CGPoint) -> Int {
        return highlightManager.characterIndex(at: point, in: attributedText ?? NSAttributedString(), textRect: bounds, layoutInfo: lastLayoutInfo)
    }
    
    /// 获取指定字符索引的边界矩形（类似UITextView）
    public func boundingRect(forCharacterAt index: Int) -> CGRect {
        let range = NSRange(location: index, length: 1)
        return highlightManager.boundingRect(for: range, in: attributedText ?? NSAttributedString(), textRect: bounds, layoutInfo: lastLayoutInfo)
    }
    
    /// 获取指定范围的边界矩形（类似UITextView）
    public func boundingRect(for range: NSRange) -> CGRect {
        return highlightManager.boundingRect(for: range, in: attributedText ?? NSAttributedString(), textRect: bounds, layoutInfo: lastLayoutInfo)
    }
    
    /// 添加排除路径
    /// - Parameter path: 排除路径
    public func addExclusionPath(_ path: TEExclusionPath) {
        exclusionPathManager.addExclusionPath(path)
        setNeedsLayout()
        setNeedsDisplay()
    }
    
    /// 移除排除路径
    /// - Parameter path: 排除路径
    public func removeExclusionPath(_ path: TEExclusionPath) {
        exclusionPathManager.removeExclusionPath(path)
        setNeedsLayout()
        setNeedsDisplay()
    }
    
    /// 清除所有排除路径
    public func clearExclusionPaths() {
        exclusionPathManager.clearExclusionPaths()
        setNeedsLayout()
        setNeedsDisplay()
    }
    
    /// 选择所有文本
    public func selectAll() {
        selectionManager.selectAll()
    }
    
    /// 清除选择
    public func clearSelection() {
        selectionManager.clearSelection()
    }
    
    /// 获取选中的文本
    /// - Returns: 选中的文本
    public func selectedText() -> String? {
        return selectionManager.selectedText()
    }
    
    /// 复制选中的文本
    public func copySelectedText() {
        selectionManager.copySelectedText()
    }
    
    // MARK: - 私有方法
    
    /// 执行点击高亮逻辑
    func performTap(at location: CGPoint, in attributedText: NSAttributedString) {
        let handled = highlightManager.handleTap(at: location, in: attributedText, textRect: bounds, layoutInfo: lastLayoutInfo)
        if handled { return }
        let index = highlightManager.characterIndex(at: location, in: attributedText, textRect: bounds, layoutInfo: lastLayoutInfo)
        guard index != NSNotFound else { return }
        var effective = NSRange(location: 0, length: 0)
        let value = attributedText.attribute(.link, at: index, effectiveRange: &effective)
        let url: URL? = {
            if let u = value as? URL { return u }
            if let s = value as? String { return URL(string: s) }
            return nil
        }()
        if let u = url { onLinkOpen?(u) }
    }

    /// 执行长按高亮逻辑
    func performLongPress(at location: CGPoint, in attributedText: NSAttributedString) {
        let handled = highlightManager.handleLongPress(at: location, in: attributedText, textRect: bounds, layoutInfo: lastLayoutInfo)
        if handled { return }
        let index = highlightManager.characterIndex(at: location, in: attributedText, textRect: bounds, layoutInfo: lastLayoutInfo)
        guard index != NSNotFound else { return }
        var effective = NSRange(location: 0, length: 0)
        let value = attributedText.attribute(.link, at: index, effectiveRange: &effective)
        let url: URL? = {
            if let u = value as? URL { return u }
            if let s = value as? String { return URL(string: s) }
            return nil
        }()
        if let u = url {
            onLinkOpen?(u)
        } else {
            let text = (attributedText.string as NSString).substring(with: effective)
            onCopy?(text)
        }
    }
    
    /// 解析附件和高亮
    /// - Parameter attributedString: 属性字符串
    private func parseAttachmentsAndHighlights(in attributedString: NSAttributedString) {
        attributedString.enumerateAttributes(in: NSRange(location: 0, length: attributedString.length), options: []) { attributes, range, _ in
            // 解析附件
            if let attachment = attributes[TEAttributeKey.textAttachment] as? TETextAttachment {
                attachmentManager.addAttachment(attachment, at: range.location)
            }
            
            // 解析高亮
            if let highlight = attributes[TEAttributeKey.textHighlight] as? TETextHighlight {
                highlightManager.addHighlight(highlight, range: range)
            }
        }
    }
    
    /// 更新选择管理器文本
    /// - Parameter attributedText: 属性文本
    private func updateSelectionManagerText(_ attributedText: NSAttributedString?) {
        selectionManager.updateText(attributedText, layoutInfo: lastLayoutInfo)
    }
    
    /// 执行同步布局
    private func performSyncLayout() {
        guard let attributedText = attributedText else { return }
        
        let layoutInfo = layoutManager.layoutSynchronously(attributedText, size: bounds.size, options: layoutOptions)
        lastLayoutInfo = layoutInfo
        
        // 更新选择管理器布局信息
        selectionManager.updateText(attributedText, layoutInfo: layoutInfo)
        
        rebuildAccessibilityElements(layoutInfo: layoutInfo)
        
        // 这里可以更新内部布局状态
        TETextEngine.shared.logDebug("执行同步布局: size=\(bounds.size), lines=\(layoutInfo.lineCount)", category: "ui")
    }
    
    /// 执行异步布局
    private func performAsyncLayout() {
        guard let attributedText = attributedText else { return }
        
        layoutManager.layoutAsynchronously(attributedText, size: bounds.size, options: layoutOptions) { [weak self] layoutInfo in
            guard let self = self else { return }
            
            DispatchQueue.main.async {
                // 这里可以更新内部布局状态
                TETextEngine.shared.logDebug("执行异步布局完成: size=\(self.bounds.size), lines=\(layoutInfo.lineCount)", category: "ui")
                self.lastLayoutInfo = layoutInfo
                
                // 更新选择管理器布局信息
                self.selectionManager.updateText(self.attributedText, layoutInfo: layoutInfo)
                
                self.rebuildAccessibilityElements(layoutInfo: layoutInfo)
            }
        }
    }
    
    /// 执行同步渲染
    /// - Parameter rect: 渲染矩形
    private func performSyncRendering(in rect: CGRect) {
        guard let attributedText = attributedText else { return }
        
        guard let context = UIGraphicsGetCurrentContext() else { return }
        
        renderer.renderSynchronously(attributedText, in: context, rect: rect, options: renderOptions)
        
        // 绘制附件
        drawAttachments(in: context, rect: rect)
    }
    
    /// 执行异步渲染
    /// - Parameter rect: 渲染矩形
    private func performAsyncRendering(in rect: CGRect) {
        asyncLayer.isAsyncEnabled = true
        asyncLayer.setNeedsDisplay()
    }
    
    /// 绘制附件
    /// - Parameters:
    ///   - context: 图形上下文
    ///   - rect: 绘制矩形
    

    
    
    
}

extension TELabel: TEAsyncLayerDelegate {
    public func draw(in context: CGContext, size: CGSize) {
        guard let attributedText = attributedText else { return }
        renderer.renderSynchronously(attributedText, in: context, rect: CGRect(origin: .zero, size: size), options: renderOptions)
        drawAttachments(in: context, rect: CGRect(origin: .zero, size: size))
    }
}

// MARK: - UILabel API 兼容性扩展

extension TELabel {
    
    /// 垂直文本对齐（MPITextKit兼容）
    public enum TextVerticalAlignment {
        case top
        case center
        case bottom
    }
    
    /// 垂直文本对齐
    public var textVerticalAlignment: TextVerticalAlignment {
        get {
            return objc_getAssociatedObject(self, &textVerticalAlignmentKey) as? TextVerticalAlignment ?? .center
        }
        set {
            objc_setAssociatedObject(self, &textVerticalAlignmentKey, newValue, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
            setNeedsLayout()
            setNeedsDisplay()
        }
    }
    
    /// 文本容器内边距（MPITextKit兼容）
    public var textContainerInset: UIEdgeInsets {
        get {
            return objc_getAssociatedObject(self, &textContainerInsetKey) as? UIEdgeInsets ?? .zero
        }
        set {
            objc_setAssociatedObject(self, &textContainerInsetKey, newValue, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
            setNeedsLayout()
            setNeedsDisplay()
        }
    }
    
    /// 截断标记（MPITextKit兼容）
    public var truncationAttributedToken: NSAttributedString? {
        get {
            return objc_getAssociatedObject(self, &truncationAttributedTokenKey) as? NSAttributedString
        }
        set {
            objc_setAssociatedObject(self, &truncationAttributedTokenKey, newValue, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
            setNeedsLayout()
            setNeedsDisplay()
        }
    }
    
    /// 额外截断消息（MPITextKit兼容）
    public var additionalTruncationAttributedMessage: NSAttributedString? {
        get {
            return objc_getAssociatedObject(self, &additionalTruncationAttributedMessageKey) as? NSAttributedString
        }
        set {
            objc_setAssociatedObject(self, &additionalTruncationAttributedMessageKey, newValue, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
            setNeedsLayout()
            setNeedsDisplay()
        }
    }
    
    /// 是否启用调试模式
    public var isDebugModeEnabled: Bool {
        get {
            return objc_getAssociatedObject(self, &isDebugModeEnabledKey) as? Bool ?? false
        }
        set {
            objc_setAssociatedObject(self, &isDebugModeEnabledKey, newValue, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
            if newValue {
                enableDebugMode()
            } else {
                disableDebugMode()
            }
        }
    }
    
    /// 是否启用性能分析
    public var isPerformanceProfilingEnabled: Bool {
        get {
            return objc_getAssociatedObject(self, &isPerformanceProfilingEnabledKey) as? Bool ?? false
        }
        set {
            objc_setAssociatedObject(self, &isPerformanceProfilingEnabledKey, newValue, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
            if newValue {
                enablePerformanceProfiling()
            } else {
                disablePerformanceProfiling()
            }
        }
    }
}

// 关联对象键
private var textVerticalAlignmentKey: UInt8 = 0
private var textContainerInsetKey: UInt8 = 0
private var truncationAttributedTokenKey: UInt8 = 0
private var additionalTruncationAttributedMessageKey: UInt8 = 0
private var isDebugModeEnabledKey: UInt8 = 0
private var isPerformanceProfilingEnabledKey: UInt8 = 0
#endif
