// 
//  TEParser.swift 
//  TextEngineKit 
// 
//  Created by fengming on 2025/11/17. 
// 
//  文本解析：定义解析协议与 Markdown 解析器，实现标题、代码、链接与强调等解析。 
// 
import Foundation
#if canImport(AppKit)
import AppKit
#endif

/// 文本解析器协议
/// 定义文本解析器的基本接口
public protocol TETextParser {
    
    /// 解析文本
    /// - Parameter text: 输入文本
    /// - Returns: 解析后的属性字符串
    func parse(_ text: String) -> NSAttributedString
    
    /// 解析文本到可变属性字符串
    /// - Parameter text: 输入文本
    /// - Returns: 解析后的可变属性字符串
    func parseToMutable(_ text: String) -> NSMutableAttributedString
}

// MARK: - Markdown 解析器

/// Markdown 解析器
/// 将 Markdown 文本解析为富文本
public final class TEMarkdownParser: TETextParser {
    
    // MARK: - 属性
    
    /// 默认属性
    private let defaultAttributes: [NSAttributedString.Key: Any]
    
    /// 标题属性
    private let headingAttributes: [Int: [NSAttributedString.Key: Any]]
    
    /// 代码属性
    private let codeAttributes: [NSAttributedString.Key: Any]
    
    /// 链接属性
    private let linkAttributes: [NSAttributedString.Key: Any]
    
    /// 强调属性
    private let emphasisAttributes: [NSAttributedString.Key: Any]
    
    /// 粗体属性
    private let strongAttributes: [NSAttributedString.Key: Any]
    
    /// 删除线属性
    private let strikethroughAttributes: [NSAttributedString.Key: Any]
    
    // MARK: - 初始化
    
    public init() {
        // 默认属性
        self.defaultAttributes = [
            TEAttributeKey.font: TEFont.systemFont(ofSize: 16),
            TEAttributeKey.foregroundColor: TEColor.label
        ]
        
        // 标题属性
        self.headingAttributes = [
            1: [TEAttributeKey.font: TEFont.boldSystemFont(ofSize: 32), TEAttributeKey.foregroundColor: TEColor.label],
            2: [TEAttributeKey.font: TEFont.boldSystemFont(ofSize: 24), TEAttributeKey.foregroundColor: TEColor.label],
            3: [TEAttributeKey.font: TEFont.boldSystemFont(ofSize: 20), TEAttributeKey.foregroundColor: TEColor.label],
            4: [TEAttributeKey.font: TEFont.boldSystemFont(ofSize: 18), TEAttributeKey.foregroundColor: TEColor.label],
            5: [TEAttributeKey.font: TEFont.boldSystemFont(ofSize: 16), TEAttributeKey.foregroundColor: TEColor.label],
            6: [TEAttributeKey.font: TEFont.boldSystemFont(ofSize: 14), TEAttributeKey.foregroundColor: TEColor.label]
        ]
        
        // 代码属性
        self.codeAttributes = [
            TEAttributeKey.font: TEFont.monospacedSystemFont(ofSize: 14, weight: .regular),
            TEAttributeKey.foregroundColor: TEColor.systemRed,
            TEAttributeKey.backgroundColor: TEColor.systemGray6
        ]
        
        // 链接属性
        self.linkAttributes = [
            TEAttributeKey.foregroundColor: TEColor.systemBlue,
            TEAttributeKey.underlineStyle: TEUnderlineStyle.single.rawValue
        ]
        
        // 强调属性
        self.emphasisAttributes = [
            TEAttributeKey.font: TEFont.italicSystemFont(ofSize: 16)
        ]
        
        // 粗体属性
        self.strongAttributes = [
            TEAttributeKey.font: TEFont.boldSystemFont(ofSize: 16)
        ]
        
        // 删除线属性
        self.strikethroughAttributes = [
            TEAttributeKey.strikethroughStyle: TEUnderlineStyle.single.rawValue
        ]
        
        TETextEngine.shared.logDebug("Markdown 解析器初始化完成", category: "parsing")
    }
    
    // MARK: - TETextParser 协议
    
