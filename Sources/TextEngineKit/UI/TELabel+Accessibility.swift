#if canImport(UIKit)
// 
//  TELabel+Accessibility.swift 
//  TextEngineKit 
// 
//  Created by fengming on 2025/11/17. 
// 
//  TELabel 无障碍扩展：提供可访问性元素与特征配置支持。 
// 
import UIKit
import CoreText

@MainActor
extension TELabel {
    func rebuildAccessibilityElements(layoutInfo: TELayoutInfo) {
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
        attributed.enumerateAttribute(.link, in: NSRange(location: 0, length: attributed.length), options: []) { value, range, _ in
            let url: URL?
            if let u = value as? URL { url = u }
            else if let s = value as? String { url = URL(string: s) }
            else { url = nil }
            guard let url = url else { return }
            let rect = TETextHighlight().boundingRect(for: range, in: attributed, textRect: bounds, layoutInfo: layoutInfo)
            let linkElem = TEAccessibilityLinkElement(accessibilityContainer: self, url: url, copyText: (attributed.string as NSString).substring(with: range))
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
}
#endif
