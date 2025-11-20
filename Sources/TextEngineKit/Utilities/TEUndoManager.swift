import Foundation

/// 撤销管理器
/// 管理文本编辑的撤销和重做操作
public final class TEUndoManager {
    
    // MARK: - 类型定义
    
    /// 撤销操作类型
    private enum UndoOperation {
        case insert(text: String, location: Int)
        case delete(text: String, location: Int)
        case replace(oldText: String, newText: String, location: Int)
    }
    
    // MARK: - 属性
    
    /// 撤销栈
    private var undoStack: [UndoOperation] = []
    
    /// 重做栈
    private var redoStack: [UndoOperation] = []
    
    /// 最大撤销步数
    public var maxUndoCount: Int = 50
    
    /// 代理
    public weak var delegate: TEUndoManagerDelegate?
    
    /// 是否启用撤销
    public var isUndoEnabled: Bool = true
    
    /// 线程安全锁
    private let lock = NSLock()
    
    // MARK: - 初始化
    
    public init() {
        TETextEngine.shared.logDebug("撤销管理器初始化完成", category: "undo")
    }
    
    // MARK: - 公共方法
    
    /// 注册撤销操作（插入）
    /// - Parameters:
    ///   - text: 插入的文本
    ///   - location: 插入位置
    public func registerUndo(with text: String, location: Int) {
        guard isUndoEnabled else { return }
        
        lock.lock()
        defer { lock.unlock() }
        
        let operation = UndoOperation.insert(text: text, location: location)
        undoStack.append(operation)
        
        // 清空重做栈
        redoStack.removeAll()
        
        // 限制撤销栈大小
        if undoStack.count > maxUndoCount {
            undoStack.removeFirst()
        }
        
        TETextEngine.shared.logDebug("注册撤销操作: 插入 length=\(text.count) 在位置 \(location)", category: "undo")
    }
    
    /// 注册撤销操作（删除）
    /// - Parameters:
    ///   - text: 删除的文本
    ///   - location: 删除位置
    ///   - isDeletion: 是否为删除操作
    public func registerUndo(with text: String, location: Int, isDeletion: Bool = true) {
        guard isUndoEnabled else { return }
        
        lock.lock()
        defer { lock.unlock() }
        
        let operation: UndoOperation
        if isDeletion {
            operation = UndoOperation.delete(text: text, location: location)
        } else {
            operation = UndoOperation.insert(text: text, location: location)
        }
        
        undoStack.append(operation)
        
        // 清空重做栈
        redoStack.removeAll()
        
        // 限制撤销栈大小
        if undoStack.count > maxUndoCount {
            undoStack.removeFirst()
        }
        
        TETextEngine.shared.logDebug("注册撤销操作: 删除 length=\(text.count) 在位置 \(location)", category: "undo")
    }
    
    /// 注册撤销操作（替换）
    /// - Parameters:
    ///   - oldText: 旧文本
    ///   - newText: 新文本
    ///   - location: 替换位置
    public func registerUndoReplace(oldText: String, newText: String, location: Int) {
        guard isUndoEnabled else { return }
        
        lock.lock()
        defer { lock.unlock() }
        
        let operation = UndoOperation.replace(oldText: oldText, newText: newText, location: location)
        undoStack.append(operation)
        
        // 清空重做栈
        redoStack.removeAll()
        
        // 限制撤销栈大小
        if undoStack.count > maxUndoCount {
            undoStack.removeFirst()
        }
        
        TETextEngine.shared.logDebug("注册撤销操作: 替换 oldLen=\(oldText.count) -> newLen=\(newText.count) 在位置 \(location)", category: "undo")
    }
    
    /// 执行撤销操作
    public func undo() {
        guard isUndoEnabled else { return }
        
        lock.lock()
        defer { lock.unlock() }
        
        guard let operation = undoStack.popLast() else {
            TETextEngine.shared.logDebug("没有可撤销的操作", category: "undo")
            return
        }
        
        performUndoOperation(operation)
        
        switch operation {
        case .insert(let text, let location):
            TETextEngine.shared.logDebug("执行撤销操作: insert length=\(text.count) at=\(location)", category: "undo")
        case .delete(let text, let location):
            TETextEngine.shared.logDebug("执行撤销操作: delete length=\(text.count) at=\(location)", category: "undo")
        case .replace(let oldText, let newText, let location):
            TETextEngine.shared.logDebug("执行撤销操作: replace oldLen=\(oldText.count) newLen=\(newText.count) at=\(location)", category: "undo")
        }
    }
    
