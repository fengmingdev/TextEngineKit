// 
//  TEPluginManager.swift 
//  TextEngineKit 
// 
//  Created by fengming on 2025/11/17. 
// 
//  插件管理：提供插件生命周期管理与扩展点注册。 
// 
import Foundation
#if canImport(CoreGraphics)
import CoreGraphics
#endif
#if canImport(UIKit)
import UIKit
#elseif canImport(AppKit)
import AppKit
#endif

/// 插件化架构支持
/// 提供可扩展的插件系统，支持动态加载和卸载功能模块，使用 Swift 5.5+ Actor 模型确保并发安全
public actor TEPluginManager {
    
    // MARK: - 插件定义
    
    /// 插件协议
    public protocol TEPlugin: AnyObject {
        /// 插件标识符
        var pluginId: String { get }
        
        /// 插件名称
        var pluginName: String { get }
        
        /// 插件版本
        var pluginVersion: String { get }
        
        /// 插件描述
        var pluginDescription: String { get }
        
        /// 依赖的插件列表
        var dependencies: [String] { get }
        
        /// 初始化插件
        func initialize() throws
        
        /// 启动插件
        func start() throws
        
        /// 停止插件
        func stop()
        
        /// 卸载插件
        func unload()
        
        /// 获取插件配置
        func getConfiguration() -> [String: Any]?
        
        /// 更新插件配置
        func updateConfiguration(_ configuration: [String: Any]) throws
    }
    
    /// 插件扩展点协议
    public protocol TEPluginExtensionPoint {
        /// 扩展点标识符
        var extensionPointId: String { get }
        
        /// 扩展点描述
        var description: String { get }
        
        /// 支持的插件类型
        var supportedPluginTypes: [Any.Type] { get }
        
        /// 注册扩展
        func registerExtension(_ extension: Any) throws
        
        /// 获取所有扩展
        func getExtensions() -> [Any]
        
        /// 获取指定类型的扩展
        func getExtensions<T>(ofType type: T.Type) -> [T]
    }
    
    /// 插件状态
    public enum TEPluginState: String {
        case notLoaded = "未加载"
        case loaded = "已加载"
        case initialized = "已初始化"
        case started = "已启动"
        case stopped = "已停止"
        case error = "错误"
    }
    
    /// 插件信息
    public struct TEPluginInfo {
        let plugin: TEPlugin
        let state: TEPluginState
        let loadTime: TimeInterval?
        let error: Error?
        let metadata: [String: Any]
        
        public init(plugin: TEPlugin, state: TEPluginState, loadTime: TimeInterval? = nil, error: Error? = nil, metadata: [String: Any] = [:]) {
            self.plugin = plugin
            self.state = state
            self.loadTime = loadTime
            self.error = error
            self.metadata = metadata
        }
    }
    
    // MARK: - 单例管理
    
    /// 共享实例
    public nonisolated static let shared = TEPluginManager()
    
    // MARK: - 私有属性
    
    /// 已加载的插件
    private var loadedPlugins: [String: TEPluginInfo] = [:]
    
    /// 扩展点注册表
    private var extensionPoints: [String: TEPluginExtensionPoint] = [:]
    
    // MARK: - 初始化
    
    private init() {
        // 私有初始化，防止外部创建
        // 注意：由于属性包装器现在需要异步访问，我们延迟初始化
    }
    
    // MARK: - 异步初始化
    
    /// 异步初始化插件管理器
    public func initialize() async {
        let logger: TETextLoggerProtocol = await TEContainer.shared.resolve(TETextLoggerProtocol.self)
        logger.log("插件管理器初始化完成", level: .info, category: "plugin", metadata: nil)
        await registerBuiltinExtensionPoints()
    }
    
    // MARK: - 插件管理
    
    /// 加载插件
    /// - Parameter plugin: 要加载的插件
    /// - Throws: 加载失败时抛出错误
    public func loadPlugin(_ plugin: TEPlugin) async throws {
        let pluginId = plugin.pluginId
        let logger: TETextLoggerProtocol = await TEContainer.shared.resolve(TETextLoggerProtocol.self)
        
        // 检查插件是否已加载
        if loadedPlugins[pluginId] != nil {
            logger.log("插件已加载: \(pluginId)", level: .warning, category: "plugin", metadata: nil)
            return
        }
        
        let startTime = CFAbsoluteTimeGetCurrent()
        
        do {
            // 检查依赖
            try await checkDependencies(for: plugin)
            
            // 初始化插件
            try plugin.initialize()
            
            let loadTime = CFAbsoluteTimeGetCurrent() - startTime
            
            loadedPlugins[pluginId] = TEPluginInfo(
                plugin: plugin,
                state: .initialized,
                loadTime: loadTime,
                metadata: [
                    "initialize_time": loadTime,
                    "dependencies": plugin.dependencies
                ]
            )
            
            logger.log("插件加载成功: \(pluginId) (耗时: \(String(format: "%.3f", loadTime))s)", level: .info, category: "plugin", metadata: nil)
            
        } catch {
            let loadTime = CFAbsoluteTimeGetCurrent() - startTime
            
            loadedPlugins[pluginId] = TEPluginInfo(
                plugin: plugin,
                state: .error,
                loadTime: loadTime,
                error: error
            )
            
            logger.log("插件加载失败: \(pluginId) - \(error.localizedDescription)", level: .error, category: "plugin", metadata: nil)
            throw TETextEngineError.pluginLoadFailure(pluginId: pluginId, reason: error.localizedDescription)
        }
    }
    
    /// 卸载插件
    /// - Parameter pluginId: 插件标识符
    public func unloadPlugin(_ pluginId: String) async {
        let logger: TETextLoggerProtocol = await TEContainer.shared.resolve(TETextLoggerProtocol.self)
        
        guard let pluginInfo = loadedPlugins[pluginId] else {
            logger.log("尝试卸载未加载的插件: \(pluginId)", level: .warning, category: "plugin", metadata: nil)
            return
        }
        
        pluginInfo.plugin.unload()
        loadedPlugins.removeValue(forKey: pluginId)
        
        logger.log("插件卸载成功: \(pluginId)", level: .info, category: "plugin", metadata: nil)
    }
    
    /// 启动插件
    /// - Parameter pluginId: 插件标识符
    /// - Throws: 启动失败时抛出错误
    public func startPlugin(_ pluginId: String) async throws {
        await performPluginOperation(pluginId: pluginId, operation: { plugin in
            try plugin.start()
            return .started
        })
    }
    
    /// 停止插件
    /// - Parameter pluginId: 插件标识符
    public func stopPlugin(_ pluginId: String) async {
        await performPluginOperation(pluginId: pluginId, operation: { plugin in
            plugin.stop()
            return .stopped
        })
    }
    
    /// 获取插件信息
    /// - Parameter pluginId: 插件标识符
    /// - Returns: 插件信息
    public func getPluginInfo(_ pluginId: String) -> TEPluginInfo? {
        return loadedPlugins[pluginId]
    }
    
    /// 获取所有插件信息
    /// - Returns: 所有插件信息
    public func getAllPluginInfo() -> [TEPluginInfo] {
        return Array(loadedPlugins.values)
    }
    
    /// 获取指定状态的插件
    /// - Parameter state: 插件状态
    /// - Returns: 符合条件的插件信息
    public func getPlugins(byState state: TEPluginState) -> [TEPluginInfo] {
        return loadedPlugins.values.filter { $0.state == state }
    }
    
    // MARK: - 扩展点管理
    
    /// 注册扩展点
    /// - Parameter extensionPoint: 扩展点
    public func registerExtensionPoint(_ extensionPoint: TEPluginExtensionPoint) async {
        let logger: TETextLoggerProtocol = await TEContainer.shared.resolve(TETextLoggerProtocol.self)
        let extensionPointId = extensionPoint.extensionPointId
        
        if extensionPoints[extensionPointId] != nil {
            logger.log("扩展点已存在: \(extensionPointId)", level: .warning, category: "plugin", metadata: nil)
            return
        }
        
        extensionPoints[extensionPointId] = extensionPoint
        logger.log("扩展点注册成功: \(extensionPointId)", level: .info, category: "plugin", metadata: nil)
    }
    
    /// 获取扩展点
    /// - Parameter extensionPointId: 扩展点标识符
    /// - Returns: 扩展点
    public func getExtensionPoint(_ extensionPointId: String) -> TEPluginExtensionPoint? {
        return extensionPoints[extensionPointId]
    }
    
    /// 注册扩展
    /// - Parameters:
    ///   - extension: 扩展
    ///   - extensionPointId: 扩展点标识符
    /// - Throws: 注册失败时抛出错误
    public func registerExtension(_ extension: Any, to extensionPointId: String) async throws {
        guard let extensionPoint = getExtensionPoint(extensionPointId) else {
            throw TETextEngineError.extensionPointNotFound(extensionPointId)
        }
        
        try extensionPoint.registerExtension(`extension`)
        let logger: TETextLoggerProtocol = await TEContainer.shared.resolve(TETextLoggerProtocol.self)
        logger.log("扩展注册成功: \(extensionPointId)", level: .info, category: "plugin", metadata: nil)
    }
    
    // MARK: - 内置扩展点实现
    
    /// 文本解析器扩展点
    class TETextParserExtensionPoint: TEPluginExtensionPoint {
        var extensionPointId: String { "text.parser" }
        var description: String { "文本解析器扩展点" }
        var supportedPluginTypes: [Any.Type] { [TETextParserPlugin.self] }
        
        private var extensions: [Any] = []
        
        func registerExtension(_ extension: Any) throws {
            guard `extension` is TETextParserPlugin else {
                throw TETextEngineError.invalidExtensionType(expected: TETextParserPlugin.self, actual: type(of: `extension`))
            }
            extensions.append(`extension`)
        }
        
        func getExtensions() -> [Any] {
            return extensions
        }
        
        func getExtensions<T>(ofType type: T.Type) -> [T] {
            return extensions.compactMap { $0 as? T }
        }
    }
    
    /// 文本渲染器扩展点
    class TETextRendererExtensionPoint: TEPluginExtensionPoint {
        var extensionPointId: String { "text.renderer" }
        var description: String { "文本渲染器扩展点" }
        var supportedPluginTypes: [Any.Type] { [TETextRendererPlugin.self] }
        
        private var extensions: [Any] = []
        
        func registerExtension(_ extension: Any) throws {
            guard `extension` is TETextRendererPlugin else {
                throw TETextEngineError.invalidExtensionType(expected: TETextRendererPlugin.self, actual: type(of: `extension`))
            }
            extensions.append(`extension`)
        }
        
        func getExtensions() -> [Any] {
            return extensions
        }
        
        func getExtensions<T>(ofType type: T.Type) -> [T] {
            return extensions.compactMap { $0 as? T }
        }
    }
    
    /// 布局管理器扩展点
    class TELayoutManagerExtensionPoint: TEPluginExtensionPoint {
        var extensionPointId: String { "layout.manager" }
        var description: String { "布局管理器扩展点" }
        var supportedPluginTypes: [Any.Type] { [TELayoutManagerPlugin.self] }
        
        private var extensions: [Any] = []
        
        func registerExtension(_ extension: Any) throws {
            guard `extension` is TELayoutManagerPlugin else {
                throw TETextEngineError.invalidExtensionType(expected: TELayoutManagerPlugin.self, actual: type(of: `extension`))
            }
            extensions.append(`extension`)
        }
        
        func getExtensions() -> [Any] {
            return extensions
        }
        
        func getExtensions<T>(ofType type: T.Type) -> [T] {
            return extensions.compactMap { $0 as? T }
        }
    }
    
    /// 属性提供器扩展点
    class TEAttributeProviderExtensionPoint: TEPluginExtensionPoint {
        var extensionPointId: String { "attribute.provider" }
        var description: String { "属性提供器扩展点" }
        var supportedPluginTypes: [Any.Type] { [TEAttributeProviderPlugin.self] }
        
        private var extensions: [Any] = []
        
        func registerExtension(_ extension: Any) throws {
            guard `extension` is TEAttributeProviderPlugin else {
                throw TETextEngineError.invalidExtensionType(expected: TEAttributeProviderPlugin.self, actual: type(of: `extension`))
            }
            extensions.append(`extension`)
        }
        
        func getExtensions() -> [Any] {
            return extensions
        }
        
        func getExtensions<T>(ofType type: T.Type) -> [T] {
            return extensions.compactMap { $0 as? T }
        }
    }
    
    // MARK: - 内置扩展点
    
    /// 注册内置扩展点
    private func registerBuiltinExtensionPoints() async {
        // 文本解析器扩展点
        await registerExtensionPoint(TETextParserExtensionPoint())
        
        // 文本渲染器扩展点
        await registerExtensionPoint(TETextRendererExtensionPoint())
        
        // 布局管理器扩展点
        await registerExtensionPoint(TELayoutManagerExtensionPoint())
        
        // 属性提供器扩展点
        await registerExtensionPoint(TEAttributeProviderExtensionPoint())
    }
    
    // MARK: - 私有辅助方法
    
    /// 检查插件依赖
    /// - Parameter plugin: 插件
    /// - Throws: 依赖检查失败时抛出错误
    private func checkDependencies(for plugin: TEPlugin) async throws {
        for dependencyId in plugin.dependencies {
            guard let dependencyInfo = loadedPlugins[dependencyId] else {
                throw TETextEngineError.pluginDependencyMissing(pluginId: plugin.pluginId, dependencyId: dependencyId)
            }
            
            guard dependencyInfo.state != .error else {
                throw TETextEngineError.pluginDependencyError(pluginId: plugin.pluginId, dependencyId: dependencyId)
            }
        }
    }
    
    /// 执行插件操作
    /// - Parameters:
    ///   - pluginId: 插件标识符
    ///   - operation: 操作闭包
    private func performPluginOperation(pluginId: String, operation: (TEPlugin) throws -> TEPluginState) async {
        let logger: TETextLoggerProtocol = await TEContainer.shared.resolve(TETextLoggerProtocol.self)
        
        guard let pluginInfo = loadedPlugins[pluginId] else {
            logger.log("插件不存在: \(pluginId)", level: .warning, category: "plugin", metadata: nil)
            return
        }
        
        do {
            let newState = try operation(pluginInfo.plugin)
            
            loadedPlugins[pluginId] = TEPluginInfo(
                plugin: pluginInfo.plugin,
                state: newState,
                loadTime: pluginInfo.loadTime,
                metadata: pluginInfo.metadata
            )
            
            logger.log("插件操作成功: \(pluginId) - \(newState.rawValue)", level: .info, category: "plugin", metadata: nil)
            
        } catch {
            loadedPlugins[pluginId] = TEPluginInfo(
                plugin: pluginInfo.plugin,
                state: .error,
                loadTime: pluginInfo.loadTime,
                error: error,
                metadata: pluginInfo.metadata
            )
            
            logger.log("插件操作失败: \(pluginId) - \(error.localizedDescription)", level: .error, category: "plugin", metadata: nil)
        }
    }
}

