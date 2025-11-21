// 
//  TEAttributeKey.swift 
//  TextEngineKit 
// 
//  Created by fengming on 2025/11/17. 
// 
//  富文本属性键：定义跨平台属性键与适配，统一富文本样式使用。 
// 
import Foundation
import CoreText
import CoreGraphics

/// 富文本属性键
/// 扩展的 CoreText 属性键
public struct TEAttributeKey {
    
    // MARK: - CoreText 标准属性
    
    /// 字体
    public static let font = NSAttributedString.Key("TEFontAttribute")
    
    /// 前景色
    public static let foregroundColor = NSAttributedString.Key("TEForegroundColorAttribute")
    
    /// 背景色
    public static let backgroundColor = NSAttributedString.Key("TEBackgroundColorAttribute")
    
    /// 字距
    public static let kern = NSAttributedString.Key("TEKernAttribute")
    
    /// 删除线
    public static let strikethroughStyle = NSAttributedString.Key("TEStrikethroughStyleAttribute")
    
    /// 删除线颜色
    public static let strikethroughColor = NSAttributedString.Key("TEStrikethroughColorAttribute")
    
    /// 下划线
    public static let underlineStyle = NSAttributedString.Key("TEUnderlineStyleAttribute")
    
    /// 下划线颜色
    public static let underlineColor = NSAttributedString.Key("TEUnderlineColorAttribute")
    
    /// 描边宽度
    public static let strokeWidth = NSAttributedString.Key("TEStrokeWidthAttribute")
    
    /// 描边颜色
    public static let strokeColor = NSAttributedString.Key("TEStrokeColorAttribute")
    
    /// 阴影
    public static let shadow = NSAttributedString.Key("TEShadowAttribute")
    
    /// 段落样式
    public static let paragraphStyle = NSAttributedString.Key("TEParagraphStyleAttribute")
    
    // MARK: - TextEngineKit 扩展属性
    
    /// 文本边框
    public static let textBorder = NSAttributedString.Key("TETextBorderAttribute")
    
    /// 文本背景边框
    public static let textBackgroundBorder = NSAttributedString.Key("TETextBackgroundBorderAttribute")
    
    /// 文本阴影
    public static let textShadow = NSAttributedString.Key("TETextShadowAttribute")
    
    /// 文本内阴影
    public static let textInnerShadow = NSAttributedString.Key("TETextInnerShadowAttribute")
    
    /// 文本附件
    public static let textAttachment = NSAttributedString.Key("TETextAttachmentAttribute")
    
    /// 文本高亮
    public static let textHighlight = NSAttributedString.Key("TETextHighlightAttribute")
    
    /// 文本绑定
    public static let textBinding = NSAttributedString.Key("TETextBindingAttribute")
    
    /// 文本装饰线
    public static let textDecoration = NSAttributedString.Key("TETextDecorationAttribute")
    
    /// 字形变换
    public static let glyphTransform = NSAttributedString.Key("TEGlyphTransformAttribute")
    
    /// 文本块边框
    public static let textBlockBorder = NSAttributedString.Key("TETextBlockBorderAttribute")
    
    /// 文本后备字符串
    public static let textBackedString = NSAttributedString.Key("TETextBackedStringAttribute")
    
    /// 运行代理
    public static let runDelegate = NSAttributedString.Key("TERunDelegateAttribute")
    
    /// 垂直字形格式
    public static let verticalGlyphForm = NSAttributedString.Key("TEVerticalGlyphFormAttribute")
    
    /// 书写方向
    public static let writingDirection = NSAttributedString.Key("TEWritingDirectionAttribute")
}

// MARK: - 属性字符串扩展

public extension NSAttributedString {
    
    /// 获取字体属性
    var te_font: TEFont? {
        return attribute(TEAttributeKey.font, at: 0, effectiveRange: nil) as? TEFont
    }
    
    /// 获取前景色
    var te_foregroundColor: TEColor? {
        return attribute(TEAttributeKey.foregroundColor, at: 0, effectiveRange: nil) as? TEColor
    }
    
    /// 获取背景色
    var te_backgroundColor: TEColor? {
        return attribute(TEAttributeKey.backgroundColor, at: 0, effectiveRange: nil) as? TEColor
    }
    
    /// 获取文本边框
    var te_textBorder: TETextBorder? {
        return attribute(TEAttributeKey.textBorder, at: 0, effectiveRange: nil) as? TETextBorder
    }
    
    /// 获取文本阴影
    var te_textShadow: TETextShadow? {
        return attribute(TEAttributeKey.textShadow, at: 0, effectiveRange: nil) as? TETextShadow
    }
    
