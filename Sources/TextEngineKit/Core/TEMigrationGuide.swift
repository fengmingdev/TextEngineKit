// 
//  TEMigrationGuide.swift 
//  TextEngineKit 
// 
//  Created by fengming on 2025/11/17. 
// 
//  迁移指南：指导从旧版单例模式迁移到新版依赖注入架构，含兼容包装与分阶段策略。 
// 
import Foundation
import FMLogger

/// TextEngineKit 迁移指南
/// 帮助用户从旧版单例模式迁移到新版依赖注入框架
public class TEMigrationGuide {
    
    // MARK: - 旧版代码示例
    
    /// 旧版：使用单例模式
    public func legacySingletonUsage() {
        // 旧版代码（不推荐）
        let engine = TETextEngine.shared
        engine.configureLogging(.info)
        engine.updateConfiguration(TEConfiguration())
        
        // 记录性能日志
        engine.logPerformance("legacy_operation", duration: 0.1)
        
        // 获取引擎信息
        let info = engine.engineInfo()
        TETextEngine.shared.log("引擎信息获取", level: .info, category: "migration", metadata: [
            "version": (info["version"] as Any),
            "platform": (info["platform"] as Any)
        ])
    }
    
    // MARK: - 新版代码示例
    
    /// 新版：使用依赖注入
    public func modernDependencyInjectionUsage() async {
        // 1. 注册服务（应用启动时执行一次）
        await TEContainer.shared.registerTextEngineServices()
        
        // 2. 获取引擎实例
        var engine: TETextEngineProtocol = await TEContainer.shared.resolve(TETextEngineProtocol.self)
        
        do {
            // 3. 启动引擎
            try engine.start()
            
            // 4. 配置引擎
            engine.configuration = TEConfiguration()
            
            // 5. 处理文本（使用新的错误处理机制）
            let result = engine.processText("测试文本", options: TEProcessingOptions())
            
            switch result {
            case .success(let attributedString):
                TETextEngine.shared.log("处理成功", level: .info, category: "migration", metadata: [
                    "length": attributedString.length
                ])
            case .failure(let error):
                TETextEngine.shared.log("处理失败", level: .error, category: "migration", metadata: [
                    "reason": error.localizedDescription
                ])
            }
            
            // 6. 停止引擎
            engine.stop()
            
        } catch {
            TETextEngine.shared.log("引擎操作失败", level: .error, category: "migration", metadata: [
                "reason": error.localizedDescription
            ])
        }
    }
    
    // MARK: - 兼容性包装器
    
    /// 兼容性包装器，帮助平滑迁移
    public class TELegacyCompatibilityWrapper {
        
        /// 兼容旧版单例访问
        @available(*, deprecated, message: "请使用依赖注入替代")
        public static var shared: TETextEngineProtocol {
            get async {
                return await TEContainer.shared.resolve(TETextEngineProtocol.self)
            }
        }
        
        /// 兼容旧版配置方法
        @available(*, deprecated, message: "请使用新的配置API")
        public func configureEngine(_ configuration: TEConfiguration) async -> Result<Void, TETextEngineError> {
            var engine = await TELegacyCompatibilityWrapper.shared
            engine.configuration = configuration
            return .success(())
        }
        
        /// 兼容旧版日志方法
        @available(*, deprecated, message: "请使用新的日志服务")
        public func logPerformance(_ operation: String, duration: TimeInterval) async {
            let logger: TETextLoggerProtocol = await TEContainer.shared.resolve(TETextLoggerProtocol.self)
            logger.log("性能: \(operation) 耗时 \(duration)ms", level: .debug, category: "performance", metadata: nil)
        }
    }
    
    // MARK: - 逐步迁移策略
    
    /// 阶段1：最小化改动迁移
    public func phase1MinimalMigration() async {
        // 在应用启动时添加这一行
        await TEContainer.shared.registerTextEngineServices()
        
        // 现有代码可以继续使用 TETextEngine.shared，但会收到弃用警告
        let engine = TETextEngine.shared  // 会触发弃用警告
        engine.configureLogging(.info)
    }
    
    /// 阶段2：使用兼容性包装器
    public func phase2CompatibilityWrapper() async {
        let wrapper = TELegacyCompatibilityWrapper()
        
        // 使用包装器替代直接访问单例
        let engine = await wrapper.configureEngine(TEConfiguration())
        
        switch engine {
        case .success:
            TETextEngine.shared.logInfo("配置成功", category: "migration")
        case .failure(let error):
            TETextEngine.shared.log("配置失败", level: .error, category: "migration", metadata: [
                "reason": error.localizedDescription
            ])
        }
    }
    