// MARK: - 内置插件类型

/// 文本解析器插件协议
public protocol TETextParserPlugin: AnyObject {
    /// 解析文本
    /// - Parameter text: 要解析的文本
    /// - Returns: 解析结果
    func parse(_ text: String) -> Result<NSAttributedString, TETextEngineError>
    
    /// 支持的文本格式
    var supportedFormats: [String] { get }
    
    /// 解析器优先级（数值越大优先级越高）
    var priority: Int { get }
}

/// 文本渲染器插件协议
public protocol TETextRendererPlugin: AnyObject {
    /// 渲染文本
    /// - Parameters:
    ///   - attributedString: 属性文本
    ///   - context: 渲染上下文
    ///   - bounds: 渲染边界
    /// - Returns: 渲染结果
    func render(_ attributedString: NSAttributedString, in context: CGContext, bounds: CGRect) -> Result<Void, TETextEngineError>
    
    /// 支持的渲染格式
    var supportedFormats: [TERenderFormat] { get }
    
    /// 渲染器能力
    var capabilities: [TERenderCapability] { get }
}

/// 布局管理器插件协议
public protocol TELayoutManagerPlugin: AnyObject {
    /// 执行布局
    /// - Parameters:
    ///   - attributedString: 属性文本
    ///   - containerSize: 容器尺寸
    ///   - options: 布局配置
    /// - Returns: 布局结果
    func layout(_ attributedString: NSAttributedString, containerSize: CGSize, options: TELayoutConfiguration?) -> Result<TETextLayout, TETextEngineError>
    
