import Foundation

/// 模块依赖优化器
/// 分析和优化模块间的依赖关系，减少循环依赖和耦合度
public final class TEModuleDependencyOptimizer {
    
    // MARK: - 依赖关系定义
    
    /// 模块依赖图
    public struct ModuleDependencyGraph {
        let modules: Set<String>
        let dependencies: [String: Set<String>]
        let circularDependencies: [String: Set<String>]
        let dependencyDepth: [String: Int]
        
        public init(modules: Set<String>, dependencies: [String: Set<String>]) {
            self.modules = modules
            self.dependencies = dependencies
            self.circularDependencies = Self.findCircularDependencies(dependencies: dependencies)
            self.dependencyDepth = Self.calculateDependencyDepth(dependencies: dependencies)
        }
        
        /// 查找循环依赖
        private static func findCircularDependencies(dependencies: [String: Set<String>]) -> [String: Set<String>] {
            var circularDeps: [String: Set<String>] = [:]
            
            for (module, deps) in dependencies {
                var circularForModule: Set<String> = []
                
                for dep in deps {
                    if let depDependencies = dependencies[dep], depDependencies.contains(module) {
                        circularForModule.insert(dep)
                    }
                }
                
                if !circularForModule.isEmpty {
                    circularDeps[module] = circularForModule
                }
            }
            
            return circularDeps
        }
        
        /// 计算依赖深度
        private static func calculateDependencyDepth(dependencies: [String: Set<String>]) -> [String: Int] {
            var depth: [String: Int] = [:]
            var visited: Set<String> = []
            
            func calculateDepth(for module: String) -> Int {
                if let existingDepth = depth[module] {
                    return existingDepth
                }
                
                if visited.contains(module) {
                    return 0 // 避免循环
                }
                
                visited.insert(module)
                
                let deps = dependencies[module] ?? []
                let maxDepDepth = deps.map { calculateDepth(for: $0) }.max() ?? 0
                
                let moduleDepth = maxDepDepth + 1
                depth[module] = moduleDepth
                
                visited.remove(module)
                return moduleDepth
            }
            
            for module in dependencies.keys {
                _ = calculateDepth(for: module)
            }
            
            return depth
        }
        
        /// 获取拓扑排序
        public func topologicalSort() -> [String] {
            var visited: Set<String> = []
            var result: [String] = []
            
            func visit(_ module: String) {
                guard !visited.contains(module) else { return }
                
                visited.insert(module)
                
                if let deps = dependencies[module] {
                    for dep in deps.sorted() {
                        visit(dep)
                    }
                }
                
                result.append(module)
            }
            
            for module in modules.sorted() {
                visit(module)
            }
            
            return result.reversed()
        }
    }
    
    // MARK: - 模块定义
    
    /// TextEngineKit 模块定义
    public enum TEModule: String, CaseIterable {
        case core = "Core"
        case ui = "UI"
        case platform = "Platform"
        case parser = "Parser"
        case attributes = "Attributes"
        case vertical = "Vertical"
        case utilities = "Utilities"
        case cache = "Cache"
        case performance = "Performance"
        case errorHandling = "ErrorHandling"
        
        /// 模块描述
        public var description: String {
            switch self {
            case .core: return "核心引擎和依赖注入"
            case .ui: return "UI组件和视图"
            case .platform: return "平台相关功能"
            case .parser: return "文本解析器"
            case .attributes: return "文本属性管理"
            case .vertical: return "垂直文本支持"
            case .utilities: return "工具类和扩展"
            case .cache: return "缓存管理"
            case .performance: return "性能监控"
            case .errorHandling: return "错误处理"
            }
        }
        
        /// 模块职责
        public var responsibilities: [String] {
            switch self {
            case .core:
                return ["依赖注入容器", "服务生命周期管理", "配置管理", "核心引擎"]
            case .ui:
                return ["UILabel扩展", "UITextView扩展", "自定义文本视图", "文本交互"]
            case .platform:
                return ["平台检测", "iOS版本兼容", "设备特性检测"]
            case .parser:
                return ["Markdown解析", "HTML解析", "正则表达式解析", "自定义解析器"]
            case .attributes:
                return ["文本属性设置", "属性转换", "属性验证"]
            case .vertical:
                return ["垂直文本布局", "垂直文本渲染", "中日韩文本支持"]
            case .utilities:
                return ["工具函数", "扩展方法", "常量定义"]
            case .cache:
                return ["布局缓存", "文本缓存", "内存管理"]
            case .performance:
                return ["性能监控", "统计收集", "性能优化"]
            case .errorHandling:
                return ["错误定义", "错误处理", "错误恢复"]
            }
        }
    }
    
    // MARK: - 依赖关系分析
    