    /// 阶段3：完全迁移到依赖注入
    public func phase3FullMigration() async {
        // 使用属性包装器进行干净的依赖注入
        class TextProcessor {
            private var engine: TETextEngineProtocol?
            private var logger: TETextLoggerProtocol?
            
            init() {
                Task {
                    self.engine = await TEContainer.shared.resolve(TETextEngineProtocol.self)
                    self.logger = await TEContainer.shared.resolve(TETextLoggerProtocol.self)
                }
            }
            
            func processText(_ text: String) async -> Result<NSAttributedString, TETextEngineError> {
                guard let engine = engine else {
                    return .failure(.engineNotInitialized)
                }
                return engine.processText(text, options: TEProcessingOptions())
            }
        }
        
        let processor = TextProcessor()
        let result = await processor.processText("测试文本")
        
        switch result {
        case .success(let attributedString):
            print("处理成功: \(attributedString)")
        case .failure(let error):
            print("处理失败: \(error.localizedDescription)")
        }
    }
    
    // MARK: - 常见迁移问题解决方案
    
    /// 问题1：如何处理旧版错误处理
    public func migrateErrorHandling() async {
        // 旧版：使用可选值和错误日志
        func legacyProcessText(_ text: String) -> NSAttributedString? {
            _ = TETextEngine.shared
            // 处理逻辑...
            return nil  // 失败时返回nil
        }
        
        // 新版：使用Result类型进行明确的错误处理
        func modernProcessText(_ text: String) async -> Result<NSAttributedString, TETextEngineError> {
            let engine: TETextEngineProtocol = await TEContainer.shared.resolve(TETextEngineProtocol.self)
            return engine.processText(text, options: TEProcessingOptions())
        }
        
        // 使用新的错误处理
        let result = await modernProcessText("测试文本")
        
        // 处理错误
        if case .failure(let error) = result {
            switch error {
            case .parserFailure(let type, let reason, let input):
                TETextEngine.shared.log("解析失败", level: .error, category: "parsing", metadata: [
                    "type": type,
                    "reason": reason,
                    "input_length": input.count
                ])
            case .cacheError(let operation, let key):
                TETextEngine.shared.log("缓存错误", level: .error, category: "cache", metadata: [
                    "operation": operation,
                    "key_hash": key.hashValue
                ])
            default:
                TETextEngine.shared.log("其他错误", level: .error, category: "error", metadata: [
                    "reason": error.localizedDescription
                ])
            }
        }
    }
    
    /// 问题2：如何处理旧版性能监控
    public func migratePerformanceMonitoring() async {
        // 旧版：直接调用性能日志方法
        func legacyMonitorPerformance() {
            let engine = TETextEngine.shared
            engine.logPerformance("old_operation", duration: 0.1)
            engine.logLayoutPerformance(operation: "layout", textLength: 100, duration: 0.05, cacheHit: true)
        }
        
        // 新版：使用专门的性能监控服务
        func modernMonitorPerformance() async {
            let monitor: TEPerformanceMonitorProtocol = await TEContainer.shared.resolve(TEPerformanceMonitorProtocol.self)
            let logger: TETextLoggerProtocol = await TEContainer.shared.resolve(TETextLoggerProtocol.self)
            
            // 执行操作
            let result = monitor.measure(operation: "modern_operation") {
                // 操作逻辑
                return "操作结果"
            }
            
            logger.log("操作成功: \(result)", level: .info, category: "performance", metadata: nil)
        }
    }
    
    /// 问题3：如何处理线程安全
    public func migrateThreadSafety() {
        // 旧版：手动管理锁
        class LegacyThreadSafeProcessor {
            private let lock = NSLock()
            private var counter = 0
            
            func incrementCounter() {
                lock.lock()
                counter += 1
                lock.unlock()
            }
        }
        
        // 新版：使用属性包装器
        class ModernThreadSafeProcessor {
            @ThreadSafe private var counter = 0
            
            func incrementCounter() {
                counter += 1  // 自动线程安全
            }
        }
    }
    
    // MARK: - 迁移检查清单
    
    /// 迁移检查清单
    public static func migrationChecklist() -> [String] {
        return [
            "✅ 在应用启动时注册所有服务",
            "✅ 替换所有 TETextEngine.shared 调用",
            "✅ 更新错误处理使用 Result 类型",
            "✅ 使用属性包装器 @Injected 进行依赖注入",
            "✅ 使用 @ThreadSafe 确保线程安全",
            "✅ 更新性能监控使用 TEPerformanceMonitorProtocol",
            "✅ 更新日志记录使用 TETextLoggerProtocol",
            "✅ 测试所有迁移后的功能",
            "✅ 移除所有弃用警告",
            "✅ 更新文档和示例代码"
        ]
    }
    
    // MARK: - 性能对比
    
    /// 性能对比分析
    public static func performanceComparison() -> [String: Any] {
        return [
            "旧版单例模式": [
                "优点": "简单直接，易于理解",
                "缺点": "紧耦合，难以测试，全局状态管理困难",
                "适用场景": "简单应用，快速原型"
            ],
            "新版依赖注入": [
                "优点": "松耦合，易于测试，可配置生命周期，更好的错误处理",
                "缺点": "初始设置稍复杂，需要理解依赖注入概念",
                "适用场景": "企业级应用，复杂架构，需要高可测试性"
            ],
            "迁移建议": "对于新项目，强烈推荐使用依赖注入；对于现有项目，建议逐步迁移"
        ]
    }
}
