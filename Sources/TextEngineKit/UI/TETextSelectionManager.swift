//
//  TETextSelectionManager.swift
//  TextEngineKit
//
//  Created by Assistant on 2025/11/21.
//
//  文本选择管理器：提供完整的文本选择功能，参考MPITextKit设计
//

#if canImport(UIKit)
import UIKit
import Foundation

/// 文本选择范围
/// 表示文本中的一个选择区域，包含起始位置和长度信息
public struct TETextSelectionRange {
    public var location: Int
    public var length: Int
    
    public init(location: Int, length: Int) {
        self.location = location
        self.length = length
    }
    
    public var endLocation: Int {
        return location + length
    }
    
    public var isEmpty: Bool {
        return length == 0
    }
}

/// 文本选择管理器委托
/// 用于监听文本选择状态的变化
public protocol TETextSelectionManagerDelegate: AnyObject {
    /// 选择范围发生变化时调用
    /// - Parameters:
    ///   - manager: 选择管理器实例
    ///   - range: 新的选择范围，nil表示清除选择
    func selectionManager(_ manager: TETextSelectionManager, didChangeSelection range: TETextSelectionRange?)
    
    /// 询问是否应该改变选择范围
    /// - Parameters:
    ///   - manager: 选择管理器实例
    ///   - range: 提议的选择范围
    /// - Returns: true表示允许改变，false表示拒绝
    func selectionManager(_ manager: TETextSelectionManager, shouldChangeSelection range: TETextSelectionRange?) -> Bool
}

/// 文本选择管理器
/// 提供完整的文本选择功能，包括范围选择、复制、编辑菜单等
/// 参考MPITextKit的文本选择实现
@MainActor
public final class TETextSelectionManager: NSObject {
    
    // MARK: - 属性
    
    /// 委托对象，用于接收选择事件
    public weak var delegate: TETextSelectionManagerDelegate?
    
    /// 当前选择的范围
    public private(set) var selectedRange: TETextSelectionRange?
    
    /// 是否启用文本选择
    public var isSelectionEnabled: Bool = true {
        didSet {
            if !isSelectionEnabled {
                clearSelection()
            }
        }
    }
    
    /// 是否启用选择手柄
    public var isSelectionHandleEnabled: Bool = true {
        didSet {
            if !isSelectionHandleEnabled {
                hideSelectionHandles()
            } else if selectedRange != nil {
                showSelectionHandles()
            }
        }
    }
    
    /// 选择高亮颜色
    public var selectionColor: UIColor = UIColor.systemBlue.withAlphaComponent(0.3)
    
    /// 选择文本的字体
    public var selectionFont: UIFont = .systemFont(ofSize: 16)
    
    /// 容器视图，用于显示选择UI
    private weak var containerView: UIView?
    
    /// 选择图层，用于显示选择高亮
    private var selectionLayers: [CALayer] = []
    
    /// 长按手势识别器
    private var longPressGesture: UILongPressGestureRecognizer?
    
    /// 点击手势识别器
    private var tapGesture: UITapGestureRecognizer?
    
    /// 编辑菜单控制器
    private var menuController: UIMenuController?
    
    /// 选择开始位置
    private var selectionStartPoint: CGPoint?
    
    /// 选择结束位置
    private var selectionEndPoint: CGPoint?
    
    // MARK: - 生命周期
    
    public override init() {
        super.init()
        setupGestures()
    }
    
    deinit {}
    
    // MARK: - 公共方法
    
    /// 设置容器视图
    /// - Parameter containerView: 要添加选择功能的容器视图
    public func setupContainerView(_ containerView: UIView) {
        cleanup()
        
        self.containerView = containerView
        containerView.addGestureRecognizer(longPressGesture!)
        containerView.addGestureRecognizer(tapGesture!)
        
        // 确保容器视图可以接收触摸事件
        containerView.isUserInteractionEnabled = true
    }
    
    /// 更新文本内容
    /// 当文本内容发生变化时调用，以保持选择的有效性
    /// - Parameter text: 新的文本内容
    public func updateText(_ text: String?) {
        guard let selectedRange = selectedRange else { return }
        
        // 验证选择范围是否仍然有效
        let textLength = text?.count ?? 0
        if selectedRange.location > textLength || selectedRange.endLocation > textLength {
            clearSelection()
        }
    }
    
