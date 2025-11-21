#if canImport(UIKit)
// 
//  TELabel+Attachments.swift 
//  TextEngineKit 
// 
//  Created by fengming on 2025/11/17. 
// 
//  TELabel 附件扩展：提供附件添加、移除与清理的便捷方法。 
// 
import UIKit
import CoreText

@MainActor
extension TELabel {
    func drawAttachments(in context: CGContext, rect: CGRect) {
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
}
#endif