    /// 支持的布局类型
    var supportedLayoutTypes: [TELayoutType] { get }
    
    /// 布局器特性
    var features: [TELayoutFeature] { get }
}

/// 属性提供器插件协议
public protocol TEAttributeProviderPlugin: AnyObject {
    /// 提供文本属性
    /// - Parameter text: 文本
    /// - Returns: 文本属性
    func provideAttributes(for text: String) -> [NSAttributedString.Key: Any]
    
    /// 支持的属性类型
    var supportedAttributeTypes: [TEAttributeType] { get }
    
    /// 属性优先级
    var priority: Int { get }
}

/// 渲染格式
public enum TERenderFormat: String, CaseIterable {
    case pdf
    case image
    case printer
    case screen
}

/// 渲染能力
public enum TERenderCapability: String, CaseIterable {
    case gradient
    case shadow
    case animation
    case transparency
    case highPrecision
}

/// 布局类型
public enum TELayoutType: String, CaseIterable {
    case horizontal
    case vertical
    case mixed
    case custom
}

/// 布局特性
public enum TELayoutFeature: String, CaseIterable {
    case lineWrapping
    case characterSpacing
    case paragraphSpacing
    case textAlignment
    case bidirectional
}

/// 布局配置
public struct TELayoutConfiguration {
    public var lineBreakMode: NSLineBreakMode
    public var alignment: NSTextAlignment
    public var lineSpacing: CGFloat
    public var paragraphSpacing: CGFloat
    