    /// 获取文本附件
    var te_textAttachment: TETextAttachment? {
        return attribute(TEAttributeKey.textAttachment, at: 0, effectiveRange: nil) as? TETextAttachment
    }
    
    /// 获取文本高亮
    var te_textHighlight: TETextHighlight? {
        return attribute(TEAttributeKey.textHighlight, at: 0, effectiveRange: nil) as? TETextHighlight
    }
}

public extension NSMutableAttributedString {
    
    /// 设置字体
    func setTe_font(_ font: TEFont?) {
        if let font = font {
            addAttribute(TEAttributeKey.font, value: font, range: NSRange(location: 0, length: length))
        } else {
            removeAttribute(TEAttributeKey.font, range: NSRange(location: 0, length: length))
        }
    }
    
    /// 获取字体
    func getTe_font() -> TEFont? {
        return attribute(TEAttributeKey.font, at: 0, effectiveRange: nil) as? TEFont
    }
    
    /// 设置前景色
    func setTe_foregroundColor(_ color: TEColor?) {
        if let color = color {
            addAttribute(TEAttributeKey.foregroundColor, value: color, range: NSRange(location: 0, length: length))
        } else {
            removeAttribute(TEAttributeKey.foregroundColor, range: NSRange(location: 0, length: length))
        }
    }
    
    /// 获取前景色
    func getTe_foregroundColor() -> TEColor? {
        return attribute(TEAttributeKey.foregroundColor, at: 0, effectiveRange: nil) as? TEColor
    }
    
    /// 设置背景色
    func setTe_backgroundColor(_ color: TEColor?) {
        if let color = color {
            addAttribute(TEAttributeKey.backgroundColor, value: color, range: NSRange(location: 0, length: length))
        } else {
            removeAttribute(TEAttributeKey.backgroundColor, range: NSRange(location: 0, length: length))
        }
    }
    
    /// 获取背景色
    func getTe_backgroundColor() -> TEColor? {
        return attribute(TEAttributeKey.backgroundColor, at: 0, effectiveRange: nil) as? TEColor
    }
    
    /// 设置文本边框
    func setTe_textBorder(_ border: TETextBorder?) {
        if let border = border {
            addAttribute(TEAttributeKey.textBorder, value: border, range: NSRange(location: 0, length: length))
        } else {
            removeAttribute(TEAttributeKey.textBorder, range: NSRange(location: 0, length: length))
        }
    }
    
    /// 获取文本边框
    func getTe_textBorder() -> TETextBorder? {
        return attribute(TEAttributeKey.textBorder, at: 0, effectiveRange: nil) as? TETextBorder
    }
    
    /// 设置文本阴影
    func setTe_textShadow(_ shadow: TETextShadow?) {
        if let shadow = shadow {
            addAttribute(TEAttributeKey.textShadow, value: shadow, range: NSRange(location: 0, length: length))
        } else {
            removeAttribute(TEAttributeKey.textShadow, range: NSRange(location: 0, length: length))
        }
    }
    
    /// 获取文本阴影
    func getTe_textShadow() -> TETextShadow? {
        return attribute(TEAttributeKey.textShadow, at: 0, effectiveRange: nil) as? TETextShadow
    }
    
    /// 设置文本高亮
    func setTe_textHighlight(_ highlight: TETextHighlight?) {
        if let highlight = highlight {
            addAttribute(TEAttributeKey.textHighlight, value: highlight, range: NSRange(location: 0, length: length))
        } else {
            removeAttribute(TEAttributeKey.textHighlight, range: NSRange(location: 0, length: length))
        }
    }
    
    /// 获取文本高亮
    func getTe_textHighlight() -> TETextHighlight? {
        return attribute(TEAttributeKey.textHighlight, at: 0, effectiveRange: nil) as? TETextHighlight
    }
    
    /// 设置属性到指定范围
    /// - Parameters:
    ///   - key: 属性键
    ///   - value: 属性值
    ///   - range: 范围
    func te_setAttribute(_ key: NSAttributedString.Key, value: Any, range: NSRange) {
        addAttribute(key, value: value, range: range)
    }
    
    /// 移除指定范围的属性
    /// - Parameters:
    ///   - key: 属性键
    ///   - range: 范围
    func te_removeAttribute(_ key: NSAttributedString.Key, range: NSRange) {
        removeAttribute(key, range: range)
    }
    
    /// 设置文本边框到指定范围
    /// - Parameters:
    ///   - border: 文本边框
    ///   - range: 范围
    func te_setTextBorder(_ border: TETextBorder, range: NSRange) {
        addAttribute(TEAttributeKey.textBorder, value: border, range: range)
    }
    
