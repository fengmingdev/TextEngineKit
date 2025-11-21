//
//  TETextSelectionManager.swift
//  TextEngineKit
//
//  Created by Assistant on 2025/11/21.
//
//  文本选择管理器：负责文本选择、复制粘贴和选择手柄管理
//

#if canImport(UIKit)
import UIKit
import Foundation

/// 文本选择范围
/// 表示文本中的一个选择区域，包含起始位置和长度信息
/// 
/// 使用示例:
/// ```swift
/// let range = TETextSelectionRange(location: 10, length: 5)
/// print("选择范围: \(range.location) - \(range.location + range.length)")
/// ```
public struct TETextSelectionRange {
    public let location: Int
    public let length: Int
    
    public init(location: Int, length: Int) {
        self.location = location
        self.length = length
    }
    
    public var nsRange: NSRange {
        return NSRange(location: location, length: length)
    }
}

/// 文本选择管理器委托协议
/// 定义了文本选择管理器与外部交互的接口
/// 
/// 使用示例:
/// ```swift
/// class ViewController: UIViewController, TETextSelectionManagerDelegate {
///     func selectionManager(_ manager: TETextSelectionManager, didChangeSelection range: TETextSelectionRange?) {
///         print("选择范围改变: \(range?.location ?? -1), \(range?.length ?? 0)")
///     }
///     
///     func selectionManager(_ manager: TETextSelectionManager, willShowMenu menu: UIMenu) {
///         print("编辑菜单将要显示")
///     }
///     
///     func selectionManager(_ manager: TETextSelectionManager, shouldCopyText text: String) -> Bool {
///         return true // 允许复制文本
///     }
/// }
/// ```
public protocol TETextSelectionManagerDelegate: AnyObject {
    /// 选择范围改变
    func selectionManager(_ manager: TETextSelectionManager, didChangeSelection range: TETextSelectionRange?)
    
    /// 选择菜单将要显示
    func selectionManager(_ manager: TETextSelectionManager, willShowMenu menu: UIMenu)
    
    /// 文本应该被复制
    func selectionManager(_ manager: TETextSelectionManager, shouldCopyText text: String) -> Bool
}

/// 文本选择管理器
/// 管理文本选择、复制粘贴和选择手柄
/// 
/// 功能特性:
/// - 文本选择和范围管理
/// - 复制粘贴操作支持
/// - 选择手柄拖拽交互
/// - 选择高亮显示
/// - 编辑菜单集成
/// - 委托模式扩展
/// 
/// 使用示例:
/// ```swift
/// class TextView: UIView {
///     private let selectionManager = TETextSelectionManager()
///     
///     override func awakeFromNib() {
///         super.awakeFromNib()
///         setupSelectionManager()
///     }
///     
///     private func setupSelectionManager() {
///         selectionManager.delegate = self
///         selectionManager.isSelectionEnabled = true
///         selectionManager.isSelectionHandleEnabled = true
///         selectionManager.selectionColor = UIColor.systemBlue.withAlphaComponent(0.3)
///         selectionManager.handleColor = .systemBlue
///     }
///     
///     func handleLongPress(_ gesture: UILongPressGestureRecognizer) {
///         let location = gesture.location(in: self)
///         switch gesture.state {
///         case .began:
///             selectionManager.startSelection(at: location, in: self)
///         case .changed:
///             selectionManager.updateSelection(to: location)
///         default:
///             break
///         }
///     }
/// }
/// ```
@MainActor
public final class TETextSelectionManager: NSObject {
    
    // MARK: - 属性
    
    /// 代理对象，接收选择管理器的事件通知
    /// - 必须实现 `TETextSelectionManagerDelegate` 协议
    /// - 用于监听选择范围变化、菜单显示等事件
    public weak var delegate: TETextSelectionManagerDelegate?
    
    /// 当前选择范围
    /// - 返回当前选中的文本范围，如果没有选择则为 `nil`
    /// - 只读属性，通过 `selectRange(_:)` 方法设置
    public private(set) var selectedRange: TETextSelectionRange?
    