    public init(lineBreakMode: NSLineBreakMode = .byWordWrapping,
                alignment: NSTextAlignment = .natural,
                lineSpacing: CGFloat = 0,
                paragraphSpacing: CGFloat = 0) {
        self.lineBreakMode = lineBreakMode
        self.alignment = alignment
        self.lineSpacing = lineSpacing
        self.paragraphSpacing = paragraphSpacing
    }
}

/// 属性类型
public enum TEAttributeType: String, CaseIterable {
    case font
    case color
    case paragraphStyle
    case attachment
    case link
    case shadow
}

// MARK: - 错误扩展

extension TETextEngineError {
    static func pluginLoadFailure(pluginId: String, reason: String) -> TETextEngineError {
        return .invalidParameter(name: "plugin_load_\(pluginId)", value: nil, reason: "插件加载失败: \(reason)")
    }
    
    static func pluginDependencyMissing(pluginId: String, dependencyId: String) -> TETextEngineError {
        return .invalidParameter(name: "plugin_dependency_\(pluginId)", value: dependencyId, reason: "插件依赖缺失")
    }
    
    static func pluginDependencyError(pluginId: String, dependencyId: String) -> TETextEngineError {
        return .invalidParameter(name: "plugin_dependency_\(pluginId)", value: dependencyId, reason: "插件依赖错误")
    }
    
    static func extensionPointNotFound(_ extensionPointId: String) -> TETextEngineError {
        return .invalidParameter(name: "extension_point", value: extensionPointId, reason: "扩展点未找到")
    }
    
    static func invalidExtensionType(expected: Any.Type, actual: Any.Type) -> TETextEngineError {
        return .invalidParameter(name: "extension_type", value: String(describing: actual), reason: "扩展类型不匹配，期望: \(expected)")
    }
}
