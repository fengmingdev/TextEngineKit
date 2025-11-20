import Foundation
import CoreGraphics

#if canImport(AppKit)
import AppKit
#endif

/// 文本附件
/// 支持图片、UIView 和 CALayer 作为文本内容
public final class TETextAttachment: NSObject, NSCopying, NSSecureCoding {
    
    // MARK: - 内容类型
    
    /// 附件内容类型
    public enum ContentType {
        case image(TEImage)      // 图片内容
        case view(TEUIView)      // 视图内容
        case layer(TECALayer)    // 图层内容
        case custom(Any)         // 自定义内容
    }
    
    // MARK: - 属性
    
    /// 附件内容
    public var content: ContentType?
    
    /// 内容模式
    public var contentMode: TEContentMode = .scaleToFill
    
    /// 附件大小
    public var size: CGSize = .zero
    
    /// 是否随字体缩放
    public var scalesWithFont: Bool = true
    
    /// 基线偏移
    public var baselineOffset: CGFloat = 0
    
    /// 垂直对齐方式
    public var verticalAlignment: TEVerticalAlignment = .center
    
    /// 点击回调
    public var tapAction: ((TETextAttachment) -> Void)?
    
    /// 长按回调
    public var longPressAction: ((TETextAttachment) -> Void)?
    
    /// 用户信息
    public var userInfo: [String: Any]?
    
    /// 边距
    public var margins: TEUIEdgeInsets = TEUIEdgeInsets(top: 0, left: 0, bottom: 0, right: 0)
    
    /// 圆角半径
    public var cornerRadius: CGFloat = 0
    
    /// 边框
    public var border: TETextBorder?
    
    /// 阴影
    public var shadow: TETextShadow?

    /// 是否由附件自身绘制装饰（边框/阴影/填充），默认关闭，统一由渲染器处理
    public var drawsOwnDecorations: Bool = false
    
    // MARK: - 初始化
    
    public override init() {
        super.init()
    }
    
    /// 便利初始化 - 图片
    public convenience init(image: TEImage?, size: CGSize? = nil) {
        self.init()
        if let image = image {
            self.content = .image(image)
            self.size = size ?? image.size
        }
    }
    
    /// 便利初始化 - 视图
    public convenience init(view: TEUIView, size: CGSize? = nil) {
        self.init()
        self.content = .view(view)
        self.size = size ?? view.bounds.size
    }
    
    /// 便利初始化 - 图层
    public convenience init(layer: TECALayer, size: CGSize? = nil) {
        self.init()
        self.content = .layer(layer)
        self.size = size ?? layer.bounds.size
    }
    
    // MARK: - NSCopying
    
    public func copy(with zone: NSZone? = nil) -> Any {
        let attachment = TETextAttachment()
        attachment.content = content
        attachment.contentMode = contentMode
        attachment.size = size
        attachment.scalesWithFont = scalesWithFont
        attachment.baselineOffset = baselineOffset
        attachment.verticalAlignment = verticalAlignment
        attachment.tapAction = tapAction
        attachment.longPressAction = longPressAction
        attachment.userInfo = userInfo
        attachment.margins = margins
        attachment.cornerRadius = cornerRadius
        attachment.border = border?.copy() as? TETextBorder
        attachment.shadow = shadow?.copy() as? TETextShadow
        return attachment
    }
    
    // MARK: - NSSecureCoding
    
    public static var supportsSecureCoding: Bool { return true }
    