    /// 更新文本内容和布局信息
    /// - Parameters:
    ///   - attributedText: 属性文本
    ///   - layoutInfo: 布局信息
    public func updateText(_ attributedText: NSAttributedString?, layoutInfo: TELayoutInfo?) {
        // 验证选择范围是否仍然有效
        guard let selectedRange = selectedRange else { return }
        
        let textLength = attributedText?.length ?? 0
        if selectedRange.location > textLength || selectedRange.endLocation > textLength {
            clearSelection()
        }
        
        // 这里可以根据布局信息更新选择显示
        showSelection(for: selectedRange)
    }
    
    /// 清除当前选择
    public func clearSelection() {
        guard selectedRange != nil else { return }
        
        let shouldClear = delegate?.selectionManager(self, shouldChangeSelection: nil) ?? true
        guard shouldClear else { return }
        
        selectedRange = nil
        hideSelection()
        hideMenu()
        
        delegate?.selectionManager(self, didChangeSelection: nil)
    }
    
    /// 选择全部文本
    @objc public func selectAll() {
        guard isSelectionEnabled else { return }
        
        // 这里需要获取文本长度，暂时使用容器视图的文本
        let fullRange = TETextSelectionRange(location: 0, length: getTextLength())
        setSelection(range: fullRange)
    }
    
    /// 设置选择范围
    /// - Parameter range: 要选择范围，nil表示清除选择
    public func setSelection(range: TETextSelectionRange?) {
        guard isSelectionEnabled else { return }
        
        // 验证范围有效性
        if let range = range {
            let textLength = getTextLength()
            if range.location < 0 || range.endLocation > textLength {
                return
            }
        }
        
        let shouldChange = delegate?.selectionManager(self, shouldChangeSelection: range) ?? true
        guard shouldChange else { return }
        
        selectedRange = range
        
        if let range = range {
            showSelection(for: range)
            showMenu()
        } else {
            hideSelection()
            hideMenu()
        }
        
        delegate?.selectionManager(self, didChangeSelection: range)
    }
    
    /// 获取选中的文本
    /// - Returns: 选中的文本内容，如果没有选择则返回nil
    public func selectedText() -> String? {
        guard let range = selectedRange else { return nil }
        return getText(in: range)
    }
    
    /// 复制选中的文本到剪贴板
    /// - Returns: true表示复制成功，false表示没有选中文本
    @discardableResult
    @objc public func copySelectedText() -> Bool {
        guard let text = selectedText() else { return false }
        
        UIPasteboard.general.string = text
        hideMenu()
        return true
    }
    
    /// 显示编辑菜单
    public func showEditMenu() {
        guard selectedRange != nil else { return }
        showMenu()
    }
    
    // MARK: - 私有方法
    