    /// 是否启用文本选择功能
    /// - 设置为 `true` 时允许用户选择和复制文本
    /// - 设置为 `false` 时禁用所有选择相关功能
    /// - 默认值为 `true`
    public var isSelectionEnabled: Bool = true
    
    /// 是否显示选择手柄
    /// - 设置为 `true` 时显示拖拽手柄用于调整选择范围
    /// - 设置为 `false` 时隐藏手柄，只允许长按选择
    /// - 默认值为 `true`
    public var isSelectionHandleEnabled: Bool = true
    
    /// 选择高亮颜色
    /// - 用于渲染选中文本的背景色
    /// - 默认值为半透明的系统蓝色
    /// - 可以自定义为任何颜色，建议使用半透明颜色
    public var selectionColor: UIColor = UIColor.systemBlue.withAlphaComponent(0.3)
    
    /// 选择文本颜色
    /// - 用于改变选中文本的前景色
    /// - 如果为 `nil`，则保持文本原有颜色
    /// - 可以用于提高选中文本的可读性
    public var selectionTextColor: UIColor?
    
    /// 选择手柄大小
    /// - 定义选择手柄的触摸区域大小
    /// - 默认值为 20x20 点
    /// - 可以根据需要调整手柄大小以提高可用性
    public var handleSize: CGSize = CGSize(width: 20, height: 20)
    
    /// 选择手柄颜色
    /// - 定义选择手柄的外观颜色
    /// - 默认值为系统蓝色
    /// - 建议与选择颜色保持协调
    public var handleColor: UIColor = .systemBlue
    
    /// 长按手势识别器
    private var longPressGestureRecognizer: UILongPressGestureRecognizer?
    
    /// 选择手柄视图
    private var startHandleView: TESelectionHandleView?
    private var endHandleView: TESelectionHandleView?
    
    /// 选择高亮图层
    private var selectionLayer: CALayer?
    
    /// 容器视图
    private weak var containerView: UIView?
    
    /// 属性文本
    private var attributedText: NSAttributedString?
    
    /// 布局信息
    private var layoutInfo: TELayoutInfo?
    
    /// 复制板管理器
    private let clipboardManager = TEClipboardManager()
    
    /// 选择开始位置
    private var selectionStartPoint: CGPoint?
    
    /// 是否正在拖拽手柄
    private var isDraggingHandle: Bool = false
    
    /// 拖拽的手柄类型
    private enum DragHandleType {
        case start
        case end
    }
    private var draggingHandleType: DragHandleType?
    
    // MARK: - 初始化
    
    public override init() {
        super.init()
        setupNotificationObservers()
    }
    
    deinit {
        removeNotificationObservers()
    }
    
    // MARK: - 公共方法
    
    /// 设置容器视图
    /// - 配置文本选择管理器的容器视图，用于显示选择手柄和高亮
    /// - 会自动设置手势识别器和选择图层
    /// 
    /// 使用示例:
    /// ```swift
    /// let textView = UIView()
    /// selectionManager.setupContainerView(textView)
    /// ```
    /// 
    /// - Parameter view: 用于显示选择UI的容器视图
    public func setupContainerView(_ view: UIView) {
        self.containerView = view
        setupGestureRecognizers()
        setupSelectionLayer()
    }
    
    /// 更新文本和布局信息
    /// - 更新选择管理器使用的文本内容和布局信息
    /// - 会自动清除当前选择状态
    /// 
    /// 使用示例:
    /// ```swift
    /// let attributedText = NSAttributedString(string: "Hello World")
    /// let layoutInfo = TELayoutInfo() // 实际的布局信息
    /// selectionManager.updateText(attributedText, layoutInfo: layoutInfo)
    /// ```
    /// 
    /// - Parameters:
    ///   - attributedText: 包含文本和属性的NSAttributedString
    ///   - layoutInfo: 文本布局信息，用于计算字符位置
    public func updateText(_ attributedText: NSAttributedString?, layoutInfo: TELayoutInfo?) {
        self.attributedText = attributedText
        self.layoutInfo = layoutInfo
        clearSelection()
    }
    
