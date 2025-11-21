#if canImport(UIKit)
// 
//  TELabel+Interaction.swift 
//  TextEngineKit 
// 
//  Created by fengming on 2025/11/17. 
// 
//  TELabel 交互扩展：手势、链接点击、复制与附件交互逻辑。 
// 
import UIKit
import Foundation

@MainActor
extension TELabel {
    /// 设置手势识别器
    func setupGestureRecognizers() {
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(handleTap(_:)))
        addGestureRecognizer(tapGesture)
        let longPressGesture = UILongPressGestureRecognizer(target: self, action: #selector(handleLongPress(_:)))
        longPressGesture.minimumPressDuration = 0.5
        addGestureRecognizer(longPressGesture)
    }

    @objc func handleTap(_ gesture: UITapGestureRecognizer) {
        let location = gesture.location(in: self)
        if let text = attributedText { performTap(at: location, in: text) }
    }

    @objc func handleLongPress(_ gesture: UILongPressGestureRecognizer) {
        guard gesture.state == .began else { return }
        let location = gesture.location(in: self)
        if let text = attributedText { performLongPress(at: location, in: text) }
    }
}
#endif