    public func encode(with coder: NSCoder) {
        // 编码内容类型和数据
        if let content = content {
            switch content {
            case .image(let image):
                coder.encode(0, forKey: "contentType")
                coder.encode(image, forKey: "imageContent")
            case .view(let view):
                coder.encode(1, forKey: "contentType")
                // UIView 不能直接编码，记录警告并尝试保存视图信息
                let warningMessage = "UIView 附件内容不支持完整编码，将丢失视图内容。建议转换为图片后再编码。"
                TETextEngine.shared.logWarning(warningMessage, category: "attachment")
                // 尝试保存视图的基本信息用于调试
                coder.encode(view.frame, forKey: "viewFrame")
                coder.encode(String(describing: type(of: view)), forKey: "viewType")
            case .layer(let layer):
                coder.encode(2, forKey: "contentType")
                // CALayer 不能直接编码，记录警告并尝试保存图层信息
                let warningMessage = "CALayer 附件内容不支持完整编码，将丢失图层内容。建议转换为图片后再编码。"
                TETextEngine.shared.logWarning(warningMessage, category: "attachment")
                // 尝试保存图层的基本信息用于调试
                coder.encode(layer.frame, forKey: "layerFrame")
                coder.encode(String(describing: type(of: layer)), forKey: "layerType")
            case .custom(let custom):
                coder.encode(3, forKey: "contentType")
                // 自定义内容需要特殊处理，记录详细警告
                let warningMessage = "自定义附件内容不支持编码，类型: \(String(describing: type(of: custom)))，将丢失内容。"
                TETextEngine.shared.logWarning(warningMessage, category: "attachment")
                // 尝试保存自定义内容的类型信息
                coder.encode(String(describing: type(of: custom)), forKey: "customType")
            }
        } else {
            // 内容为nil时，记录调试信息
            TETextEngine.shared.logDebug("编码附件时内容为nil", category: "attachment")
        }
        
        coder.encode(contentMode.rawValue, forKey: "contentMode")
        coder.encode(NSValue(size: size), forKey: "size")
        coder.encode(scalesWithFont, forKey: "scalesWithFont")
        coder.encode(baselineOffset, forKey: "baselineOffset")
        coder.encode(verticalAlignment.rawValue, forKey: "verticalAlignment")
        #if canImport(UIKit)
        coder.encode(NSValue(uiEdgeInsets: margins), forKey: "margins")
        #elseif canImport(AppKit)
        coder.encode(NSValue(edgeInsets: margins), forKey: "margins")
        #endif
        coder.encode(cornerRadius, forKey: "cornerRadius")
        coder.encode(border, forKey: "border")
        coder.encode(shadow, forKey: "shadow")
        
        // 编码附加信息用于调试
        coder.encode(Date(), forKey: "encodeTimestamp")
        TETextEngine.shared.logDebug("附件编码完成，内容类型: \(content != nil ? String(describing: content!) : "nil")", category: "attachment")
    }
    
    public required init?(coder: NSCoder) {
        super.init()
        
        // 解码时间戳用于调试
        if let timestamp = coder.decodeObject(of: NSDate.self, forKey: "encodeTimestamp") {
            TETextEngine.shared.logDebug("开始解码附件，编码时间: \(timestamp)", category: "attachment")
        }
        
        // 解码内容
        let contentType = coder.decodeInteger(forKey: "contentType")
        switch contentType {
        case 0:
            if let image = coder.decodeObject(of: TEImage.self, forKey: "imageContent") {
                self.content = .image(image)
                TETextEngine.shared.logDebug("成功解码图片附件", category: "attachment")
            } else {
                TETextEngine.shared.logWarning("解码图片附件失败，图片数据可能损坏", category: "attachment")
            }
        case 1:
            let warningMessage = "UIView 附件内容不支持解码，视图内容将丢失。"
            TETextEngine.shared.logWarning(warningMessage, category: "attachment")
            // 尝试读取调试信息
            if let viewFrameValue = coder.decodeObject(of: NSValue.self, forKey: "viewFrame"),
               let viewType = coder.decodeObject(of: NSString.self, forKey: "viewType") {
                #if canImport(UIKit)
                let viewFrame = viewFrameValue.cgRectValue
                #elseif canImport(AppKit)
                let viewFrame = viewFrameValue.rectValue
                #endif
                TETextEngine.shared.logDebug("原始视图信息 - 类型: \(viewType), 框架: origin(\(viewFrame.origin.x), \(viewFrame.origin.y)) size(\(viewFrame.size.width), \(viewFrame.size.height))", category: "attachment")
            }
        case 2:
            let warningMessage = "CALayer 附件内容不支持解码，图层内容将丢失。"
            TETextEngine.shared.logWarning(warningMessage, category: "attachment")
            // 尝试读取调试信息
            if let layerFrameValue = coder.decodeObject(of: NSValue.self, forKey: "layerFrame"),
               let layerType = coder.decodeObject(of: NSString.self, forKey: "layerType") {
                #if canImport(UIKit)
                let layerFrame = layerFrameValue.cgRectValue
                #elseif canImport(AppKit)
                let layerFrame = layerFrameValue.rectValue
                #endif
                TETextEngine.shared.logDebug("原始图层信息 - 类型: \(layerType), 框架: origin(\(layerFrame.origin.x), \(layerFrame.origin.y)) size(\(layerFrame.size.width), \(layerFrame.size.height))", category: "attachment")
            }
        case 3:
            let warningMessage = "自定义附件内容不支持解码，自定义内容将丢失。"
            TETextEngine.shared.logWarning(warningMessage, category: "attachment")
            // 尝试读取调试信息
            if let customType = coder.decodeObject(of: NSString.self, forKey: "customType") {
                TETextEngine.shared.logDebug("原始自定义内容类型: \(customType)", category: "attachment")
            }
        default:
            TETextEngine.shared.logDebug("解码附件时遇到未知内容类型: \(contentType)", category: "attachment")
        }
        
        // 解码基本属性
        contentMode = TEContentMode(rawValue: coder.decodeInteger(forKey: "contentMode")) ?? .scaleToFill
        if let sizeValue = coder.decodeObject(of: NSValue.self, forKey: "size") {
            size = CGSize(width: sizeValue.sizeValue.width, height: sizeValue.sizeValue.height)
        } else {
            TETextEngine.shared.logWarning("解码附件大小时失败，使用默认大小", category: "attachment")
            size = CGSize(width: 20, height: 20) // 默认大小
        }
        scalesWithFont = coder.decodeBool(forKey: "scalesWithFont")
        baselineOffset = CGFloat(coder.decodeDouble(forKey: "baselineOffset"))
        verticalAlignment = TEVerticalAlignment(rawValue: coder.decodeInteger(forKey: "verticalAlignment")) ?? .center
        
        if let marginsValue = coder.decodeObject(of: NSValue.self, forKey: "margins") {
            let edgeInsets = marginsValue.edgeInsetsValue
            #if canImport(UIKit)
            margins = UIEdgeInsets(top: edgeInsets.top, left: edgeInsets.left, bottom: edgeInsets.bottom, right: edgeInsets.right)
            #elseif canImport(AppKit)
            margins = NSEdgeInsets(top: edgeInsets.top, left: edgeInsets.left, bottom: edgeInsets.bottom, right: edgeInsets.right)
            #endif
        }
        
        cornerRadius = CGFloat(coder.decodeDouble(forKey: "cornerRadius"))
        border = coder.decodeObject(of: TETextBorder.self, forKey: "border")
        shadow = coder.decodeObject(of: TETextShadow.self, forKey: "shadow")
        
        TETextEngine.shared.logDebug("附件解码完成，内容类型: \(content != nil ? String(describing: content!) : "nil")", category: "attachment")
    }
    