    /// 清除当前选择
    /// - 移除所有选择状态，包括选择范围、手柄和高亮
    /// - 通常在文本内容改变或需要重置选择状态时调用
    /// - 会通知代理选择状态已改变
    /// 
    /// 使用示例:
    /// ```swift
    /// // 清除当前选择
    /// selectionManager.clearSelection()
    /// ```
    public func clearSelection() {
        selectedRange = nil
        hideSelectionHandles()
        hideSelectionLayer()
        delegate?.selectionManager(self, didChangeSelection: nil)
    }
    
    /// 选择所有文本
    /// - 选中容器中的所有文本内容
    /// - 如果没有文本内容，则不执行任何操作
    /// - 会自动显示选择高亮和手柄
    /// 
    /// 使用示例:
    /// ```swift
    /// // 选择所有文本
    /// selectionManager.selectAll()
    /// ```
    public func selectAll() {
        guard let text = attributedText else { return }
        let range = TETextSelectionRange(location: 0, length: text.length)
        setSelection(range)
    }
    
    /// 设置选择范围
    /// - 设置特定的文本选择范围
    /// - 如果范围有效，会显示相应的高亮和手柄
    /// - 如果范围为 `nil`，则清除当前选择
    /// - 会通知代理选择状态已改变
    /// 
    /// 使用示例:
    /// ```swift
    /// // 设置选择范围（选择前10个字符）
    /// let range = TETextSelectionRange(location: 0, length: 10)
    /// selectionManager.setSelection(range)
    /// 
    /// // 清除选择
    /// selectionManager.setSelection(nil)
    /// ```
    /// 
    /// - Parameter range: 要设置的选择范围，如果为 `nil` 则清除选择
    public func setSelection(_ range: TETextSelectionRange?) {
        selectedRange = range
        
        if let range = range {
            showSelection(for: range)
            showSelectionHandles(for: range)
        } else {
            hideSelectionHandles()
            hideSelectionLayer()
        }
        
        delegate?.selectionManager(self, didChangeSelection: range)
    }
    
    /// 获取当前选中的文本内容
    /// - 根据当前选择范围从属性文本中提取对应的字符串
    /// - 会进行范围有效性检查，确保不超出文本边界
    /// - 如果没有选择或文本，返回 `nil`
    /// 
    /// 使用示例:
    /// ```swift
    /// if let selectedText = selectionManager.selectedText() {
    ///     print("选中的文本: \(selectedText)")
    /// }
    /// ```
    /// 
    /// - Returns: 选中的文本字符串，如果没有选择则返回 `nil`
    public func selectedText() -> String? {
        guard let range = selectedRange,
              let text = attributedText else { return nil }
        
        let nsRange = range.nsRange
        guard nsRange.location != NSNotFound && nsRange.location + nsRange.length <= text.length else { return nil }
        
        return (text.string as NSString).substring(with: nsRange)
    }
    
    /// 复制当前选中的文本到剪贴板
    /// - 首先获取当前选中的文本
    /// - 通过代理确认是否允许复制
    /// - 如果允许，将文本复制到系统剪贴板
    /// - 显示复制成功的视觉反馈
    /// 
    /// 使用示例:
    /// ```swift
    /// // 复制选中的文本
    /// selectionManager.copySelectedText()
    /// ```
    public func copySelectedText() {
        guard let text = selectedText() else { return }
        
        if delegate?.selectionManager(self, shouldCopyText: text) != false {
            clipboardManager.copyText(text)
            showCopyFeedback()
        }
    }
    