    /// 设置文本阴影到指定范围
    /// - Parameters:
    ///   - shadow: 文本阴影
    ///   - range: 范围
    func te_setTextShadow(_ shadow: TETextShadow, range: NSRange) {
        addAttribute(TEAttributeKey.textShadow, value: shadow, range: range)
    }
    
    /// 设置文本高亮到指定范围
    /// - Parameters:
    ///   - highlight: 文本高亮
    ///   - range: 范围
    func te_setTextHighlight(_ highlight: TETextHighlight, range: NSRange) {
        addAttribute(TEAttributeKey.textHighlight, value: highlight, range: range)
    }
    
    /// 设置文本附件到指定范围
    /// - Parameters:
    ///   - attachment: 文本附件
    ///   - range: 范围
    func te_setTextAttachment(_ attachment: TETextAttachment, range: NSRange) {
        addAttribute(TEAttributeKey.textAttachment, value: attachment, range: range)
    }
}

// MARK: - 属性转换器

/// 属性转换器
/// 负责 TextEngineKit 属性与 CoreText 属性的转换
public final class TEAttributeConverter {
    
    /// 将 TextEngineKit 属性转换为 CoreText 属性
    /// - Parameter attributes: TextEngineKit 属性字典
    /// - Returns: CoreText 属性字典
    public static func convertToCoreTextAttributes(_ attributes: [NSAttributedString.Key: Any]) -> [NSAttributedString.Key: Any] {
        var coreTextAttributes: [NSAttributedString.Key: Any] = [:]
        
        for (key, value) in attributes {
            if let coreTextKey = coreTextAttributeKey(for: key) {
                if let coreTextValue = coreTextAttributeValue(for: key, value: value) {
                    coreTextAttributes[coreTextKey] = coreTextValue
                }
            }
        }
        
        return coreTextAttributes
    }

    /// 将整串属性字符串转换为 CoreText 可识别的属性字符串，并处理附件的 CTRunDelegate
    /// - Parameter attributedString: 原始属性字符串（包含 TextEngineKit 扩展属性）
    /// - Returns: 转换后的属性字符串（含 CoreText 标准属性与附件 run delegate）
    public static func convertAttributedString(_ attributedString: NSAttributedString) -> NSAttributedString {
        let converted = NSMutableAttributedString(string: attributedString.string)
        let fullRange = NSRange(location: 0, length: attributedString.length)
        attributedString.enumerateAttributes(in: fullRange, options: []) { attrs, range, _ in
            var ctAttrs = convertToCoreTextAttributes(attrs)

            // 附件 CTRunDelegate 绑定
            if let attachment = attrs[TEAttributeKey.textAttachment] as? TETextAttachment {
                let font = attrs[TEAttributeKey.font] as? TEFont
                let delegate = makeRunDelegate(for: attachment, font: font)
                ctAttrs[NSAttributedString.Key(kCTRunDelegateAttributeName as String)] = delegate
            }

            // 保留非 CoreText 的装饰属性用于渲染阶段读取
            if let border = attrs[TEAttributeKey.textBorder] { ctAttrs[TEAttributeKey.textBorder] = border }
            if let bgBorder = attrs[TEAttributeKey.textBackgroundBorder] { ctAttrs[TEAttributeKey.textBackgroundBorder] = bgBorder }
            if let shadow = attrs[TEAttributeKey.textShadow] { ctAttrs[TEAttributeKey.textShadow] = shadow }
            if let innerShadow = attrs[TEAttributeKey.textInnerShadow] { ctAttrs[TEAttributeKey.textInnerShadow] = innerShadow }
            if let highlight = attrs[TEAttributeKey.textHighlight] { ctAttrs[TEAttributeKey.textHighlight] = highlight }
            if let transform = attrs[TEAttributeKey.glyphTransform] { ctAttrs[TEAttributeKey.glyphTransform] = transform }

            converted.setAttributes(ctAttrs, range: range)
        }
        return converted
    }
    