    public func parse(_ text: String) -> NSAttributedString {
        return parseToMutable(text)
    }
    
    public func parseToMutable(_ text: String) -> NSMutableAttributedString {
        let startTime = CFAbsoluteTimeGetCurrent()
        
        let attributedString = NSMutableAttributedString(string: text, attributes: defaultAttributes)
        
        // 解析各种 Markdown 元素
        parseHeadings(in: attributedString)
        parseCodeBlocks(in: attributedString)
        parseInlineCode(in: attributedString)
        parseLinks(in: attributedString)
        parseEmphasis(in: attributedString)
        parseStrong(in: attributedString)
        parseStrikethrough(in: attributedString)
        parseLists(in: attributedString)
        parseBlockquotes(in: attributedString)
        
        let duration = (CFAbsoluteTimeGetCurrent() - startTime) * 1000
        TETextEngine.shared.logParsingPerformance(
            parserType: "markdown",
            inputLength: text.count,
            duration: duration,
            outputLength: attributedString.length
        )
        
        return attributedString
    }
    
    // MARK: - 私有解析方法
    
    /// 解析标题
    /// - Parameter attributedString: 属性字符串
    private func parseHeadings(in attributedString: NSMutableAttributedString) {
        let text = attributedString.string
        let pattern = "^(#{1,6})\\s+(.+)$"
        guard let regex = try? NSRegularExpression(pattern: pattern, options: [.anchorsMatchLines]) else { return }
        
        let matches = regex.matches(in: text, options: [], range: NSRange(location: 0, length: text.count))
        
        for match in matches.reversed() {
            guard match.numberOfRanges == 3 else { continue }
            
            let levelRange = match.range(at: 1)
            let textRange = match.range(at: 2)
            
            let level = levelRange.length
            guard level >= 1 && level <= 6 else { continue }
            
            if let attributes = headingAttributes[level] {
                attributedString.addAttributes(attributes, range: textRange)
            }
        }
    }
    
    /// 解析代码块
    /// - Parameter attributedString: 属性字符串
    private func parseCodeBlocks(in attributedString: NSMutableAttributedString) {
        let text = attributedString.string
        let pattern = "```([\\s\\S]*?)```"
        guard let regex = try? NSRegularExpression(pattern: pattern, options: []) else { return }
        
        let matches = regex.matches(in: text, options: [], range: NSRange(location: 0, length: text.count))
        
        for match in matches.reversed() {
            attributedString.addAttributes(codeAttributes, range: match.range)
        }
    }
    
    /// 解析行内代码
    /// - Parameter attributedString: 属性字符串
    private func parseInlineCode(in attributedString: NSMutableAttributedString) {
        let text = attributedString.string
        let pattern = "`([^`]+)`"
        guard let regex = try? NSRegularExpression(pattern: pattern, options: []) else { return }
        
        let matches = regex.matches(in: text, options: [], range: NSRange(location: 0, length: text.count))
        
        for match in matches.reversed() {
            attributedString.addAttributes(codeAttributes, range: match.range)
        }
    }
    
    /// 解析链接
    /// - Parameter attributedString: 属性字符串
    private func parseLinks(in attributedString: NSMutableAttributedString) {
        let text = attributedString.string
        // 使用严格的 Markdown 链接格式：[文本](URL)
        let pattern = "\\[([^\\]]+)\\]\\(([^\\)]+)\\)"
        guard let regex = try? NSRegularExpression(pattern: pattern, options: []) else { return }
        
        let matches = regex.matches(in: text, options: [], range: NSRange(location: 0, length: text.count))
        
        // 从后向前处理，避免范围变化影响后续匹配
        for match in matches.reversed() {
            guard match.numberOfRanges == 3 else { continue }
            
            let textRange = match.range(at: 1)
            let urlRange = match.range(at: 2)
            
            let rawURL = (text as NSString).substring(with: urlRange).trimmingCharacters(in: .whitespacesAndNewlines)
            
            // 安全处理：过滤控制字符，防止注入攻击
            // 为什么需要过滤：用户输入的 URL 可能包含恶意控制字符
            let sanitized = String(rawURL.unicodeScalars.filter { !CharacterSet.controlCharacters.contains($0) })
            
            // 限制 URL 长度，防止内存耗尽攻击
            // 2048 字符是合理的 URL 长度上限，超过此长度的 URL 通常是无效的
            guard sanitized.count <= 2048 else { continue }
            
            // 验证 URL 格式和协议，只允许 HTTP/HTTPS 协议
            // 为什么限制协议：防止 javascript:、file: 等危险协议
            if let url = URL(string: sanitized), let scheme = url.scheme?.lowercased(), scheme == "http" || scheme == "https" {
                var linkAttributes = linkAttributes
                linkAttributes[.link] = url.absoluteString
                attributedString.addAttributes(linkAttributes, range: textRange)
            }
        }
    }
    