    // MARK: - 公共方法
    
    /// 获取图片内容
    /// - Returns: 图片或 nil
    public func imageContent() -> TEImage? {
        guard case .image(let image) = content else { return nil }
        return image
    }
    
    /// 获取视图内容
    /// - Returns: 视图或 nil
    public func viewContent() -> TEUIView? {
        guard case .view(let view) = content else { return nil }
        return view
    }
    
    /// 获取图层内容
    /// - Returns: 图层或 nil
    public func layerContent() -> TECALayer? {
        guard case .layer(let layer) = content else { return nil }
        return layer
    }
    
    /// 绘制附件
    /// - Parameters:
    ///   - context: 图形上下文
    ///   - rect: 绘制矩形
    ///   - containerView: 容器视图
    func draw(in context: CGContext, rect: CGRect, containerView: TEUIView? = nil) {
        context.saveGState()
        
        // 应用边距
        let drawRect = CGRect(
            x: rect.origin.x + margins.left,
            y: rect.origin.y + margins.top,
            width: rect.size.width - margins.left - margins.right,
            height: rect.size.height - margins.top - margins.bottom
        )
        
        // 应用圆角
        if cornerRadius > 0 {
            #if canImport(UIKit)
            let path = UIBezierPath(roundedRect: drawRect, cornerRadius: cornerRadius)
            context.addPath(path.cgPath)
            context.clip()
            #elseif canImport(AppKit)
            let path = NSBezierPath(roundedRect: drawRect, xRadius: cornerRadius, yRadius: cornerRadius)
            context.saveGState()
            path.setClip()
            context.restoreGState()
            #endif
        }
        
        // 可选：附件自身绘制装饰（如启用）
        if drawsOwnDecorations {
            if let shadow = shadow {
                context.setShadow(offset: shadow.offset, blur: shadow.radius, color: shadow.color?.cgColor)
            }
            if let border = border {
                border.draw(in: context, rect: drawRect, lineOrigin: drawRect.origin, lineAscent: drawRect.height, lineDescent: 0, lineHeight: drawRect.height)
            }
        }
        
        // 绘制内容
        drawContent(in: context, rect: drawRect, containerView: containerView)
        
        context.restoreGState()
    }
    