    /// 获取对应的 CoreText 属性键
    /// - Parameter key: TextEngineKit 属性键
    /// - Returns: CoreText 属性键
    private static func coreTextAttributeKey(for key: NSAttributedString.Key) -> NSAttributedString.Key? {
        switch key {
        case TEAttributeKey.font:
            return .font
        case TEAttributeKey.foregroundColor:
            return .foregroundColor
        case TEAttributeKey.backgroundColor:
            return .backgroundColor
        case TEAttributeKey.kern:
            return .kern
        case TEAttributeKey.strikethroughStyle:
            return .strikethroughStyle
        case TEAttributeKey.strikethroughColor:
            return .strikethroughColor
        case TEAttributeKey.underlineStyle:
            return .underlineStyle
        case TEAttributeKey.underlineColor:
            return .underlineColor
        case TEAttributeKey.strokeWidth:
            return .strokeWidth
        case TEAttributeKey.strokeColor:
            return .strokeColor
        case TEAttributeKey.shadow:
            return .shadow
        case TEAttributeKey.paragraphStyle:
            return .paragraphStyle
        case TEAttributeKey.verticalGlyphForm:
            return NSAttributedString.Key(kCTVerticalFormsAttributeName as String)
        case TEAttributeKey.writingDirection:
            return .writingDirection
        case TEAttributeKey.runDelegate:
            return NSAttributedString.Key(kCTRunDelegateAttributeName as String)
        default:
            return nil
        }
    }
    
    /// 获取对应的 CoreText 属性值
    /// - Parameters:
    ///   - key: TextEngineKit 属性键
    ///   - value: TextEngineKit 属性值
    /// - Returns: CoreText 属性值
    private static func coreTextAttributeValue(for key: NSAttributedString.Key, value: Any) -> Any? {
        switch key {
        case TEAttributeKey.font:
            return value
        case TEAttributeKey.foregroundColor, TEAttributeKey.backgroundColor,
             TEAttributeKey.strikethroughColor, TEAttributeKey.underlineColor,
             TEAttributeKey.strokeColor:
            return value
        case TEAttributeKey.kern, TEAttributeKey.strikethroughStyle,
             TEAttributeKey.underlineStyle, TEAttributeKey.strokeWidth:
            return value
        case TEAttributeKey.shadow:
            return value
        case TEAttributeKey.paragraphStyle:
            return value
        case TEAttributeKey.verticalGlyphForm:
            return value
        case TEAttributeKey.writingDirection:
            return value
        case TEAttributeKey.runDelegate:
            return value
        default:
            return nil
        }
    }

    /// 创建附件的 CTRunDelegate，提供 ascent/descent/width 以参与排版
    private static func makeRunDelegate(for attachment: TETextAttachment, font: TEFont?) -> CTRunDelegate {
        final class Box { let size: CGSize; let baselineOffset: CGFloat; let alignment: TEVerticalAlignment; let asc: CGFloat; let desc: CGFloat; init(size: CGSize, baselineOffset: CGFloat, alignment: TEVerticalAlignment, asc: CGFloat, desc: CGFloat) { self.size = size; self.baselineOffset = baselineOffset; self.alignment = alignment; self.asc = asc; self.desc = desc } }
        #if canImport(UIKit)
        let asc = font?.ascender ?? 0
        let desc = abs(font?.descender ?? 0)
        #elseif canImport(AppKit)
        let asc = font?.ascender ?? 0
        let desc = abs(font?.descender ?? 0)
        #endif
        let box = Box(size: attachment.size, baselineOffset: attachment.baselineOffset, alignment: attachment.verticalAlignment, asc: asc, desc: desc)

        var callbacks = CTRunDelegateCallbacks(version: kCTRunDelegateVersion1, dealloc: { (ref: UnsafeMutableRawPointer) in
            _ = Unmanaged<Box>.fromOpaque(ref).takeRetainedValue()
        }, getAscent: { (ref: UnsafeMutableRawPointer) -> CGFloat in
            let b = Unmanaged<Box>.fromOpaque(ref).takeUnretainedValue()
            switch b.alignment {
            case .top:
                return b.size.height + b.baselineOffset
            case .center:
                let target = max(b.asc, b.size.height/2)
                return target + b.baselineOffset
            case .bottom:
                return max(0, b.baselineOffset)
            }
        }, getDescent: { (ref: UnsafeMutableRawPointer) -> CGFloat in
            let b = Unmanaged<Box>.fromOpaque(ref).takeUnretainedValue()
            switch b.alignment {
            case .top:
                return max(0, -b.baselineOffset)
            case .center:
                let ascent = max(b.asc, b.size.height/2)
                let total = b.size.height
                let d = max(total - ascent, b.desc)
                return d + max(0, -b.baselineOffset)
            case .bottom:
                return b.size.height + max(0, -b.baselineOffset)
            }
        }, getWidth: { (ref: UnsafeMutableRawPointer) -> CGFloat in
            let b = Unmanaged<Box>.fromOpaque(ref).takeUnretainedValue()
            return b.size.width
        })

        return CTRunDelegateCreate(&callbacks, Unmanaged.passRetained(box).toOpaque())!
    }
}