    /// 分析当前模块依赖关系
    public func analyzeCurrentDependencies() -> ModuleDependencyGraph {
        let dependencies: [String: Set<String>] = [
            TEModule.core.rawValue: [], // 核心模块无依赖
            TEModule.ui.rawValue: [TEModule.core.rawValue, TEModule.attributes.rawValue],
            TEModule.platform.rawValue: [TEModule.core.rawValue],
            TEModule.parser.rawValue: [TEModule.core.rawValue, TEModule.attributes.rawValue],
            TEModule.attributes.rawValue: [TEModule.core.rawValue],
            TEModule.vertical.rawValue: [TEModule.core.rawValue, TEModule.attributes.rawValue],
            TEModule.utilities.rawValue: [TEModule.core.rawValue],
            TEModule.cache.rawValue: [TEModule.core.rawValue, TEModule.performance.rawValue],
            TEModule.performance.rawValue: [TEModule.core.rawValue, TEModule.errorHandling.rawValue],
            TEModule.errorHandling.rawValue: [TEModule.core.rawValue]
        ]
        
        let modules = Set(TEModule.allCases.map { $0.rawValue })
        return ModuleDependencyGraph(modules: modules, dependencies: dependencies)
    }
    
    // MARK: - 优化建议
    
    /// 依赖优化建议
    public struct DependencyOptimization {
        let module: String
        let issue: String
        let recommendation: String
        let priority: OptimizationPriority
        let estimatedEffort: TimeInterval // 小时
        
        public enum OptimizationPriority: String {
            case high = "高"
            case medium = "中"
            case low = "低"
        }
    }
    
    /// 生成优化建议
    public func generateOptimizationRecommendations() -> [DependencyOptimization] {
        let graph = analyzeCurrentDependencies()
        var recommendations: [DependencyOptimization] = []
        
        // 检查循环依赖
        for (module, circularDeps) in graph.circularDependencies {
            for dep in circularDeps {
                recommendations.append(DependencyOptimization(
                    module: module,
                    issue: "与模块 \(dep) 存在循环依赖",
                    recommendation: "考虑提取公共接口或使用依赖倒置原则",
                    priority: .high,
                    estimatedEffort: 8.0
                ))
            }
        }
        
        // 检查过深的依赖链
        for (module, depth) in graph.dependencyDepth {
            if depth > 3 {
                recommendations.append(DependencyOptimization(
                    module: module,
                    issue: "依赖深度过深 (\(depth) 层)",
                    recommendation: "考虑重构为更扁平的架构",
                    priority: .medium,
                    estimatedEffort: 12.0
                ))
            }
        }
        
        // 检查核心模块过载
        let coreDependencies = graph.dependencies.filter { $0.value.contains(TEModule.core.rawValue) }
        if coreDependencies.count > 6 {
            recommendations.append(DependencyOptimization(
                module: TEModule.core.rawValue,
                issue: "核心模块被过多模块依赖，可能导致耦合",
                recommendation: "考虑将核心模块拆分为更细粒度的子模块",
                priority: .medium,
                estimatedEffort: 16.0
            ))
        }
        
        return recommendations.sorted { $0.priority.rawValue > $1.priority.rawValue }
    }
    
    // MARK: - 重构建议
    
    /// 重构建议
    public struct RefactoringSuggestion {
        let module: String
        let currentIssue: String
        let proposedSolution: String
        let implementationSteps: [String]
        let benefits: [String]
        let risks: [String]
    }
    
    /// 生成重构建议
    public func generateRefactoringSuggestions() -> [RefactoringSuggestion] {
        return [
            RefactoringSuggestion(
                module: "Core",
                currentIssue: "核心模块包含过多职责",
                proposedSolution: "将核心模块拆分为多个专门的子模块",
                implementationSteps: [
                    "1. 提取配置管理到独立的 Configuration 模块",
                    "2. 提取服务注册到独立的 ServiceRegistry 模块",
                    "3. 提取生命周期管理到独立的 Lifecycle 模块",
                    "4. 更新所有依赖引用",
                    "5. 运行完整的测试套件"
                ],
                benefits: [
                    "降低单个模块的复杂度",
                    "提高模块的可测试性",
                    "更好的关注点分离",
                    "更清晰的依赖关系"
                ],
                risks: [
                    "需要大量代码重构",
                    "可能影响现有API",
                    "需要更新文档"
                ]
            ),
            RefactoringSuggestion(
                module: "UI + Parser",
                currentIssue: "UI模块和Parser模块相互依赖",
                proposedSolution: "引入抽象层，使用依赖倒置原则",
                implementationSteps: [
                    "1. 定义 TETextParserProtocol 接口",
                    "2. 定义 TETextRendererProtocol 接口",
                    "3. 让UI模块依赖抽象接口而非具体实现",
                    "4. 在Core模块中协调具体实现",
                    "5. 通过依赖注入提供具体实现"
                ],
                benefits: [
                    "消除循环依赖",
                    "提高模块独立性",
                    "支持多种解析器实现",
                    "更好的可扩展性"
                ],
                risks: [
                    "增加接口设计的复杂性",
                    "可能影响性能",
                    "需要更多的抽象层"
                ]
            ),
            RefactoringSuggestion(
                module: "Cache + Performance",
                currentIssue: "缓存和性能监控紧密耦合",
                proposedSolution: "使用事件驱动架构解耦",
                implementationSteps: [
                    "1. 定义性能事件协议",
                    "2. 实现事件总线",
                    "3. 让缓存模块发布性能事件",
                    "4. 让性能模块订阅相关事件",
                    "5. 移除直接的模块依赖"
                ],
                benefits: [
                    "降低模块耦合度",
                    "支持动态订阅",
                    "更好的可测试性",
                    "支持异步处理"
                ],
                risks: [
                    "增加事件系统的复杂性",
                    "可能引入性能开销",
                    "需要处理事件顺序问题"
                ]
            )
        ]
    }
    
