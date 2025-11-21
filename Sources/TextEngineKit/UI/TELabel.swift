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
    
    /// 是否启用高亮
    public var isHighlightEnabled: Bool {
        get { return highlightManager.isHighlightEnabled }
        set { highlightManager.isHighlightEnabled = newValue }
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
                    accessibilityLabel = attributedText.string
                } else {
                    TETextEngineError.threadSafetyViolation(operation: "set attributedText on TELabel").log(category: "ui")
                    DispatchQueue.main.async { [weak self] in
                        self?.parseAttachmentsAndHighlights(in: attributedText)
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
    
    /// 执行同步布局
    private func performSyncLayout() {
        guard let attributedText = attributedText else { return }
        
        let layoutInfo = layoutManager.layoutSynchronously(attributedText, size: bounds.size, options: layoutOptions)
        lastLayoutInfo = layoutInfo
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
#endif