    /// 解析强调
    /// - Parameter attributedString: 属性字符串
    private func parseEmphasis(in attributedString: NSMutableAttributedString) {
        let text = attributedString.string
        let patterns = ["\\*([^*]+)\\*", "_([^_]+)_"]
        
        for pattern in patterns {
            guard let regex = try? NSRegularExpression(pattern: pattern, options: []) else { continue }
            let matches = regex.matches(in: text, options: [], range: NSRange(location: 0, length: text.count))
            
            for match in matches.reversed() {
                applyFontTrait(.italic, to: attributedString, range: match.range)
            }
        }
    }
    
    /// 解析粗体
    /// - Parameter attributedString: 属性字符串
    private func parseStrong(in attributedString: NSMutableAttributedString) {
        let text = attributedString.string
        let patterns = ["\\*\\*(.*?)\\*\\*", "__([^_]+)__"]
        
        for pattern in patterns {
            guard let regex = try? NSRegularExpression(pattern: pattern, options: []) else { continue }
            let matches = regex.matches(in: text, options: [], range: NSRange(location: 0, length: text.count))
            
            for match in matches.reversed() {
                applyFontTrait(.bold, to: attributedString, range: match.range)
            }
        }
    }

    private enum FontTrait { case bold, italic }
    private func applyFontTrait(_ trait: FontTrait, to attributedString: NSMutableAttributedString, range: NSRange) {
        #if canImport(UIKit)
        attributedString.enumerateAttribute(TEAttributeKey.font, in: range, options: []) { value, subRange, _ in
            let base = (value as? TEFont) ?? TEFont.systemFont(ofSize: 16)
            var traits = base.fontDescriptor.symbolicTraits
            switch trait {
            case .bold: traits.insert(.traitBold)
            case .italic: traits.insert(.traitItalic)
            }
            if let desc = base.fontDescriptor.withSymbolicTraits(traits) {
                let newFont = TEFont(descriptor: desc, size: base.pointSize)
                attributedString.addAttribute(TEAttributeKey.font, value: newFont, range: subRange)
            } else {
                let fallback: TEFont = (trait == .bold) ? TEFont.boldSystemFont(ofSize: base.pointSize) : TEFont.italicSystemFont(ofSize: base.pointSize)
                attributedString.addAttribute(TEAttributeKey.font, value: fallback, range: subRange)
            }
        }
        #elseif canImport(AppKit)
        let manager = NSFontManager.shared
        attributedString.enumerateAttribute(TEAttributeKey.font, in: range, options: []) { value, subRange, _ in
            let base = (value as? TEFont) ?? TEFont.systemFont(ofSize: 16)
            var targetTraits = manager.traits(of: base)
            switch trait {
            case .bold:
                targetTraits.insert(.boldFontMask)
            case .italic:
                targetTraits.insert(.italicFontMask)
            }
            let newFont = manager.convert(base, toHaveTrait: targetTraits)
            attributedString.addAttribute(TEAttributeKey.font, value: newFont, range: subRange)
        }
        #endif
    }
    
    /// 解析删除线
    /// - Parameter attributedString: 属性字符串
    private func parseStrikethrough(in attributedString: NSMutableAttributedString) {
        let text = attributedString.string
        let pattern = "~~([^~]+)~~"
        guard let regex = try? NSRegularExpression(pattern: pattern, options: []) else { return }
        
        let matches = regex.matches(in: text, options: [], range: NSRange(location: 0, length: text.count))
        
        for match in matches.reversed() {
            attributedString.addAttributes(strikethroughAttributes, range: match.range)
        }
    }
    
