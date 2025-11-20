import Foundation

#if canImport(UIKit)
import UIKit
public typealias TEPasteboard = UIPasteboard
#elseif canImport(AppKit)
import AppKit
public typealias TEPasteboard = NSPasteboard
#endif

/// 剪贴板管理器
/// 管理文本的复制和粘贴操作
public final class TEClipboardManager {
    
    // MARK: - 属性
    
    /// 通用剪贴板
    private let generalPasteboard = TEPasteboard.general
    
    /// 自定义剪贴板
    private var customPasteboards: [String: TEPasteboard] = [:]
    
    /// 剪贴板历史记录
    private var clipboardHistory: [String] = []
    
    /// 最大历史记录数
    public var maxHistoryCount: Int = 20
    
    /// 是否启用历史记录
    public var isHistoryEnabled: Bool = true
    
    /// 线程安全锁
    private let lock = NSLock()
    
    // MARK: - 初始化
    
    public init() {
        TETextEngine.shared.logDebug("剪贴板管理器初始化完成", category: "clipboard")
    }
    
    // MARK: - 公共方法
    
    /// 复制文本到通用剪贴板
    /// - Parameter text: 要复制的文本
    public func copyText(_ text: String) {
        lock.lock()
        defer { lock.unlock() }
        
        #if canImport(UIKit)
        generalPasteboard.string = text
        #elseif canImport(AppKit)
        generalPasteboard.clearContents()
        generalPasteboard.setString(text, forType: .string)
        #endif
        
        // 添加到历史记录
        if isHistoryEnabled {
            addToHistory(text)
        }
        
        TETextEngine.shared.logDebug("复制文本到剪贴板: length=\(text.count)", category: "clipboard")
    }
    
    /// 从通用剪贴板粘贴文本
    /// - Returns: 粘贴的文本或 nil
    public func pasteText() -> String? {
        lock.lock()
        defer { lock.unlock() }
        
        #if canImport(UIKit)
        let text = generalPasteboard.string
        #elseif canImport(AppKit)
        let text = generalPasteboard.string(forType: .string)
        #endif
        
        if let text = text {
            TETextEngine.shared.logDebug("从剪贴板粘贴文本: length=\(text.count)", category: "clipboard")
        } else {
            TETextEngine.shared.logDebug("剪贴板为空", category: "clipboard")
        }
        
        return text
    }
    
    /// 复制富文本到通用剪贴板
    /// - Parameter attributedText: 要复制的富文本
    public func copyAttributedText(_ attributedText: NSAttributedString) {
        lock.lock()
        defer { lock.unlock() }
        
        #if canImport(UIKit)
        generalPasteboard.string = attributedText.string
        #elseif canImport(AppKit)
        generalPasteboard.clearContents()
        generalPasteboard.setString(attributedText.string, forType: .string)
        #endif
        
        // 尝试设置富文本（如果支持）
        #if canImport(UIKit)
        if #available(iOS 14.0, *) {
            generalPasteboard.setValue(attributedText, forPasteboardType: "public.rtf")
        }
        #elseif canImport(AppKit)
        generalPasteboard.setData(attributedText.rtf(from: NSRange(location: 0, length: attributedText.length)), forType: .rtf)
        #endif
        
        // 添加到历史记录
        if isHistoryEnabled {
            addToHistory(attributedText.string)
        }
        