    /// 绘制内容
    /// - Parameters:
    ///   - context: 图形上下文
    ///   - rect: 绘制矩形
    ///   - containerView: 容器视图
    private func drawContent(in context: CGContext, rect: CGRect, containerView: TEUIView?) {
        guard let content = content else { return }
        
        switch content {
        case .image(let image):
            drawImage(image, in: context, rect: rect)
        case .view(let view):
            drawView(view, in: context, rect: rect, containerView: containerView)
        case .layer(let layer):
            drawLayer(layer, in: context, rect: rect)
        case .custom(let custom):
            drawCustom(custom, in: context, rect: rect)
        }
    }
    
    /// 绘制图片
    /// - Parameters:
    ///   - image: 图片
    ///   - context: 图形上下文
    ///   - rect: 绘制矩形
    private func drawImage(_ image: TEImage, in context: CGContext, rect: CGRect) {
        #if canImport(UIKit)
        guard let cgImage = image.cgImage else { return }
        #elseif canImport(AppKit)
        guard let cgImage = image.cgImage(forProposedRect: nil, context: nil, hints: nil) else { return }
        #endif
        
        let drawRect = calculateDrawRect(for: image.size, in: rect)
        context.draw(cgImage, in: drawRect)
    }
    
    /// 绘制视图
    /// - Parameters:
    ///   - view: 视图
    ///   - context: 图形上下文
    ///   - rect: 绘制矩形
    ///   - containerView: 容器视图
    private func drawView(_ view: TEUIView, in context: CGContext, rect: CGRect, containerView: TEUIView?) {
        // 临时将视图添加到容器以便渲染
        if containerView != nil {
            let tempView = TEUIView(frame: rect)
            tempView.addSubview(view)
            view.frame = CGRect(origin: .zero, size: rect.size)
            
            // 渲染视图到上下文
            #if canImport(UIKit)
            tempView.layer.render(in: context)
            #elseif canImport(AppKit)
            tempView.layer?.render(in: context)
            #endif
            
            view.removeFromSuperview()
        }
    }
    
    /// 绘制图层
    /// - Parameters:
    ///   - layer: 图层
    ///   - context: 图形上下文
    ///   - rect: 绘制矩形
    private func drawLayer(_ layer: TECALayer, in context: CGContext, rect: CGRect) {
        layer.render(in: context)
    }
    
    /// 绘制自定义内容
    /// - Parameters:
    ///   - custom: 自定义内容
    ///   - context: 图形上下文
    ///   - rect: 绘制矩形
    private func drawCustom(_ custom: Any, in context: CGContext, rect: CGRect) {
        // 自定义内容的绘制逻辑需要具体实现
        TETextEngine.shared.logWarning("自定义附件内容绘制未实现", category: "attachment")
    }
    
    /// 计算绘制矩形
    /// - Parameters:
    ///   - contentSize: 内容尺寸
    ///   - rect: 目标矩形
    /// - Returns: 计算后的绘制矩形
    private func calculateDrawRect(for contentSize: CGSize, in rect: CGRect) -> CGRect {
        switch contentMode {
        case .scaleToFill:
            return rect
        case .scaleAspectFit:
            let scale = min(rect.width / contentSize.width, rect.height / contentSize.height)
            let newSize = CGSize(width: contentSize.width * scale, height: contentSize.height * scale)
            let origin = CGPoint(x: rect.midX - newSize.width / 2, y: rect.midY - newSize.height / 2)
            return CGRect(origin: origin, size: newSize)
        case .scaleAspectFill:
            let scale = max(rect.width / contentSize.width, rect.height / contentSize.height)
            let newSize = CGSize(width: contentSize.width * scale, height: contentSize.height * scale)
            let origin = CGPoint(x: rect.midX - newSize.width / 2, y: rect.midY - newSize.height / 2)
            return CGRect(origin: origin, size: newSize)
        case .center:
            let origin = CGPoint(x: rect.midX - contentSize.width / 2, y: rect.midY - contentSize.height / 2)
            return CGRect(origin: origin, size: contentSize)
        case .top:
            let origin = CGPoint(x: rect.midX - contentSize.width / 2, y: rect.minY)
            return CGRect(origin: origin, size: contentSize)
        case .bottom:
            let origin = CGPoint(x: rect.midX - contentSize.width / 2, y: rect.maxY - contentSize.height)
            return CGRect(origin: origin, size: contentSize)
        case .left:
            let origin = CGPoint(x: rect.minX, y: rect.midY - contentSize.height / 2)
            return CGRect(origin: origin, size: contentSize)
        case .right:
            let origin = CGPoint(x: rect.maxX - contentSize.width, y: rect.midY - contentSize.height / 2)
            return CGRect(origin: origin, size: contentSize)
        case .topLeft:
            return CGRect(origin: rect.origin, size: contentSize)
        case .topRight:
            let origin = CGPoint(x: rect.maxX - contentSize.width, y: rect.minY)
            return CGRect(origin: origin, size: contentSize)
        case .bottomLeft:
            let origin = CGPoint(x: rect.minX, y: rect.maxY - contentSize.height)
            return CGRect(origin: origin, size: contentSize)
        case .bottomRight:
            let origin = CGPoint(x: rect.maxX - contentSize.width, y: rect.maxY - contentSize.height)
            return CGRect(origin: origin, size: contentSize)
        @unknown default:
            return rect
        }
    }
}