    /// 解析列表
    /// - Parameter attributedString: 属性字符串
    private func parseLists(in attributedString: NSMutableAttributedString) {
        let text = attributedString.string
        let pattern = "^\\s*[-*+]\\s+(.+)$"
        guard let regex = try? NSRegularExpression(pattern: pattern, options: [.anchorsMatchLines]) else { return }
        
        let matches = regex.matches(in: text, options: [], range: NSRange(location: 0, length: text.count))
        
        for match in matches.reversed() {
            guard match.numberOfRanges == 2 else { continue }
            let textRange = match.range(at: 1)
            
            // 添加列表样式属性
            let paragraphStyle = TEMutableParagraphStyle()
            paragraphStyle.headIndent = 20
            paragraphStyle.firstLineHeadIndent = 20
            
            var listAttributes = defaultAttributes
            listAttributes[TEAttributeKey.paragraphStyle] = paragraphStyle
            
            attributedString.addAttributes(listAttributes, range: textRange)
        }
    }
    
    /// 解析引用
    /// - Parameter attributedString: 属性字符串
    private func parseBlockquotes(in attributedString: NSMutableAttributedString) {
        let text = attributedString.string
        let pattern = "^>\\s+(.+)$"
        guard let regex = try? NSRegularExpression(pattern: pattern, options: [.anchorsMatchLines]) else { return }
        
        let matches = regex.matches(in: text, options: [], range: NSRange(location: 0, length: text.count))
        
        for match in matches.reversed() {
            guard match.numberOfRanges == 2 else { continue }
            let textRange = match.range(at: 1)
            
            // 添加引用样式属性
            let paragraphStyle = TEMutableParagraphStyle()
            paragraphStyle.headIndent = 20
            paragraphStyle.firstLineHeadIndent = 20
            
            var quoteAttributes = defaultAttributes
            quoteAttributes[TEAttributeKey.foregroundColor] = TEColor.systemGray
            quoteAttributes[TEAttributeKey.paragraphStyle] = paragraphStyle
            
            attributedString.addAttributes(quoteAttributes, range: textRange)
        }
    }
}

// MARK: - 表情符号解析器

/// 表情符号解析器
/// 将表情符号代码解析为 Unicode 表情符号
public final class TEEmojiParser: TETextParser {
    
    // MARK: - 属性
    
    /// 表情符号映射
    private let emojiMap: [String: String] = [
        ":)": "😊",
        ":(": "😢",
        ":D": "😃",
        ":P": "😛",
        ":o": "😮",
        ":O": "😮",
        ":smile:": "😄",
        ";)": "😉",
        "B)": "😎",
        ":'(": "😂",
        ":\"": "😗",
        ":*": "😘",
        ":|": "😐",
        ":/": "😕",
        ":\\": "😕",
        "<3": "❤️",
        "</3": "💔",
        ":heart:": "❤️",
        ":broken_heart:": "💔",
        ":thumbs_up:": "👍",
        ":thumbs_down:": "👎",
        ":ok:": "👌",
        ":victory:": "✌️",
        ":wave:": "👋",
        ":clap:": "👏",
        ":fire:": "🔥",
        ":star:": "⭐",
        ":sun:": "☀️",
        ":moon:": "🌙",
        ":cloud:": "☁️",
        ":rain:": "🌧️",
        ":snow:": "❄️",
        ":lightning:": "⚡",
        ":coffee:": "☕",
        ":pizza:": "🍕",
        ":burger:": "🍔",
        ":fries:": "🍟",
        ":sushi:": "🍣",
        ":cake:": "🍰",
        ":apple:": "🍎",
        ":banana:": "🍌",
        ":orange:": "🍊",
        ":grape:": "🍇",
        ":strawberry:": "🍓",
        ":watermelon:": "🍉",
        ":car:": "🚗",
        ":bus:": "🚌",
        ":train:": "🚂",
        ":plane:": "✈️",
        ":rocket:": "🚀",
        ":bike:": "🚲",
        ":walk:": "🚶",
        ":run:": "🏃",
        ":swim:": "🏊",
        ":music:": "🎵",
        ":movie:": "🎬",
        ":game:": "🎮",
        ":book:": "📚",
        ":phone:": "📱",
        ":computer:": "💻",
        ":camera:": "📷",
        ":watch:": "⌚",
        ":money:": "💰",
        ":gift:": "🎁",
        ":party:": "🎉",
        ":balloon:": "🎈",
        ":candle:": "🕯️",
        ":bell:": "🔔",
        ":clock:": "⏰",
        ":alarm:": "⏰",
        ":timer:": "⏲️",
        ":stopwatch:": "⏱️",
        ":100:": "💯",
        ":ok_hand:": "👌",
        ":thumbsup:": "👍"
    ]
    