        TETextEngine.shared.logDebug("复制富文本到剪贴板", category: "clipboard")
    }
    
    /// 从通用剪贴板粘贴富文本
    /// - Returns: 粘贴的富文本或 nil
    public func pasteAttributedText() -> NSAttributedString? {
        lock.lock()
        defer { lock.unlock() }
        
        #if canImport(UIKit)
        if #available(iOS 14.0, *) {
            if let attributedText = generalPasteboard.value(forPasteboardType: "public.rtf") as? NSAttributedString {
                TETextEngine.shared.logDebug("从剪贴板粘贴富文本", category: "clipboard")
                return attributedText
            }
        }
        #elseif canImport(AppKit)
        if let rtfData = generalPasteboard.data(forType: .rtf),
           let attributedText = NSAttributedString(rtf: rtfData, documentAttributes: nil) {
            TETextEngine.shared.logDebug("从剪贴板粘贴富文本", category: "clipboard")
            return attributedText
        }
        #endif
        
        // 回退到纯文本
        #if canImport(UIKit)
        if let string = generalPasteboard.string {
            return NSAttributedString(string: string)
        }
        #elseif canImport(AppKit)
        if let string = generalPasteboard.string(forType: .string) {
            return NSAttributedString(string: string)
        }
        #endif
        
        return nil
    }
    
    /// 复制到自定义剪贴板
    /// - Parameters:
    ///   - text: 要复制的文本
    ///   - name: 自定义剪贴板名称
    public func copyText(_ text: String, to name: String) {
        lock.lock()
        defer { lock.unlock() }
        
        let pasteboard = getOrCreateCustomPasteboard(name: name)
        
        #if canImport(UIKit)
        pasteboard.string = text
        #elseif canImport(AppKit)
        pasteboard.clearContents()
        pasteboard.setString(text, forType: .string)
        #endif
        
        TETextEngine.shared.logDebug("复制文本到自定义剪贴板 '\(name)': length=\(text.count)", category: "clipboard")
    }
    
    /// 从自定义剪贴板粘贴
    /// - Parameter name: 自定义剪贴板名称
    /// - Returns: 粘贴的文本或 nil
    public func pasteText(from name: String) -> String? {
        lock.lock()
        defer { lock.unlock() }
        
        guard let pasteboard = customPasteboards[name] else {
            TETextEngine.shared.logWarning("自定义剪贴板 '\(name)' 不存在", category: "clipboard")
            return nil
        }
        
        #if canImport(UIKit)
        let text = pasteboard.string
        #elseif canImport(AppKit)
        let text = pasteboard.string(forType: .string)
        #endif
        
        if let text = text {
            TETextEngine.shared.logDebug("从自定义剪贴板 '\(name)' 粘贴文本: length=\(text.count)", category: "clipboard")
        }
        
        return text
    }
    
    /// 清除通用剪贴板
    public func clearGeneralClipboard() {
        lock.lock()
        defer { lock.unlock() }
        
        #if canImport(UIKit)
        generalPasteboard.string = nil
        generalPasteboard.items = []
        #elseif canImport(AppKit)
        generalPasteboard.clearContents()
        #endif
        
        TETextEngine.shared.logDebug("清除通用剪贴板", category: "clipboard")
    }
    
    /// 清除自定义剪贴板
    /// - Parameter name: 自定义剪贴板名称
    public func clearCustomClipboard(name: String) {
        lock.lock()
        defer { lock.unlock() }
        
        guard let pasteboard = customPasteboards[name] else {
            TETextEngine.shared.logWarning("自定义剪贴板 '\(name)' 不存在", category: "clipboard")
            return
        }
        
        #if canImport(UIKit)
        pasteboard.string = nil
        pasteboard.items = []
        #elseif canImport(AppKit)
        pasteboard.clearContents()
        #endif
        
        TETextEngine.shared.logDebug("清除自定义剪贴板 '\(name)'", category: "clipboard")
    }
    
    /// 清除所有自定义剪贴板
    public func clearAllCustomClipboards() {
        lock.lock()
        defer { lock.unlock() }
        
        for (name, pasteboard) in customPasteboards {
            #if canImport(UIKit)
            pasteboard.string = nil
            pasteboard.items = []
            #elseif canImport(AppKit)
            pasteboard.clearContents()
            #endif
            TETextEngine.shared.logDebug("清除自定义剪贴板 '\(name)'", category: "clipboard")
        }
        
        customPasteboards.removeAll()
    }
    
    /// 获取剪贴板历史记录
    /// - Returns: 历史记录数组
    public func getClipboardHistory() -> [String] {
        lock.lock()
        defer { lock.unlock() }
        
        return Array(clipboardHistory)
    }
    
    /// 从历史记录粘贴
    /// - Parameter index: 历史记录索引
    /// - Returns: 粘贴的文本或 nil
    public func pasteFromHistory(at index: Int) -> String? {
        lock.lock()
        defer { lock.unlock() }
        
        guard index >= 0 && index < clipboardHistory.count else {
            TETextEngine.shared.logWarning("历史记录索引 \(index) 超出范围", category: "clipboard")
            return nil
        }
        
        let text = clipboardHistory[index]
        TETextEngine.shared.logDebug("从历史记录粘贴: length=\(text.count)", category: "clipboard")
        return text
    }
    
    /// 清除历史记录
    public func clearHistory() {
        lock.lock()
        defer { lock.unlock() }
        
        clipboardHistory.removeAll()
        TETextEngine.shared.logDebug("清除剪贴板历史记录", category: "clipboard")
    }
    
    /// 检查剪贴板是否包含文本
    /// - Returns: 是否包含文本
    public func hasText() -> Bool {
        lock.lock()
        defer { lock.unlock() }
        
        #if canImport(UIKit)
        return generalPasteboard.hasStrings
        #elseif canImport(AppKit)
        return generalPasteboard.string(forType: .string) != nil
        #endif
    }
    
    /// 获取剪贴板统计信息
    /// - Returns: 统计信息
    public func getStatistics() -> TEClipboardStatistics {
        lock.lock()
        defer { lock.unlock() }
        
        return TEClipboardStatistics(
            historyCount: clipboardHistory.count,
            customClipboardCount: customPasteboards.count,
            isHistoryEnabled: isHistoryEnabled,
            maxHistoryCount: maxHistoryCount
        )
    }
    
    // MARK: - 私有方法
    
    /// 获取或创建自定义剪贴板
    /// - Parameter name: 剪贴板名称
    /// - Returns: 自定义剪贴板
    private func getOrCreateCustomPasteboard(name: String) -> TEPasteboard {
        if let pasteboard = customPasteboards[name] {
            return pasteboard
        }
        
        #if canImport(UIKit)
        let pasteboard = UIPasteboard(name: UIPasteboard.Name(name), create: true)
        #elseif canImport(AppKit)
        let pasteboard = NSPasteboard(name: NSPasteboard.Name(name))
        #endif
        customPasteboards[name] = pasteboard
        
        return pasteboard
    }
    
    /// 添加到历史记录
    /// - Parameter text: 文本
    private func addToHistory(_ text: String) {
        guard isHistoryEnabled else { return }
        
        // 避免重复添加相同的文本
        if clipboardHistory.first == text {
            return
        }
        
        // 添加到历史记录开头
        clipboardHistory.insert(text, at: 0)
        
        // 限制历史记录大小
        if clipboardHistory.count > maxHistoryCount {
            clipboardHistory.removeLast()
        }
    }
}

// MARK: - 剪贴板统计信息

/// 剪贴板统计信息
public struct TEClipboardStatistics {
    /// 历史记录数
    public let historyCount: Int
    
    /// 自定义剪贴板数
    public let customClipboardCount: Int
    
    /// 是否启用历史记录
    public let isHistoryEnabled: Bool
    
    /// 最大历史记录数
    public let maxHistoryCount: Int
    
    /// 描述信息
    public var description: String {
        return """
        剪贴板统计:
        - 历史记录数: \(historyCount)
        - 自定义剪贴板数: \(customClipboardCount)
        - 历史记录启用: \(isHistoryEnabled)
        - 最大历史记录数: \(maxHistoryCount)
        """
    }
}