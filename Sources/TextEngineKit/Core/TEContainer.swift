// 
//  TEContainer.swift 
//  TextEngineKit 
// 
//  Created by fengming on 2025/11/17. 
// 
//  依赖注入容器：提供线程安全的服务注册、解析与生命周期管理。 
// 
import Foundation

/// TextEngineKit依赖注入容器
/// 提供统一的依赖管理和生命周期控制，使用 Swift 5.5+ Actor 模型确保并发安全
public actor TEContainer {
    
    // MARK: - 单例实例
    
    /// 共享容器实例（唯一保留的单例）
    public nonisolated static let shared = TEContainer()
    
    // MARK: - 私有属性
    
    /// 服务注册表
    private var services: [String: Any] = [:]
    
    /// 服务工厂函数
    private var factories: [String: () -> Any] = [:]
    
    /// 单例服务缓存
    private var singletons: [String: Any] = [:]
    
    // MARK: - 初始化
    
    private init() {
        // 私有初始化，防止外部创建
        // 注意：actor 的初始化器不能是异步的，所以我们将注册延迟到第一次访问时
    }
    
    // MARK: - 服务注册
    
    /// 注册瞬态服务
    /// - Parameters:
    ///   - type: 服务类型
    ///   - factory: 服务创建工厂
    public func register<T>(_ type: T.Type, factory: @escaping () -> T) {
        let key = String(describing: type)
        factories[key] = factory
    }
    
    /// 注册单例服务
    /// - Parameters:
    ///   - type: 服务类型
    ///   - factory: 服务创建工厂
    public func registerSingleton<T>(_ type: T.Type, factory: @escaping () -> T) {
        let key = String(describing: type)
        factories[key] = factory
        // 预创建单例实例
        singletons[key] = factory()
    }
    
    /// 注册实例
    /// - Parameters:
    ///   - type: 服务类型
    ///   - instance: 服务实例
    public func registerInstance<T>(_ type: T.Type, instance: T) {
        let key = String(describing: type)
        singletons[key] = instance
    }
    
    // MARK: - 服务解析
    
    /// 解析服务实例
    /// - Parameter type: 服务类型
    /// - Returns: 服务实例
    public func resolve<T>(_ type: T.Type) -> T {
        let key = String(describing: type)
        
        // 优先检查单例缓存
        if let singleton = singletons[key] as? T {
            return singleton
        }
        
        // 检查工厂函数
        if let factory = factories[key] as? () -> T {
            return factory()
        }
        
        // 检查瞬态服务
        if let service = services[key] as? T {
            return service
        }
        
        fatalError("未注册的服务类型: \(key)")
    }
    
    /// 解析可选服务实例
    /// - Parameter type: 服务类型
    /// - Returns: 服务实例或nil
    public func resolveOptional<T>(_ type: T.Type) -> T? {
        let key = String(describing: type)
        
        // 优先检查单例缓存
        if let singleton = singletons[key] as? T {
            return singleton
        }
        
        // 检查工厂函数
        if let factory = factories[key] as? () -> T {
            return factory()
        }
        
        // 检查瞬态服务
        return services[key] as? T
    }
    
    // MARK: - 生命周期管理
    
    /// 清除所有服务
    public func clearAll() {
        services.removeAll()
        factories.removeAll()
        singletons.removeAll()
    }
    
    /// 清除瞬态服务
    public func clearTransients() {
        services.removeAll()
    }
    
    // MARK: - 扩展方法
    
    /// 扩展注册方法以支持链式调用
    public struct TEContainerRegistration<T> {
        private let container: TEContainer
        private let type: T.Type
        private let factory: () -> T
        
        init(container: TEContainer, type: T.Type, factory: @escaping () -> T) {
            self.container = container
            self.type = type
            self.factory = factory
        }
        
        /// 标记为单例（异步版本）
        public func asSingleton() async {
            await container.registerSingleton(type, factory: factory)
        }
    }
    
    /// 注册服务并返回可链式调用的注册对象
    public func registerChained<T>(_ type: T.Type, factory: @escaping () -> T) -> TEContainerRegistration<T> {
        return TEContainerRegistration(container: self, type: type, factory: factory)
    }
    
    // MARK: - 异步初始化
    
    /// 异步初始化默认服务
    public func initializeDefaultServices() async {
        // 注册配置服务
        register(TEConfigurationManager.self) { TEConfigurationManager() }
        
        // 注册日志服务
        register(TETextLogger.self) { TETextLogger() }
        
        // 注册性能监控服务
        register(TEPerformanceMonitor.self) { TEPerformanceMonitor() }
        
        // 注册缓存管理服务
        register(TECacheManager.self) { TECacheManager() }
        
        // 注册统计服务
        register(TEStatisticsService.self) { TEStatisticsService() }
        
        // 注册布局服务
        register(TELayoutService.self) { TELayoutService() }
        
        // 注册渲染服务
        register(TERenderingService.self) { TERenderingService() }
        
        // 注册解析服务
        register(TEParsingService.self) { TEParsingService() }
        
        // 注册平台服务
        register(TEPlatformService.self) { TEPlatformService() }
    }
}

/// 依赖注入属性包装器（同步版本，用于非 actor 环境）
@propertyWrapper
public struct Injected<T> {
    private let type: T.Type
    
    public init(_ type: T.Type) {
        self.type = type
    }
    
    public var wrappedValue: T {
        get {
            // 这里我们使用一个同步的访问方式，需要确保容器已经初始化
            // 在实际使用中，应该在应用启动时初始化容器
            fatalError("Injected property wrapper requires async container access. Use await TEContainer.shared.resolve(T.self) instead.")
        }
    }
}

/// 可选依赖注入属性包装器（同步版本）
@propertyWrapper
public struct InjectedOptional<T> {
    private let type: T.Type
    
    public init(_ type: T.Type) {
        self.type = type
    }
    
    public var wrappedValue: T? {
        get {
            // 这里我们使用一个同步的访问方式，需要确保容器已经初始化
            fatalError("InjectedOptional property wrapper requires async container access. Use await TEContainer.shared.resolveOptional(T.self) instead.")
        }
    }
}