    /// 默认属性
    private let defaultAttributes: [NSAttributedString.Key: Any]
    
    // MARK: - 初始化
    
    public init() {
        self.defaultAttributes = [
            .font: TEFont.systemFont(ofSize: 16),
            .foregroundColor: TEColor.label
        ]
        
        TETextEngine.shared.logDebug("表情符号解析器初始化完成", category: "parsing")
    }
    
    // MARK: - TETextParser 协议
    
    public func parse(_ text: String) -> NSAttributedString {
        return parseToMutable(text)
    }
    
    public func parseToMutable(_ text: String) -> NSMutableAttributedString {
        let startTime = CFAbsoluteTimeGetCurrent()
        
        let attributedString = NSMutableAttributedString(string: text, attributes: defaultAttributes)
        
        // 解析表情符号
        parseEmojis(in: attributedString)
        
        let duration = (CFAbsoluteTimeGetCurrent() - startTime) * 1000
        TETextEngine.shared.logParsingPerformance(
            parserType: "emoji",
            inputLength: text.count,
            duration: duration,
            outputLength: attributedString.length
        )
        
        return attributedString
    }
    
    // MARK: - 私有方法
    
    /// 解析表情符号
    /// - Parameter attributedString: 属性字符串
    private func parseEmojis(in attributedString: NSMutableAttributedString) {
        // 构建单次匹配的正则，大小写不敏感
        let keys = emojiMap.keys.map { NSRegularExpression.escapedPattern(for: $0) }
        let pattern = "(" + keys.joined(separator: "|") + ")"
        guard let regex = try? NSRegularExpression(pattern: pattern, options: [.caseInsensitive]) else { return }
        let text = attributedString.string
        let matches = regex.matches(in: text, options: [], range: NSRange(location: 0, length: text.count))
        for match in matches.reversed() {
            let matched = (text as NSString).substring(with: match.range).lowercased()
            if let emoji = emojiMap[matched] {
                attributedString.replaceCharacters(in: match.range, with: emoji)
            }
        }
    }

    public func applyInPlace(_ attributedString: NSMutableAttributedString) {
        parseEmojis(in: attributedString)
    }
}

// MARK: - 组合解析器

/// 组合解析器
/// 组合多个解析器按顺序解析文本
public final class TECompositeParser: TETextParser {
    
    // MARK: - 属性
    
    /// 解析器数组
    private let parsers: [TETextParser]
    public enum LinkConflictStrategy { case complement, override, skip }
    public var linkConflictStrategy: LinkConflictStrategy = .complement
    
    // MARK: - 初始化
    
    public init(parsers: [TETextParser], strategy: LinkConflictStrategy = .complement) {
        self.parsers = parsers
        self.linkConflictStrategy = strategy
        TETextEngine.shared.logDebug("组合解析器初始化完成，包含 \(parsers.count) 个解析器", category: "parsing")
    }
    
    /// 默认组合解析器（Markdown + Emoji）
    public static func defaultParser() -> TECompositeParser {
        return TECompositeParser(parsers: [
            TEEmojiParser(),
            TEMarkdownParser()
        ], strategy: .complement)
    }
    
    // MARK: - TETextParser 协议
    