// MARK: - 垂直对齐方式

/// 垂直对齐方式
public enum TEVerticalAlignment: Int {
    case top = 0        // 顶部对齐
    case center = 1     // 居中对齐
    case bottom = 2     // 底部对齐
}

// MARK: - 附件管理器

/// 文本附件管理器
/// 管理文本中的附件内容
public final class TEAttachmentManager {
    
    // MARK: - 属性
    
    /// 附件数组
    private var attachments: [TETextAttachment] = []
    
    /// 附件映射（按位置索引）
    private var attachmentMap: [Int: TETextAttachment] = [:]
    
    /// 线程安全锁
    private let lock = NSLock()
    private var countLimit: Int = 200
    
    // MARK: - 初始化
    
    public init() {
        TETextEngine.shared.logDebug("附件管理器初始化完成", category: "attachment")
    }
    
    // MARK: - 公共方法
    
    /// 添加附件
    /// - Parameters:
    ///   - attachment: 附件
    ///   - at: 位置
    public func addAttachment(_ attachment: TETextAttachment, at location: Int) {
        lock.lock()
        defer { lock.unlock() }
        
        if attachments.count >= countLimit {
            let removed = attachments.removeFirst()
            // 从映射移除第一个出现的位置
            if let index = attachmentMap.firstIndex(where: { $0.value === removed }) {
                attachmentMap.remove(at: index)
            }
            TETextEngine.shared.logWarning("附件数量达到上限，已逐出最早的一个", category: "attachment")
        }
        attachments.append(attachment)
        attachmentMap[location] = attachment
        
        TETextEngine.shared.logDebug("添加附件: location=\(location), attachment=\(attachment)", category: "attachment")
    }
    
    /// 移除附件
    /// - Parameter location: 位置
    public func removeAttachment(at location: Int) {
        lock.lock()
        defer { lock.unlock() }
        
        if let attachment = attachmentMap[location] {
            attachments.removeAll { $0 === attachment }
            attachmentMap.removeValue(forKey: location)
            
            TETextEngine.shared.logDebug("移除附件: location=\(location)", category: "attachment")
        }
    }
    
    /// 获取指定位置的附件
    /// - Parameter location: 位置
    /// - Returns: 附件或 nil
    public func attachment(at location: Int) -> TETextAttachment? {
        lock.lock()
        defer { lock.unlock() }
        
        return attachmentMap[location]
    }
    
    /// 获取所有附件
    /// - Returns: 附件数组
    public func allAttachments() -> [TETextAttachment] {
        lock.lock()
        defer { lock.unlock() }
        
        return attachments
    }
    
    /// 清除所有附件
    public func clearAttachments() {
        lock.lock()
        defer { lock.unlock() }
        
        attachments.removeAll()
        attachmentMap.removeAll()
        
        TETextEngine.shared.logDebug("清除所有附件", category: "attachment")
    }
    
    /// 获取附件数量
    /// - Returns: 附件数量
    public func attachmentCount() -> Int {
        lock.lock()
        defer { lock.unlock() }
        
        return attachments.count
    }

    /// 更新附件数量上限
    public func updateCountLimit(_ limit: Int) {
        lock.lock(); countLimit = max(1, limit); lock.unlock()
        TETextEngine.shared.logDebug("附件数量上限更新为: \(countLimit)", category: "attachment")
    }
}
