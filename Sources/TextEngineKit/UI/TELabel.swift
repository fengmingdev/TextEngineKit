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
        
        let layoutManager = NSLayoutManager()
        let textContainer = NSTextContainer(size: bounds.size)
        let textStorage = NSTextStorage(attributedString: attributedText)
        
        layoutManager.addTextContainer(textContainer)
        textStorage.addLayoutManager(layoutManager)
        
        textContainer.lineFragmentPadding = 0
        textContainer.maximumNumberOfLines = numberOfLines
        textContainer.lineBreakMode = lineBreakMode
        
        let index = layoutManager.characterIndex(for: point, in: textContainer, fractionOfDistanceBetweenInsertionPoints: nil)
        return index
    }
    
    /// 获取指定字符索引的边界矩形
    /// - Parameter index: 字符索引
    /// - Returns: 边界矩形
    public func boundingRect(forCharacterAt index: Int) -> CGRect {
        guard let attributedText = attributedText else { return .zero }
        
        let layoutManager = NSLayoutManager()
        let textContainer = NSTextContainer(size: bounds.size)
        let textStorage = NSTextStorage(attributedString: attributedText)
        
        layoutManager.addTextContainer(textContainer)
        textStorage.addLayoutManager(layoutManager)
        
        textContainer.lineFragmentPadding = 0
        textContainer.maximumNumberOfLines = numberOfLines
        textContainer.lineBreakMode = lineBreakMode
        
        let glyphRange = layoutManager.glyphRange(forCharacterRange: NSRange(location: index, length: 1), actualCharacterRange: nil)
        return layoutManager.boundingRect(forGlyphRange: glyphRange, in: textContainer)
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
    
    /// 设置手势识别器
    private func setupGestureRecognizers() {
        // 点击手势
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(handleTap(_:)))
        addGestureRecognizer(tapGesture)
        
        // 长按手势
        let longPressGesture = UILongPressGestureRecognizer(target: self, action: #selector(handleLongPress(_:)))
        longPressGesture.minimumPressDuration = 0.5
        addGestureRecognizer(longPressGesture)
    }
    
    /// 处理点击手势
    /// - Parameter gesture: 手势识别器
    @objc private func handleTap(_ gesture: UITapGestureRecognizer) {
        let location = gesture.location(in: self)
        if let attributedText = attributedText {
            _ = highlightManager.handleTap(at: location, in: attributedText, textRect: bounds)
        }
    }
    
    /// 处理长按手势
    /// - Parameter gesture: 手势识别器
    @objc private func handleLongPress(_ gesture: UILongPressGestureRecognizer) {
        guard gesture.state == .began else { return }
        let location = gesture.location(in: self)
        if let attributedText = attributedText {
            _ = highlightManager.handleLongPress(at: location, in: attributedText, textRect: bounds)
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
    private func drawAttachments(in context: CGContext, rect: CGRect) {
        let attachments = attachmentManager.allAttachments()
        
        for attachment in attachments {
            // 这里需要计算附件的实际绘制位置
            let attachmentRect = CGRect(x: 0, y: 0, width: attachment.size.width, height: attachment.size.height)
            attachment.draw(in: context, rect: attachmentRect, containerView: self)
        }
    }

    private func rebuildAccessibilityElements(layoutInfo: TELayoutInfo) {
        guard let attributed = attributedText else { return }
        var elements: [UIAccessibilityElement] = []
        // 行元素
        for (index, line) in layoutInfo.lines.enumerated() {
            let origin = layoutInfo.lineOrigins[index]
            var ascent: CGFloat = 0, descent: CGFloat = 0, leading: CGFloat = 0
            let width = CGFloat(CTLineGetTypographicBounds(line, &ascent, &descent, &leading))
            let rect = CGRect(x: origin.x, y: origin.y - descent, width: width, height: ascent + descent)
            let elem = UIAccessibilityElement(accessibilityContainer: self)
            let stringRange = CTLineGetStringRange(line)
            let nsRange = NSRange(location: stringRange.location, length: stringRange.length)
            let labelText = (attributed.string as NSString).substring(with: nsRange)
            var prefix = ""
            attributed.enumerateAttributes(in: nsRange, options: []) { attrs, _, _ in
                if let font = attrs[TEAttributeKey.font] as? UIFont, font.fontDescriptor.symbolicTraits.contains(.traitMonoSpace) {
                    prefix = "代码: "
                } else if let color = attrs[TEAttributeKey.foregroundColor] as? UIColor, color == UIColor.systemGray {
                    prefix = prefix.isEmpty ? "引用: " : prefix
                } else if let ps = attrs[TEAttributeKey.paragraphStyle] as? NSParagraphStyle, ps.headIndent >= 20 {
                    prefix = prefix.isEmpty ? "列表: " : prefix
                }
            }
            elem.accessibilityLabel = prefix.isEmpty ? labelText : (prefix + labelText)
            elem.accessibilityTraits = [.staticText]
            elem.accessibilityFrameInContainerSpace = rect
            elements.append(elem)
        }
        // 链接元素
        attributed.enumerateAttribute(.link, in: NSRange(location: 0, length: attributed.length), options: []) { value, range, _ in
            guard let v = value as? String, let url = URL(string: v) else { return }
            let rect = TETextHighlight().boundingRect(for: range, in: attributed, textRect: bounds, layoutInfo: layoutInfo)
            let linkElem = TEAccessibilityLinkElement(accessibilityContainer: self, url: url, copyText: (attributed.string as NSString).substring(with: range))
            linkElem.accessibilityTraits = [.link]
            linkElem.accessibilityLabel = (attributed.string as NSString).substring(with: range)
            linkElem.accessibilityFrameInContainerSpace = rect
            linkElem.onOpen = { [weak self] u in self?.onLinkOpen?(u) }
            linkElem.onCopy = { [weak self] s in self?.onCopy?(s) }
            elements.append(linkElem)
        }
        // 附件元素
        attributed.enumerateAttribute(TEAttributeKey.textAttachment, in: NSRange(location: 0, length: attributed.length), options: []) { value, range, _ in
            guard let attachment = value as? TETextAttachment else { return }
            let rect = TETextHighlight().boundingRect(for: range, in: attributed, textRect: bounds, layoutInfo: layoutInfo)
            let elem = TEAccessibilityAttachmentElement(accessibilityContainer: self, attachment: attachment)
            elem.accessibilityTraits = [.image]
            elem.accessibilityLabel = "附件"
            elem.accessibilityFrameInContainerSpace = rect
            elem.onView = { [weak self] att in self?.onAttachmentView?(att) }
            elem.onSave = { [weak self] att in self?.onAttachmentSave?(att) }
            elements.append(elem)
        }
        self.accessibilityElements = elements
    }
    
    final class TEAccessibilityLinkElement: UIAccessibilityElement {
        var url: URL
        var copyText: String
        var onOpen: ((URL) -> Void)?
        var onCopy: ((String) -> Void)?
        init(accessibilityContainer: Any, url: URL, copyText: String) {
            self.url = url
            self.copyText = copyText
            super.init(accessibilityContainer: accessibilityContainer)
            let openAction = UIAccessibilityCustomAction(name: "打开链接", target: self, selector: #selector(accessibilityOpen))
            let copyAction = UIAccessibilityCustomAction(name: "复制文本", target: self, selector: #selector(accessibilityCopy))
            self.accessibilityCustomActions = [openAction, copyAction]
        }
        override func accessibilityActivate() -> Bool {
            onOpen?(url)
            TETextEngine.shared.logDebug("VoiceOver 激活链接: \(url.absoluteString)", category: "accessibility")
            return true
        }
        @objc private func accessibilityOpen() -> Bool {
            onOpen?(url)
            TETextEngine.shared.logDebug("VoiceOver 打开链接: \(url.absoluteString)", category: "accessibility")
            return true
        }
        @objc private func accessibilityCopy() -> Bool {
            onCopy?(copyText)
            TETextEngine.shared.logDebug("VoiceOver 复制文本: length=\(copyText.count)", category: "accessibility")
            return true
        }
    }
    
    final class TEAccessibilityAttachmentElement: UIAccessibilityElement {
        var attachment: TETextAttachment
        var onView: ((TETextAttachment) -> Void)?
        var onSave: ((TETextAttachment) -> Void)?
        init(accessibilityContainer: Any, attachment: TETextAttachment) {
            self.attachment = attachment
            super.init(accessibilityContainer: accessibilityContainer)
            let viewAction = UIAccessibilityCustomAction(name: "查看附件", target: self, selector: #selector(accessibilityView))
            let saveAction = UIAccessibilityCustomAction(name: "保存图片", target: self, selector: #selector(accessibilitySave))
            self.accessibilityCustomActions = [viewAction, saveAction]
        }
        @objc private func accessibilityView() -> Bool {
            onView?(attachment)
            TETextEngine.shared.logDebug("VoiceOver 查看附件", category: "accessibility")
            return true
        }
        @objc private func accessibilitySave() -> Bool {
            if let onSave = onSave {
                onSave(attachment)
                TETextEngine.shared.logDebug("VoiceOver 保存附件(自定义)", category: "accessibility")
                return true
            }
            #if canImport(UIKit)
            if case .image(let img) = attachment.content {
                UIImageWriteToSavedPhotosAlbum(img, nil, nil, nil)
                TETextEngine.shared.logInfo("已保存图片到照片库", category: "accessibility")
                return true
            }
            #endif
            TETextEngine.shared.logWarning("附件保存未执行：不支持的类型或平台", category: "accessibility")
            return false
        }
    }
}

extension TELabel: TEAsyncLayerDelegate {
    public func draw(in context: CGContext, size: CGSize) {
        guard let attributedText = attributedText else { return }
        renderer.renderSynchronously(attributedText, in: context, rect: CGRect(origin: .zero, size: size), options: renderOptions)
        drawAttachments(in: context, rect: CGRect(origin: .zero, size: size))
    }
}
#endif