    /// 显示编辑菜单
    /// - 在选择位置显示系统编辑菜单
    /// - 菜单包含复制、全选等操作
    /// - 需要当前有有效的选择范围
    /// 
    /// 使用示例:
    /// ```swift
    /// // 显示编辑菜单
    /// selectionManager.showEditMenu()
    /// ```
    /// 
    /// 注意: 此方法需要在有选择范围时调用，否则会直接返回
    public func showEditMenu() {
        guard let range = selectedRange,
              let containerView = containerView else { return }
        
        let menu = createEditMenu()
        let rect = boundingRect(for: range)
        
        // 显示菜单
        if let textView = containerView as? TETextView {
            textView.showMenu(menu, from: rect)
        }
    }
    
    // MARK: - 私有方法
    
    /// 设置手势识别器
    private func setupGestureRecognizers() {
        guard let containerView = containerView else { return }
        
        // 长按手势
        let longPress = UILongPressGestureRecognizer(target: self, action: #selector(handleLongPress(_:)))
        longPress.minimumPressDuration = 0.5
        containerView.addGestureRecognizer(longPress)
        self.longPressGestureRecognizer = longPress
    }
    
    /// 设置选择图层
    private func setupSelectionLayer() {
        guard let containerView = containerView else { return }
        
        let layer = CALayer()
        layer.backgroundColor = selectionColor.cgColor
        layer.isHidden = true
        containerView.layer.insertSublayer(layer, at: 0)
        self.selectionLayer = layer
    }
    
    /// 处理长按手势
    @objc private func handleLongPress(_ gesture: UILongPressGestureRecognizer) {
        guard isSelectionEnabled,
              let attributedText = attributedText,
              let layoutInfo = layoutInfo else { return }
        
        let location = gesture.location(in: gesture.view)
        
        switch gesture.state {
        case .began:
            // 获取字符索引
            let index = characterIndex(at: location, in: attributedText, layoutInfo: layoutInfo)
            guard index != NSNotFound else { return }
            
            // 选择单词
            let wordRange = wordRange(at: index, in: attributedText.string)
            let selectionRange = TETextSelectionRange(location: wordRange.location, length: wordRange.length)
            
            setSelection(selectionRange)
            showEditMenu()
            
        case .changed, .ended:
            break
            
        default:
            break
        }
    }
    
    /// 显示选择高亮
    /// - Parameter range: 选择范围
    private func showSelection(for range: TETextSelectionRange) {
        guard let containerView = containerView,
              let attributedText = attributedText else { return }
        
        let rect = boundingRect(for: range)
        
        CATransaction.begin()
        CATransaction.setDisableActions(true)
        
        selectionLayer?.frame = rect
        selectionLayer?.isHidden = false
        
        CATransaction.commit()
        
        // 更新选择文本颜色
        if let textColor = selectionTextColor {
            updateSelectionTextColor(textColor, for: range)
        }
    }
    
    /// 隐藏选择图层
    private func hideSelectionLayer() {
        selectionLayer?.isHidden = true
    }
    
    /// 显示选择手柄
    /// - Parameter range: 选择范围
    private func showSelectionHandles(for range: TETextSelectionRange) {
        guard isSelectionHandleEnabled,
              let containerView = containerView else { return }
        
        // 获取开始和结束位置
        let startRect = boundingRect(for: TETextSelectionRange(location: range.location, length: 0))
        let endRect = boundingRect(for: TETextSelectionRange(location: range.location + range.length, length: 0))
        
        // 创建或更新开始手柄
        if startHandleView == nil {
            let handleView = TESelectionHandleView(type: .start)
            handleView.backgroundColor = handleColor
            containerView.addSubview(handleView)
            startHandleView = handleView
            
            // 添加拖拽手势
            let panGesture = UIPanGestureRecognizer(target: self, action: #selector(handleHandlePan(_:)))
            handleView.addGestureRecognizer(panGesture)
        }
        
        // 创建或更新结束手柄
        if endHandleView == nil {
            let handleView = TESelectionHandleView(type: .end)
            handleView.backgroundColor = handleColor
            containerView.addSubview(handleView)
            endHandleView = handleView
            
            // 添加拖拽手势
            let panGesture = UIPanGestureRecognizer(target: self, action: #selector(handleHandlePan(_:)))
            handleView.addGestureRecognizer(panGesture)
        }
        
        // 更新位置
        startHandleView?.center = CGPoint(x: startRect.midX, y: startRect.maxY)
        endHandleView?.center = CGPoint(x: endRect.midX, y: endRect.maxY)
        
        startHandleView?.isHidden = false
        endHandleView?.isHidden = false
    }
    
    /// 隐藏选择手柄
    private func hideSelectionHandles() {
        startHandleView?.isHidden = true
        endHandleView?.isHidden = true
    }
    
    /// 处理手柄拖拽
    @objc private func handleHandlePan(_ gesture: UIPanGestureRecognizer) {
        guard let handleView = gesture.view as? TESelectionHandleView,
              let attributedText = attributedText,
              let layoutInfo = layoutInfo else { return }
        
        let location = gesture.location(in: containerView)
        
        switch gesture.state {
        case .began:
            isDraggingHandle = true
            draggingHandleType = handleView.handleType
            
        case .changed:
            // 获取新的字符索引
            let index = characterIndex(at: location, in: attributedText, layoutInfo: layoutInfo)
            guard index != NSNotFound else { return }
            
            // 更新选择范围
            if let currentRange = selectedRange {
                var newRange: TETextSelectionRange
                
                switch handleView.handleType {
                case .start:
                    let newLocation = min(index, currentRange.location + currentRange.length)
                    let newLength = (currentRange.location + currentRange.length) - newLocation
                    newRange = TETextSelectionRange(location: newLocation, length: newLength)
                    
                case .end:
                    let newLength = index - currentRange.location
                    newRange = TETextSelectionRange(location: currentRange.location, length: newLength)
                }
                
                setSelection(newRange)
            }
            
        case .ended, .cancelled:
            isDraggingHandle = false
            draggingHandleType = nil
            
        default:
            break
        }
    }
    
    /// 获取字符索引
    /// - Parameters:
    ///   - point: 点
    ///   - attributedText: 属性文本
    ///   - layoutInfo: 布局信息
    /// - Returns: 字符索引
    private func characterIndex(at point: CGPoint, in attributedText: NSAttributedString, layoutInfo: TELayoutInfo) -> Int {
        // 这里需要实现基于CoreText的字符索引计算
        // 简化实现，实际需要更复杂的布局计算
        return NSNotFound
    }
    
    /// 获取单词范围
    /// - Parameters:
    ///   - index: 字符索引
    ///   - text: 文本
    /// - Returns: 单词范围
    private func wordRange(at index: Int, in text: String) -> NSRange {
        let nsString = text as NSString
        let range = nsString.rangeOfComposedCharacterSequence(at: index)
        return nsString.rangeOfComposedCharacterSequences(for: range)
    }
    
    /// 获取边界矩形
    /// - Parameter range: 选择范围
    /// - Returns: 边界矩形
    private func boundingRect(for range: TETextSelectionRange) -> CGRect {
        // 这里需要实现基于CoreText的边界计算
        // 简化实现，实际需要更复杂的布局计算
        return .zero
    }
    
    /// 更新选择文本颜色
    /// - Parameters:
    ///   - color: 颜色
    ///   - range: 范围
    private func updateSelectionTextColor(_ color: UIColor, for range: TETextSelectionRange) {
        // 这里需要实现文本颜色更新逻辑
    }
    
    /// 创建编辑菜单
    /// - Returns: 菜单
    private func createEditMenu() -> UIMenu {
        let copyAction = UIAction(title: "复制", image: UIImage(systemName: "doc.on.doc")) { [weak self] _ in
            self?.copySelectedText()
        }
        
        let selectAllAction = UIAction(title: "全选", image: UIImage(systemName: "checkmark.circle")) { [weak self] _ in
            self?.selectAll()
        }
        
        var actions = [copyAction]
        
        // 只有在有选择范围时显示全选
        if selectedRange == nil {
            actions.append(selectAllAction)
        }
        
        return UIMenu(title: "", children: actions)
    }
}

#endif