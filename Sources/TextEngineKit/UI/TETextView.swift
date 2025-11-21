// 
//  TETextView.swift 
//  TextEngineKit 
// 
//  Created by fengming on 2025/11/17. 
// 
//  富文本视图：支持编辑与显示、解析、高亮与附件管理，含异步布局与渲染。 
// 
#if canImport(UIKit)
import UIKit

/// 富文本视图
/// 功能丰富的富文本编辑和显示控件
@IBDesignable
@MainActor
public final class TETextView: UITextView {
    
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
    
    /// 解析器
    public var parser: TETextParser?

    /// 链接打开回调
    public var onLinkOpen: ((Foundation.URL) -> Void)?
    /// 复制回调
    public var onCopy: ((String) -> Void)?
    private var lastLayoutInfo: TELayoutInfo?
    
    /// 是否启用异步布局
    @IBInspectable public var enableAsyncLayout: Bool = true
    
    /// 是否启用异步渲染
    @IBInspectable public var enableAsyncRendering: Bool = true
    @IBInspectable public var autoDisableAsyncWhenEditing: Bool = true
    public enum TEAsyncEditingDegradePolicy: Int { case none = 0, disableAsync = 1, lowQuality = 2, forceSync = 3 }
    public var editingAsyncDegradePolicy: TEAsyncEditingDegradePolicy = .disableAsync
    @IBInspectable public var editingAsyncDegradePolicyRaw: Int {
        get { editingAsyncDegradePolicy.rawValue }
        set { editingAsyncDegradePolicy = TEAsyncEditingDegradePolicy(rawValue: newValue) ?? .disableAsync }
    }
    public var disableDecorationsDuringEditing: Bool = true
    private var isCurrentlyEditing: Bool = false
    
    /// 布局选项
    public var layoutOptions: TELayoutOptions = []
    
    /// 文本容器
    public var textContainer: TETextContainer?
    
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
    
    /// 是否启用解析
    public var isParsingEnabled: Bool = false {
        didSet {
            if isParsingEnabled != oldValue {
                updateTextParsing()
            }
        }
    }
    
    /// 占位符文本
    @IBInspectable public var placeholder: String? {
        didSet {
            setNeedsDisplay()
        }
    }
    
    /// 富文本占位符
    public var attributedPlaceholder: NSAttributedString? {
        didSet {
            setNeedsDisplay()
        }
    }
    
    @IBInspectable public var attributedPlaceholderTextProxy: String = "" {
        didSet { rebuildAttributedPlaceholderFromProxy() }
    }
    @IBInspectable public var attributedPlaceholderColorProxy: UIColor = .systemGray3 {
        didSet { rebuildAttributedPlaceholderFromProxy() }
    }
    @IBInspectable public var attributedPlaceholderFontSizeProxy: CGFloat = 16.0 {
        didSet { rebuildAttributedPlaceholderFromProxy() }
    }
    @IBInspectable public var attributedPlaceholderBoldProxy: Bool = false {
        didSet { rebuildAttributedPlaceholderFromProxy() }
    }
    
    /// 占位符颜色
    @IBInspectable public var placeholderColor: UIColor = .systemGray3 {
        didSet {
            setNeedsDisplay()
        }
    }
    
    /// 最大长度限制
    public var maxLength: Int = Int.max {
        didSet {
            if maxLength != oldValue {
                enforceMaxLength()
            }
        }
    }
    
    /// 撤销管理器
    private let undoManager = TEUndoManager()
    
    /// 剪贴板管理器
    private let clipboardManager = TEClipboardManager()
    
    // MARK: - 初始化
    
    public override init(frame: CGRect, textContainer: NSTextContainer?) {
        super.init(frame: frame, textContainer: textContainer)
        setupTextView()
    }
    
