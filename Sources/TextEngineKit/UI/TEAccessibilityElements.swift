#if canImport(UIKit)
// 
//  TEAccessibilityElements.swift 
//  TextEngineKit 
// 
//  Created by fengming on 2025/11/17. 
// 
//  无障碍元素：为富文本组件提供辅助功能元素与读屏支持。 
// 
import UIKit
import Foundation

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
        if case .image(let img) = attachment.content {
            UIImageWriteToSavedPhotosAlbum(img, nil, nil, nil)
            TETextEngine.shared.logInfo("已保存图片到照片库", category: "accessibility")
            return true
        }
        TETextEngine.shared.logWarning("附件保存未执行：不支持的类型或平台", category: "accessibility")
        return false
    }
}
#endif