    /// 执行重做操作
    public func redo() {
        guard isUndoEnabled else { return }
        
        lock.lock()
        defer { lock.unlock() }
        
        guard let operation = redoStack.popLast() else {
            TETextEngine.shared.logDebug("没有可重做的操作", category: "undo")
            return
        }
        
        performRedoOperation(operation)
        
        switch operation {
        case .insert(let text, let location):
            TETextEngine.shared.logDebug("执行重做操作: insert length=\(text.count) at=\(location)", category: "undo")
        case .delete(let text, let location):
            TETextEngine.shared.logDebug("执行重做操作: delete length=\(text.count) at=\(location)", category: "undo")
        case .replace(let oldText, let newText, let location):
            TETextEngine.shared.logDebug("执行重做操作: replace oldLen=\(oldText.count) newLen=\(newText.count) at=\(location)", category: "undo")
        }
    }
    
    /// 是否可以撤销
    public var canUndo: Bool {
        lock.lock()
        defer { lock.unlock() }
        return !undoStack.isEmpty
    }
    
    /// 是否可以重做
    public var canRedo: Bool {
        lock.lock()
        defer { lock.unlock() }
        return !redoStack.isEmpty
    }
    
    /// 清空撤销历史
    public func clear() {
        lock.lock()
        defer { lock.unlock() }
        
        undoStack.removeAll()
        redoStack.removeAll()
        
        TETextEngine.shared.logDebug("清空撤销历史", category: "undo")
    }
    
    /// 获取撤销统计信息
    /// - Returns: 统计信息
    public func getStatistics() -> TEUndoStatistics {
        lock.lock()
        defer { lock.unlock() }
        
        return TEUndoStatistics(
            undoCount: undoStack.count,
            redoCount: redoStack.count,
            maxUndoCount: maxUndoCount
        )
    }
    
    // MARK: - 私有方法
    
    /// 执行撤销操作
    /// - Parameter operation: 操作
    private func performUndoOperation(_ operation: UndoOperation) {
        switch operation {
        case .insert(let text, let location):
            // 撤销插入操作：删除插入的文本
            delegate?.undoManager(self, didUndo: "", at: location)
            
            // 将操作添加到重做栈
            let redoOperation = UndoOperation.delete(text: text, location: location)
            redoStack.append(redoOperation)
            
        case .delete(let text, let location):
            // 撤销删除操作：重新插入文本
            delegate?.undoManager(self, didUndo: text, at: location)
            
            // 将操作添加到重做栈
            let redoOperation = UndoOperation.insert(text: text, location: location)
            redoStack.append(redoOperation)
            
        case .replace(let oldText, let newText, let location):
            // 撤销替换操作：恢复旧文本
            delegate?.undoManager(self, didUndo: oldText, at: location)
            
            // 将操作添加到重做栈
            let redoOperation = UndoOperation.replace(oldText: newText, newText: oldText, location: location)
            redoStack.append(redoOperation)
        }
    }
    
    /// 执行重做操作
    /// - Parameter operation: 操作
    private func performRedoOperation(_ operation: UndoOperation) {
        switch operation {
        case .insert(let text, let location):
            // 重做插入操作：重新插入文本
            delegate?.undoManager(self, didRedo: text, at: location)
            
            // 将操作添加到撤销栈
            let undoOperation = UndoOperation.delete(text: text, location: location)
            undoStack.append(undoOperation)
            
        case .delete(let text, let location):
            // 重做删除操作：删除文本
            delegate?.undoManager(self, didRedo: "", at: location)
            
            // 将操作添加到撤销栈
            let undoOperation = UndoOperation.insert(text: text, location: location)
            undoStack.append(undoOperation)
            
        case .replace(let oldText, let newText, let location):
            // 重做替换操作：应用新文本
            delegate?.undoManager(self, didRedo: newText, at: location)
            
            // 将操作添加到撤销栈
            let undoOperation = UndoOperation.replace(oldText: newText, newText: oldText, location: location)
            undoStack.append(undoOperation)
        }
    }
}

// MARK: - 撤销管理器代理

/// 撤销管理器代理
public protocol TEUndoManagerDelegate: AnyObject {
    
    /// 撤销操作执行
    /// - Parameters:
    ///   - manager: 撤销管理器
    ///   - text: 撤销后的文本
    ///   - location: 位置
    func undoManager(_ manager: TEUndoManager, didUndo text: String, at location: Int)
    
    /// 重做操作执行
    /// - Parameters:
    ///   - manager: 撤销管理器
    ///   - text: 重做后的文本
    ///   - location: 位置
    func undoManager(_ manager: TEUndoManager, didRedo text: String, at location: Int)
}

// MARK: - 撤销统计信息

/// 撤销统计信息
public struct TEUndoStatistics {
    /// 撤销操作数
    public let undoCount: Int
    
    /// 重做操作数
    public let redoCount: Int
    
    /// 最大撤销数
    public let maxUndoCount: Int
    
    /// 描述信息
    public var description: String {
        return """
        撤销统计:
        - 撤销操作数: \(undoCount)
        - 重做操作数: \(redoCount)
        - 最大撤销数: \(maxUndoCount)
        """
    }
}