    public required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupTextView()
    }
    
    private func setupTextView() {
        // 设置默认属性
        font = UIFont.systemFont(ofSize: 16)
        textColor = .label
        backgroundColor = .systemBackground
        
        // 设置代理
        delegate = self
        
        // 设置高亮管理器
        highlightManager.setupContainerView(self)
        // 将高亮激活状态提供给渲染器
        renderer.highlightStateProvider = { [weak self] range in
            guard let self = self else { return false }
            if self.isCurrentlyEditing && self.disableDecorationsDuringEditing { return false }
            return self.highlightManager.isRangeActive(range)
        }
        renderer.highlightProgressProvider = { [weak self] range in
            guard let self = self else { return 0 }
            if self.isCurrentlyEditing && self.disableDecorationsDuringEditing { return 0 }
            return self.highlightManager.highlightProgress(for: range)
        }
        
        // 设置撤销管理器
        undoManager.delegate = self
        
        // 添加通知监听
        setupNotifications()
        
        // 设置工具栏
        setupInputAccessoryView()
        
        isAccessibilityElement = false
        accessibilityTraits = .staticText
        TETextEngine.shared.logDebug("TETextView 初始化完成", category: "ui")
        setupGestureRecognizers()
        layer.addSublayer(asyncLayer)
        asyncLayer.asyncDelegate = self
        asyncLayer.contentsScale = UIScreen.main.scale
    }
    
    // MARK: - 重写方法
    
    public override var text: String! {
        didSet {
            if Thread.isMainThread {
                if isParsingEnabled {
                    updateTextParsing()
                }
                parseAttachmentsAndHighlights()
                accessibilityLabel = self.text
            } else {
                TETextEngineError.threadSafetyViolation(operation: "set text on TETextView").log(category: "ui")
                DispatchQueue.main.async { [weak self] in
                    guard let self = self else { return }
                    if self.isParsingEnabled {
                        self.updateTextParsing()
                    }
                    self.parseAttachmentsAndHighlights()
                    self.setNeedsDisplay()
                    self.setNeedsLayout()
                    self.accessibilityLabel = self.text
                }
            }
        }
    }
    
    public override var attributedText: NSAttributedString! {
        didSet {
            if Thread.isMainThread {
                parseAttachmentsAndHighlights()
                accessibilityLabel = attributedText?.string
            } else {
                TETextEngineError.threadSafetyViolation(operation: "set attributedText on TETextView").log(category: "ui")
                DispatchQueue.main.async { [weak self] in
                    self?.parseAttachmentsAndHighlights()
                    self?.setNeedsDisplay()
                    self?.setNeedsLayout()
                    self?.accessibilityLabel = self?.attributedText?.string
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
        if enableAsyncRendering {
            asyncLayer.isAsyncEnabled = true
            asyncLayer.setNeedsDisplay()
        } else {
            super.draw(rect)
            if text.isEmpty { drawPlaceholder(in: rect) }
            performSyncRendering(in: rect)
        }
    }
    
    // MARK: - 公共方法
    
    /// 插入文本
    /// - Parameters:
    ///   - text: 要插入的文本
    ///   - at: 插入位置
    public func insertText(_ text: String, at location: Int) {
        guard location >= 0 && location <= self.text.count else { return }
        
        let newText = (self.text as NSString).replacingCharacters(in: NSRange(location: location, length: 0), with: text)
        
        if newText.count <= maxLength {
            undoManager.registerUndo(with: self.text, location: selectedRange.location)
            self.text = newText
            selectedRange = NSRange(location: location + text.count, length: 0)
        }
    }
    
    /// 删除文本
    /// - Parameter range: 要删除的范围
    public func deleteText(in range: NSRange) {
        guard range.location >= 0 && range.location + range.length <= text.count else { return }
        
        let deletedText = (text as NSString).substring(with: range)
        undoManager.registerUndo(with: deletedText, location: range.location, isDeletion: true)
        
        let newText = (text as NSString).replacingCharacters(in: range, with: "")
        self.text = newText
        selectedRange = NSRange(location: range.location, length: 0)
    }
    
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
    
    /// 解析当前文本
    public func parseCurrentText() {
        guard isParsingEnabled, let parser = parser else { return }
        
        let parsedText = parser.parse(text)
        attributedText = parsedText
    }
    
    /// 撤销操作
    public func undo() {
        undoManager.undo()
    }
    
    /// 重做操作
    public func redo() {
        undoManager.redo()
    }
    
    /// 复制选中文本
    public func copySelectedText() {
        guard selectedRange.length > 0 else { return }
        
        let selectedText = plainTextForRange(selectedRange)
        clipboardManager.copyText(selectedText)
        
        TETextEngine.shared.logDebug("复制文本: length=\(selectedText.count)", category: "clipboard")
    }
    
    /// 粘贴剪贴板内容
    public func pasteFromClipboard() {
        guard let pastedText = clipboardManager.pasteText() else { return }
        
        let newText = (text as NSString).replacingCharacters(in: selectedRange, with: pastedText)
        
        if newText.count <= maxLength {
            undoManager.registerUndo(with: text, location: selectedRange.location)
            text = newText
            selectedRange = NSRange(location: selectedRange.location + pastedText.count, length: 0)
            
            TETextEngine.shared.logDebug("粘贴文本: length=\(pastedText.count)", category: "clipboard")
        }
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
    
    /// 设置圆形文本容器
    /// - Parameters:
    ///   - center: 圆心
    ///   - radius: 半径
    public func setCircularTextContainer(center: CGPoint, radius: CGFloat) {
        if textContainer == nil {
            textContainer = TETextContainer()
        }
        textContainer?.setCircularPath(center: center, radius: radius)
        setNeedsLayout()
    }
    
    /// 设置圆角矩形文本容器
    /// - Parameters:
    ///   - rect: 矩形
    ///   - cornerRadius: 圆角半径
    public func setRoundedRectTextContainer(_ rect: CGRect, cornerRadius: CGFloat) {
        if textContainer == nil {
            textContainer = TETextContainer()
        }
        textContainer?.setRoundedRectPath(rect, cornerRadius: cornerRadius)
        setNeedsLayout()
    }
    
    /// 设置贝塞尔曲线文本容器
    /// - Parameter bezierPath: 贝塞尔路径
    #if canImport(UIKit)
    public func setBezierTextContainer(_ bezierPath: UIBezierPath) {
        if textContainer == nil {
            textContainer = TETextContainer()
        }
        textContainer?.setBezierPath(bezierPath)
        setNeedsLayout()
    }
    #elseif canImport(AppKit)
    public func setBezierTextContainer(_ bezierPath: NSBezierPath) {
        if textContainer == nil {
            textContainer = TETextContainer()
        }
        textContainer?.setBezierPath(bezierPath)
        setNeedsLayout()
    }
    #endif
    
    /// 添加排除路径
    /// - Parameter path: 排除路径
    public func addExclusionPath(_ path: CGPath) {
        if textContainer == nil {
            textContainer = TETextContainer()
        }
        textContainer?.addExclusionPath(path)
        setNeedsLayout()
    }
    
    /// 清除所有排除路径
    public func clearExclusionPaths() {
        textContainer?.clearExclusionPaths()
        setNeedsLayout()
    }
    
    /// 重置为默认矩形文本容器
    public func resetToDefaultTextContainer() {
        textContainer?.resetToDefaultPath()
        setNeedsLayout()
    }
    
    /// 获取文本容器统计信息
    /// - Returns: 统计信息
    public func getTextContainerStatistics() -> TETextContainerStatistics? {
        return textContainer?.getStatistics()
    }
    
    // MARK: - 私有方法
    
    /// 设置通知监听
    private func setupNotifications() {
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(textDidChange),
            name: UITextViewTextDidChangeNotification,
            object: self
        )
        
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(textDidBeginEditing),
            name: UITextViewTextDidBeginEditingNotification,
            object: self
        )
        
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(textDidEndEditing),
            name: UITextViewTextDidEndEditingNotification,
            object: self
        )
    }
    
    /// 设置输入工具栏
    private func setupInputAccessoryView() {
        let toolbar = UIToolbar(frame: CGRect(x: 0, y: 0, width: UIScreen.main.bounds.width, height: 44))
        
        let undoButton = UIBarButtonItem(title: "撤销", style: .plain, target: self, action: #selector(undo))
        let redoButton = UIBarButtonItem(title: "重做", style: .plain, target: self, action: #selector(redo))
        let flexibleSpace = UIBarButtonItem(barButtonSystemItem: .flexibleSpace, target: nil, action: nil)
        let doneButton = UIBarButtonItem(barButtonSystemItem: .done, target: self, action: #selector(resignFirstResponder))
        
        toolbar.items = [undoButton, redoButton, flexibleSpace, doneButton]
        inputAccessoryView = toolbar
    }

    @IBInspectable public var customKeyboardEnabled: Bool = false {
        didSet {
            if customKeyboardEnabled {
                inputView = customInputView
            } else {
                inputView = nil
            }
            reloadInputViews()
        }
    }

    public var customInputView: UIView? {
        didSet {
            if customKeyboardEnabled { inputView = customInputView; reloadInputViews() }
        }
    }
    
    /// 更新文本解析
    private func updateTextParsing() {
        guard isParsingEnabled, let parser = parser else { return }
        
        let parsedText = parser.parse(text)
        attributedText = parsedText
    }
    
    /// 解析附件和高亮
    private func parseAttachmentsAndHighlights() {
        guard let attributedText = attributedText else { return }
        
        attributedText.enumerateAttributes(in: NSRange(location: 0, length: attributedText.length), options: []) { attributes, range, _ in
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
    
    /// 强制执行最大长度限制
    private func enforceMaxLength() {
        guard text.count > maxLength else { return }
        
        let truncatedText = String(text.prefix(maxLength))
        text = truncatedText
        
        TETextEngine.shared.logWarning("文本长度超过限制，已截断到 \(maxLength) 字符", category: "ui")
    }
    
    /// 绘制占位符
    /// - Parameter rect: 绘制矩形
    private func drawPlaceholder(in rect: CGRect) {
        guard text.isEmpty else { return }
        let placeholderRect = CGRect(
            x: textContainerInset.left + 5,
            y: textContainerInset.top,
            width: rect.width - textContainerInset.left - textContainerInset.right - 10,
            height: rect.height - textContainerInset.top - textContainerInset.bottom
        )
        if let attributed = attributedPlaceholder, attributed.length > 0 {
            attributed.draw(in: placeholderRect)
            return
        }
        guard let placeholder = placeholder, !placeholder.isEmpty else { return }
        
        let placeholderAttributes: [NSAttributedString.Key: Any] = [
            .font: font ?? UIFont.systemFont(ofSize: 16),
            .foregroundColor: placeholderColor
        ]
        
        placeholder.draw(in: placeholderRect, withAttributes: placeholderAttributes)
    }
    
    private func rebuildAttributedPlaceholderFromProxy() {
        if attributedPlaceholderTextProxy.isEmpty {
            attributedPlaceholder = nil
            return
        }
        let f: UIFont = attributedPlaceholderBoldProxy ? UIFont.boldSystemFont(ofSize: attributedPlaceholderFontSizeProxy) : UIFont.systemFont(ofSize: attributedPlaceholderFontSizeProxy)
        let attr: [NSAttributedString.Key: Any] = [
            .font: f,
            .foregroundColor: attributedPlaceholderColorProxy
        ]
        attributedPlaceholder = NSAttributedString(string: attributedPlaceholderTextProxy, attributes: attr)
    }
    
    /// 执行同步布局
    private func performSyncLayout() {
        guard let attributedText = attributedText else { return }
        
        let layoutInfo: TELayoutInfo
        if let container = textContainer {
            layoutInfo = layoutManager.layoutSynchronously(attributedText, container: container, options: layoutOptions)
        } else {
            layoutInfo = layoutManager.layoutSynchronously(attributedText, size: bounds.size, options: layoutOptions)
        }
        lastLayoutInfo = layoutInfo
        rebuildAccessibilityElements(layoutInfo: layoutInfo)
        
        TETextEngine.shared.logDebug("执行同步布局: size=\(bounds.size), lines=\(layoutInfo.lineCount)", category: "ui")
    }
    
    /// 执行异步布局
    private func performAsyncLayout() {
        guard let attributedText = attributedText else { return }
        
        if let container = textContainer {
            layoutManager.layoutAsynchronously(attributedText, container: container, options: layoutOptions) { [weak self] layoutInfo in
                guard let self = self else { return }
                
                DispatchQueue.main.async {
                    TETextEngine.shared.logDebug("执行异步布局完成: size=\(self.bounds.size), lines=\(layoutInfo.lineCount)", category: "ui")
                    self.lastLayoutInfo = layoutInfo
                    self.rebuildAccessibilityElements(layoutInfo: layoutInfo)
                }
            }
        } else {
            layoutManager.layoutAsynchronously(attributedText, size: bounds.size, options: layoutOptions) { [weak self] layoutInfo in
                guard let self = self else { return }
                
                DispatchQueue.main.async {
                    TETextEngine.shared.logDebug("执行异步布局完成: size=\(self.bounds.size), lines=\(layoutInfo.lineCount)", category: "ui")
                    self.lastLayoutInfo = layoutInfo
                    self.rebuildAccessibilityElements(layoutInfo: layoutInfo)
                }
            }
        }
    }

    private func rebuildAccessibilityElements(layoutInfo: TELayoutInfo) {
        guard let attributed = attributedText else { return }
        var elements: [UIAccessibilityElement] = []
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
        attributed.enumerateAttribute(NSAttributedString.Key.link, in: NSRange(location: 0, length: attributed.length), options: []) { value, range, _ in
            let url: Foundation.URL?
            if let v = value as? Foundation.URL { url = v }
            else if let s = value as? String { url = Foundation.URL(string: s) }
            else { url = nil }
            guard let u = url else { return }
            let rect = TETextHighlight().boundingRect(for: range, in: attributed, textRect: bounds, layoutInfo: layoutInfo)
            let linkElem = TEAccessibilityLinkElement(accessibilityContainer: self, url: u, copyText: (attributed.string as NSString).substring(with: range))
            linkElem.accessibilityTraits = [.link]
            linkElem.accessibilityLabel = (attributed.string as NSString).substring(with: range)
            linkElem.accessibilityFrameInContainerSpace = rect
            linkElem.onOpen = { [weak self] u in self?.onLinkOpen?(u) }
            linkElem.onCopy = { [weak self] s in self?.onCopy?(s) }
            elements.append(linkElem)
        }
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
        guard let attributed = attributedText, let info = lastLayoutInfo else { return }
        for (i, line) in info.lines.enumerated() {
            let origin = info.lineOrigins[i]
            let cfRuns = CTLineGetGlyphRuns(line)
            let runs = (cfRuns as NSArray as? [CTRun]) ?? []
            for run in runs {
                let rr = CTRunGetStringRange(run)
                let loc = rr.location
                if let attachment = attributed.attribute(TEAttributeKey.textAttachment, at: loc, effectiveRange: nil) as? TETextAttachment {
                    var ascent: CGFloat = 0
                    var descent: CGFloat = 0
                    var leading: CGFloat = 0
                    _ = CTRunGetTypographicBounds(run, CFRange(location: 0, length: 0), &ascent, &descent, &leading)
                    let offset = CTLineGetOffsetForStringIndex(line, rr.location, nil)
                    let height = max(attachment.size.height, ascent + descent)
                    var y = origin.y - descent
                    switch attachment.verticalAlignment {
                    case .top:
                        y = origin.y + (ascent - attachment.size.height)
                    case .center:
                        y = y + (ascent + descent - attachment.size.height) / 2
                    case .bottom:
                        break
                    }
                    y += attachment.baselineOffset
                    let drawRect = CGRect(x: origin.x + CGFloat(offset), y: y, width: attachment.size.width, height: height)
                    attachment.draw(in: context, rect: drawRect, containerView: self)
                }
            }
        }
    }

    

    

    private func setupGestureRecognizers() {
        let tap = UITapGestureRecognizer(target: self, action: #selector(handleTap(_:)))
        addGestureRecognizer(tap)
        let longPress = UILongPressGestureRecognizer(target: self, action: #selector(handleLongPress(_:)))
        longPress.minimumPressDuration = 0.5
        addGestureRecognizer(longPress)
    }

    @objc private func handleTap(_ gesture: UITapGestureRecognizer) {
        guard let attributed = attributedText else { return }
        let point = gesture.location(in: self)
        let handled = highlightManager.handleTap(at: point, in: attributed, textRect: bounds, layoutInfo: lastLayoutInfo)
        if handled { return }
        let index = highlightManager.characterIndex(at: point, in: attributed, textRect: bounds, layoutInfo: lastLayoutInfo)
        guard index != NSNotFound else { return }
        var effective = NSRange(location: 0, length: 0)
        let value = attributed.attribute(.link, at: index, effectiveRange: &effective)
        let url: URL? = {
            if let u = value as? URL { return u }
            if let s = value as? String { return URL(string: s) }
            return nil
        }()
        if let u = url { onLinkOpen?(u) }
    }

    @objc private func handleLongPress(_ gesture: UILongPressGestureRecognizer) {
        guard gesture.state == .began, let attributed = attributedText else { return }
        let point = gesture.location(in: self)
        let handled = highlightManager.handleLongPress(at: point, in: attributed, textRect: bounds, layoutInfo: lastLayoutInfo)
        if handled { return }
        let index = highlightManager.characterIndex(at: point, in: attributed, textRect: bounds, layoutInfo: lastLayoutInfo)
        guard index != NSNotFound else { return }
        var effective = NSRange(location: 0, length: 0)
        let value = attributed.attribute(.link, at: index, effectiveRange: &effective)
        let url: URL? = {
            if let u = value as? URL { return u }
            if let s = value as? String { return URL(string: s) }
            return nil
        }()
        if let u = url {
            onLinkOpen?(u)
        } else {
            let text = (attributed.string as NSString).substring(with: effective)
            onCopy?(text)
        }
    }

    
    
    // MARK: - 通知处理方法
    
    @objc private func textDidChange() {
        enforceMaxLength()
        
        if isParsingEnabled {
            updateTextParsing()
        }
        
        TETextEngine.shared.logDebug("文本内容已更改", category: "ui")
    }
    
    @objc private func textDidBeginEditing() {
        isCurrentlyEditing = true
        switch editingAsyncDegradePolicy {
        case .none:
            if autoDisableAsyncWhenEditing { enableAsyncRendering = false }
        case .disableAsync:
            enableAsyncRendering = false
        case .lowQuality:
            enableAsyncRendering = true
            asyncLayer.renderScale = 0.5
        case .forceSync:
            enableAsyncRendering = false
        }
        TETextEngine.shared.logDebug("开始编辑文本", category: "ui")
    }
    
    @objc private func textDidEndEditing() {
        isCurrentlyEditing = false
        asyncLayer.renderScale = 1.0
        if autoDisableAsyncWhenEditing { enableAsyncRendering = true }
        TETextEngine.shared.logDebug("结束编辑文本", category: "ui")
    }
}

extension TETextView: TEAsyncLayerDelegate {
    public func draw(in context: CGContext, size: CGSize) {
        let rect = CGRect(origin: .zero, size: size)
        if (attributedText == nil || attributedText?.length == 0) {
            UIGraphicsPushContext(context)
            drawPlaceholder(in: rect)
            UIGraphicsPopContext()
            return
        }
        guard let attributedText = attributedText else { return }
        renderer.renderSynchronously(attributedText, in: context, rect: rect, options: renderOptions)
        drawAttachments(in: context, rect: rect)
    }
}

final class TETextViewAccessibilityLinkElement: UIAccessibilityElement {
    var url: Foundation.URL
    var copyText: String
    var onOpen: ((Foundation.URL) -> Void)?
    var onCopy: ((String) -> Void)?
    init(accessibilityContainer: Any, url: Foundation.URL, copyText: String) {
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

// MARK: - UITextViewDelegate

extension TETextView: UITextViewDelegate {
    
    public func textView(_ textView: UITextView, shouldChangeTextIn range: NSRange, replacementText text: String) -> Bool {
        let currentText = textView.text as NSString
        let newText = currentText.replacingCharacters(in: range, with: text)
        if newText.count > maxLength { return false }
        if text.isEmpty && range.length > 0, let attributed = attributedText {
            var effective = NSRange(location: 0, length: 0)
            if let binding = attributed.attribute(TEAttributeKey.textBinding, at: range.location, effectiveRange: &effective) as? TETextBinding, binding.deleteTogether {
                deleteText(in: effective)
                return false
            }
        }
        return true
    }
    
    public func textViewDidChange(_ textView: UITextView) {
        // 文本更改时更新解析
        if isParsingEnabled {
            updateTextParsing()
        }
    }
}

// MARK: - TEUndoManagerDelegate

extension TETextView: TEUndoManagerDelegate {
    
    func undoManager(_ manager: TEUndoManager, didUndo text: String, at location: Int) {
        self.text = text
        selectedRange = NSRange(location: location, length: 0)
        
        TETextEngine.shared.logDebug("执行撤销操作", category: "undo")
    }
    
    func undoManager(_ manager: TEUndoManager, didRedo text: String, at location: Int) {
        self.text = text
        selectedRange = NSRange(location: location, length: 0)
        
        TETextEngine.shared.logDebug("执行重做操作", category: "undo")
    }
}
#endif