    // MARK: - 依赖注入优化
    
    /// 优化依赖注入配置
    public func optimizeDependencyInjection() -> [String: Any] {
        return [
            "服务生命周期建议": [
                "TETextEngineProtocol": "singleton - 全局共享的引擎实例",
                "TEConfigurationManagerProtocol": "singleton - 配置管理",
                "TETextLoggerProtocol": "singleton - 日志服务",
                "TEPerformanceMonitorProtocol": "singleton - 性能监控",
                "TECacheManagerProtocol": "singleton - 缓存管理",
                "TEStatisticsServiceProtocol": "singleton - 统计服务",
                "TELayoutServiceProtocol": "transient - 布局服务",
                "TERenderingServiceProtocol": "transient - 渲染服务",
                "TEParsingServiceProtocol": "transient - 解析服务",
                "TEPlatformServiceProtocol": "singleton - 平台服务"
            ],
            "依赖注入最佳实践": [
                "1. 优先使用协议而非具体类型",
                "2. 合理使用属性包装器 @Injected",
                "3. 避免循环依赖",
                "4. 为每个服务定义清晰的职责边界",
                "5. 使用适当的生命周期管理",
                "6. 提供默认实现和可配置选项"
            ],
            "性能优化建议": [
                "1. 单例服务预创建，避免运行时开销",
                "2. 瞬态服务延迟创建，减少内存占用",
                "3. 使用线程安全的容器实现",
                "4. 避免频繁的依赖解析操作",
                "5. 缓存频繁使用的服务实例"
            ]
        ]
    }
    
    // MARK: - 架构改进建议
    
    /// 架构改进建议
    public func generateArchitectureImprovements() -> [String: Any] {
        return [
            "短期改进 (1-2周)": [
                "1. 整理现有依赖关系，消除明显的循环依赖",
                "2. 为核心服务定义清晰的协议接口",
                "3. 优化服务注册和解析的性能",
                "4. 添加依赖关系文档和可视化"
            ],
            "中期改进 (1-2个月)": [
                "1. 实现事件驱动的模块间通信",
                "2. 引入插件化架构支持",
                "3. 优化缓存策略和内存管理",
                "4. 增强错误处理和恢复机制"
            ],
            "长期改进 (3-6个月)": [
                "1. 重构核心模块，实现更好的关注点分离",
                "2. 支持动态模块加载和卸载",
                "3. 实现完整的微服务架构",
                "4. 支持跨平台模块复用"
            ]
        ]
    }
    
    // MARK: - 可视化报告
    
    /// 生成依赖关系可视化报告
    public func generateDependencyReport() -> String {
        let graph = analyzeCurrentDependencies()
        let recommendations = generateOptimizationRecommendations()
        let refactorings = generateRefactoringSuggestions()
        
        var report = """
        # TextEngineKit 模块依赖关系分析报告
        
        ## 当前依赖关系图
        
        模块总数: \(graph.modules.count)
        依赖关系总数: \(graph.dependencies.values.reduce(0) { $0 + $1.count })
        
        拓扑排序结果:
        """
        
        for (index, module) in graph.topologicalSort().enumerated() {
            report += "\n\(index + 1). \(module) (深度: \(graph.dependencyDepth[module] ?? 0))"
        }
        
        report += "\n\n## 循环依赖检测"
        
        if graph.circularDependencies.isEmpty {
            report += "\n✅ 未发现循环依赖"
        } else {
            report += "\n⚠️ 发现循环依赖:"
            for (module, deps) in graph.circularDependencies {
                report += "\n- \(module) ↔ \(deps.joined(separator: ", "))"
            }
        }
        
        report += "\n\n## 优化建议"
        
        for (index, recommendation) in recommendations.enumerated() {
            report += """
            \n\n### \(index + 1). \(recommendation.module) - \(recommendation.priority.rawValue)优先级
            **问题**: \(recommendation.issue)
            **建议**: \(recommendation.recommendation)
            **预计工作量**: \(recommendation.estimatedEffort)小时
            """
        }
        
        report += "\n\n## 重构建议"
        
        for (index, suggestion) in refactorings.enumerated() {
            report += """
            \n\n### \(index + 1). \(suggestion.module)模块重构
            **当前问题**: \(suggestion.currentIssue)
            **解决方案**: \(suggestion.proposedSolution)
            
            **实现步骤**:
            """
            
            for step in suggestion.implementationSteps {
                report += "\n- \(step)"
            }
            
            report += "\n\n**预期收益**:\n"
            for benefit in suggestion.benefits {
                report += "\n- \(benefit)"
            }
            
            report += "\n\n**潜在风险**:\n"
            for risk in suggestion.risks {
                report += "\n- \(risk)"
            }
        }
        
        return report
    }
}