    public func parse(_ text: String) -> NSAttributedString {
        return parseToMutable(text)
    }
    
    public func parseToMutable(_ text: String) -> NSMutableAttributedString {
        let startTime = CFAbsoluteTimeGetCurrent()
        
        // 1) 先进行 Emoji 替换，确保后续 Markdown 基于最终文本
        let emojiStage = TEEmojiParser().parseToMutable(text)
        let result = TEMarkdownParser().parseToMutable(emojiStage.string)
        
        // 3) 数据检测补全（仅为未设置 .link 的范围添加链接属性）
        if linkConflictStrategy != .skip, let detector = try? NSDataDetector(types: NSTextCheckingResult.CheckingType.link.rawValue | NSTextCheckingResult.CheckingType.phoneNumber.rawValue) {
            let range = NSRange(location: 0, length: result.length)
            detector.enumerateMatches(in: result.string, options: [], range: range) { r, _, _ in
                guard let r = r else { return }
                var hasLink = false
                result.enumerateAttribute(.link, in: r.range, options: []) { value, subRange, stop in
                    if value != nil && subRange.length > 0 { hasLink = true; stop.pointee = true }
                }
                if linkConflictStrategy == .complement && hasLink { return }
                var attrs: [NSAttributedString.Key: Any] = [
                    TEAttributeKey.foregroundColor: TEColor.systemBlue,
                    TEAttributeKey.underlineStyle: TEUnderlineStyle.single.rawValue
                ]
                switch r.resultType {
                case .link:
                    if let url = r.url {
                        let sanitized = String(url.absoluteString.unicodeScalars.filter { !CharacterSet.controlCharacters.contains($0) })
                        guard sanitized.count <= 2048 else { return }
                        attrs[.link] = sanitized
                    }
                case .phoneNumber:
                    if let p = r.phoneNumber { attrs[.link] = "tel://" + p }
                default:
                    break
                }
                if linkConflictStrategy == .override {
                    result.removeAttribute(.link, range: r.range)
                }
                result.addAttributes(attrs, range: r.range)
            }
        }
        
        let duration = (CFAbsoluteTimeGetCurrent() - startTime) * 1000
        TETextEngine.shared.logParsingPerformance(
            parserType: "composite",
            inputLength: text.count,
            duration: duration,
            outputLength: result.length
        )
        
        return result
    }
}

// MARK: - 数据检测解析器

public final class TELinkDetectorParser: TETextParser {
    private let detector: NSDataDetector
    private let linkAttributes: [NSAttributedString.Key: Any]
    public init() {
        self.detector = (try? NSDataDetector(types: NSTextCheckingResult.CheckingType.link.rawValue | NSTextCheckingResult.CheckingType.phoneNumber.rawValue)) ?? NSDataDetector()
        self.linkAttributes = [
            TEAttributeKey.foregroundColor: TEColor.systemBlue,
            TEAttributeKey.underlineStyle: TEUnderlineStyle.single.rawValue
        ]
        TETextEngine.shared.logDebug("数据检测解析器初始化完成", category: "parsing")
    }
    public func parse(_ text: String) -> NSAttributedString { return parseToMutable(text) }
    public func parseToMutable(_ text: String) -> NSMutableAttributedString {
        let startTime = CFAbsoluteTimeGetCurrent()
        let attr = NSMutableAttributedString(string: text)
        let range = NSRange(location: 0, length: text.utf16.count)
        detector.enumerateMatches(in: text, options: [], range: range) { result, _, _ in
            guard let r = result else { return }
            var attrs = linkAttributes
            switch r.resultType {
            case .link:
                if let url = r.url { attrs[.link] = url.absoluteString }
            case .phoneNumber:
                if let p = r.phoneNumber { attrs[.link] = "tel://" + p }
            default:
                break
            }
            attr.addAttributes(attrs, range: r.range)
        }
        let duration = (CFAbsoluteTimeGetCurrent() - startTime) * 1000
        TETextEngine.shared.logParsingPerformance(parserType: "data_detector", inputLength: text.count, duration: duration, outputLength: attr.length)
        return attr
    }
}