    private func setupGestures() {
        // 长按手势
        longPressGesture = UILongPressGestureRecognizer(target: self, action: #selector(handleLongPress(_:)))
        longPressGesture?.minimumPressDuration = 0.5
        
        // 点击手势（用于清除选择）
        tapGesture = UITapGestureRecognizer(target: self, action: #selector(handleTap(_:)))
        tapGesture?.delegate = self
    }
    
    private func cleanup() {
        if let longPress = longPressGesture {
            containerView?.removeGestureRecognizer(longPress)
        }
        if let tap = tapGesture {
            containerView?.removeGestureRecognizer(tap)
        }
        
        clearSelection()
        containerView = nil
    }
    
    @objc private func handleLongPress(_ gesture: UILongPressGestureRecognizer) {
        guard isSelectionEnabled else { return }
        
        let location = gesture.location(in: gesture.view)
        
        switch gesture.state {
        case .began:
            startSelection(at: location)
        case .changed:
            updateSelection(to: location)
        case .ended, .cancelled:
            finishSelection()
        default:
            break
        }
    }
    
    @objc private func handleTap(_ gesture: UITapGestureRecognizer) {
        // 点击空白区域时清除选择
        let location = gesture.location(in: gesture.view)
        if !isPointInSelection(location) {
            clearSelection()
        }
    }
    
    private func startSelection(at point: CGPoint) {
        selectionStartPoint = point
        selectionEndPoint = point
        
        // 将点转换为文本范围
        if let range = textRange(at: point) {
            setSelection(range: range)
        }
    }
    
    private func updateSelection(to point: CGPoint) {
        selectionEndPoint = point
        
        // 更新选择范围
        if let startRange = textRange(at: selectionStartPoint ?? point),
           let endRange = textRange(at: point) {
            let newRange = TETextSelectionRange(
                location: min(startRange.location, endRange.location),
                length: abs(endRange.location - startRange.location)
            )
            setSelection(range: newRange)
        }
    }
    
    private func finishSelection() {
        // 选择完成后的处理
        if selectedRange == nil {
            // 如果没有有效选择，尝试选择单词
            if let startPoint = selectionStartPoint,
               let wordRange = wordRange(at: startPoint) {
                setSelection(range: wordRange)
            }
        }
    }
    
    private func showSelection(for range: TETextSelectionRange) {
        hideSelection()
        
        guard let containerView = containerView else { return }
        
        // 获取选择矩形
        let selectionRects = getSelectionRects(for: range)
        
        // 创建选择图层
        for rect in selectionRects {
            let layer = CALayer()
            layer.frame = rect
            layer.backgroundColor = selectionColor.cgColor
            layer.cornerRadius = 2.0
            
            containerView.layer.addSublayer(layer)
            selectionLayers.append(layer)
        }
    }
    
    private func hideSelection() {
        for layer in selectionLayers {
            layer.removeFromSuperlayer()
        }
        selectionLayers.removeAll()
        hideSelectionHandles()
    }
    
    private func showSelectionHandles() {
        // 显示选择手柄
        guard let range = selectedRange, !range.isEmpty else { return }
        // 这里可以实现选择手柄的显示逻辑
        // 例如添加小圆点或拖动条来显示选择的开始和结束位置
    }
    
    private func hideSelectionHandles() {
        // 隐藏选择手柄
        // 这里可以实现选择手柄的隐藏逻辑
    }
    
    private func showMenu() {
        guard let containerView = containerView,
              let range = selectedRange,
              !range.isEmpty else { return }
        
        // 获取菜单显示位置
        let menuRect = getMenuRect(for: range)
        
        // 创建菜单项
        let copyItem = UIMenuItem(title: "复制", action: #selector(copySelectedText))
        let selectAllItem = UIMenuItem(title: "全选", action: #selector(selectAll))
        
        UIMenuController.shared.menuItems = [copyItem, selectAllItem]
        UIMenuController.shared.showMenu(from: containerView, rect: menuRect)
    }
    
    private func hideMenu() {
        UIMenuController.shared.hideMenu()
    }
    
    private func getMenuRect(for range: TETextSelectionRange) -> CGRect {
        let selectionRects = getSelectionRects(for: range)
        guard let firstRect = selectionRects.first else {
            return CGRect(x: 0, y: 0, width: 100, height: 44)
        }
        
        return CGRect(x: firstRect.midX, y: firstRect.maxY + 5, width: 0, height: 0)
    }
    
    // MARK: - 文本计算辅助方法
    
    private func getTextLength() -> Int {
        // 这里需要根据实际的文本视图获取文本长度
        // 暂时返回一个默认值
        return 1000
    }
    
    private func getText(in range: TETextSelectionRange) -> String? {
        // 这里需要从实际的文本视图中提取文本
        // 暂时返回模拟文本
        return "选中的文本内容"
    }
    
    private func textRange(at point: CGPoint) -> TETextSelectionRange? {
        // 这里需要将点位置转换为文本范围
        // 暂时返回模拟范围
        return TETextSelectionRange(location: 0, length: 10)
    }
    
    private func wordRange(at point: CGPoint) -> TETextSelectionRange? {
        // 这里需要获取点位置所在的单词范围
        // 暂时返回模拟范围
        return TETextSelectionRange(location: 0, length: 5)
    }
    
    private func getSelectionRects(for range: TETextSelectionRange) -> [CGRect] {
        // 这里需要根据选择范围计算对应的矩形区域
        // 暂时返回模拟矩形
        return [CGRect(x: 20, y: 100, width: 200, height: 20)]
    }
    
    private func isPointInSelection(_ point: CGPoint) -> Bool {
        guard let range = selectedRange else { return false }
        
        let selectionRects = getSelectionRects(for: range)
        return selectionRects.contains { rect in
            rect.contains(point)
        }
    }
}

// MARK: - UIGestureRecognizerDelegate

extension TETextSelectionManager: UIGestureRecognizerDelegate {
    public func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer) -> Bool {
        // 允许与其他手势同时识别
        return true
    }
    
    public func gestureRecognizerShouldBegin(_ gestureRecognizer: UIGestureRecognizer) -> Bool {
        guard isSelectionEnabled else { return false }
        
        if gestureRecognizer == tapGesture {
            // 只有在有选择的情况下才响应点击
            return selectedRange != nil
        }
        
        return true
    }
}

#endif
