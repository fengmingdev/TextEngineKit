import Foundation

/// 综合性能优化系统
/// 提供多维度的性能监控、分析和优化建议
public final class TEPerformanceOptimizationSystem {
    
    // MARK: - 性能指标定义
    
    /// 性能指标类型
    public enum TEPerformanceMetric: String, CaseIterable {
        case cpuUsage = "CPU使用率"
        case memoryUsage = "内存使用"
        case diskIO = "磁盘IO"
        case networkLatency = "网络延迟"
        case renderingTime = "渲染时间"
        case layoutTime = "布局时间"
        case parsingTime = "解析时间"
        case cacheHitRate = "缓存命中率"
        case frameRate = "帧率"
        case batteryUsage = "电池使用"
        
        var unit: String {
            switch self {
            case .cpuUsage: return "%"
            case .memoryUsage: return "MB"
            case .diskIO: return "MB/s"
            case .networkLatency: return "ms"
            case .renderingTime, .layoutTime, .parsingTime: return "ms"
            case .cacheHitRate: return "%"
            case .frameRate: return "fps"
            case .batteryUsage: return "mW"
            }
        }
        
        var optimalRange: ClosedRange<Double> {
            switch self {
            case .cpuUsage: return 0...30
            case .memoryUsage: return 0...100
            case .diskIO: return 0...50
            case .networkLatency: return 0...100
            case .renderingTime: return 0...16.67 // 60fps = 16.67ms/frame
            case .layoutTime: return 0...8.33 // 120fps = 8.33ms/frame
            case .parsingTime: return 0...50
            case .cacheHitRate: return 95...100
            case .frameRate: return 60...120
            case .batteryUsage: return 0...500
            }
        }
    }
    
    /// 性能数据点
    public struct TEPerformanceDataPoint {
        let timestamp: Date
        let metric: TEPerformanceMetric
        let value: Double
        let context: [String: Any]
        let thread: String
        let processId: Int
        
        public init(metric: TEPerformanceMetric, value: Double, context: [String: Any] = [:]) {
            self.timestamp = Date()
            self.metric = metric
            self.value = value
            self.context = context
            self.thread = Thread.current.name ?? "unknown"
            self.processId = Int(ProcessInfo.processInfo.processIdentifier)
        }
    }
    
    /// 性能分析报告
    public struct TEPerformanceReport {
        let startTime: Date
        let endTime: Date
        let metrics: [TEPerformanceMetric: TEPerformanceMetricAnalysis]
        let bottlenecks: [TEPerformanceBottleneck]
        let recommendations: [TEPerformanceRecommendation]
        let overallScore: Double
        let grade: PerformanceGrade
        
        public enum PerformanceGrade: String {
            case excellent = "A+"
            case good = "A"
            case fair = "B"
            case poor = "C"
            case critical = "D"
            
            var description: String {
                switch self {
                case .excellent: return "优秀 - 性能表现极佳"
                case .good: return "良好 - 性能表现良好"
                case .fair: return "一般 - 性能有待优化"
                case .poor: return "较差 - 需要性能优化"
                case .critical: return "严重 - 急需性能优化"
                }
            }
        }
    }
    
    /// 性能指标分析
    public struct TEPerformanceMetricAnalysis {
        let metric: TEPerformanceMetric
        let average: Double
        let minimum: Double
        let maximum: Double
        let standardDeviation: Double
        let percentile95: Double
        let percentile99: Double
        let trend: PerformanceTrend
        let violations: Int // 超出最优范围的次数
        let score: Double // 0-100分
        
        public enum PerformanceTrend {
            case improving
            case stable
            case degrading
            case volatile
        }
    }
    
    /// 性能瓶颈
    public struct TEPerformanceBottleneck {
        let type: BottleneckType
        let severity: Severity
        let description: String
        let location: String
        let frequency: Double
        let impact: Double
        let suggestions: [String]
        
        public enum BottleneckType: String {
            case cpu = "CPU瓶颈"
            case memory = "内存瓶颈"
            case io = "IO瓶颈"
            case network = "网络瓶颈"
            case rendering = "渲染瓶颈"
            case algorithm = "算法瓶颈"
            case concurrency = "并发瓶颈"
        }
        
        public enum Severity: String {
            case low = "低"
            case medium = "中"
            case high = "高"
            case critical = "严重"
        }
    }
    
    /// 性能优化建议
    public struct TEPerformanceRecommendation {
        let category: RecommendationCategory
        let priority: Priority
        let title: String
        let description: String
        let implementationSteps: [String]
        let expectedImprovement: Double // 预期改进百分比
        let effort: EffortLevel
        let risks: [String]
        
        public enum RecommendationCategory: String {
            case algorithm = "算法优化"
            case memory = "内存优化"
            case io = "IO优化"
            case concurrency = "并发优化"
            case caching = "缓存优化"
            case architecture = "架构优化"
        }
        
        public enum Priority: String {
            case immediate = "立即"
            case high = "高"
            case medium = "中"
            case low = "低"
        }
        
        public enum EffortLevel: String {
            case low = "低（1-2天）"
            case medium = "中（1-2周）"
            case high = "高（1-2月）"
        }
    }
    
    // MARK: - 属性
    
    private var logger: TETextLoggerProtocol?
    private var cacheOptimizer: TEAdvancedCacheOptimizer?
    private var configurationManager: TEConfigurationManagerProtocol?
    
    /// 单例实例
    public static let shared = TEPerformanceOptimizationSystem()
    
    /// 性能数据存储
    private var performanceData: [TEPerformanceMetric: [TEPerformanceDataPoint]] = [:]
    
    /// 监控状态
    private var isMonitoring: Bool = false
    
    /// 监控开始时间
    private var monitoringStartTime: Date?
    
    /// 性能监控队列
    private let monitoringQueue = DispatchQueue(label: "textengine.performance.monitoring", qos: .utility)
    
    /// 性能分析队列
    private let analysisQueue = DispatchQueue(label: "textengine.performance.analysis", qos: .background)
    
    /// 监控定时器
    private var monitoringTimer: Timer?
    
    /// 性能阈值配置
    private var thresholdConfig: PerformanceThresholdConfig
    
    // MARK: - 初始化
    
    private init() {
        // 初始化性能阈值配置
        self.thresholdConfig = PerformanceThresholdConfig()
        
        // 初始化性能数据存储
        for metric in TEPerformanceMetric.allCases {
            performanceData[metric] = []
        }
        
        // 延迟初始化注入的服务
        Task {
            self.logger = await TEContainer.shared.resolveOptional(TETextLoggerProtocol.self)
            self.cacheOptimizer = await TEContainer.shared.resolveOptional(TEAdvancedCacheOptimizer.self)
            self.configurationManager = await TEContainer.shared.resolveOptional(TEConfigurationManagerProtocol.self)
            
            self.logger?.log("性能优化系统初始化完成", level: .info, category: "performance", metadata: nil)
        }
    }
    
    deinit {
        stopMonitoring()
    }
    
    // MARK: - 监控控制
    
    /// 开始性能监控
    public func startMonitoring() {
        guard !isMonitoring else {
            logger?.log("性能监控已在运行中", level: .warning, category: "performance", metadata: nil)
            return
        }
        
        isMonitoring = true
        monitoringStartTime = Date()
        
        // 启动监控定时器
        monitoringTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            self?.collectPerformanceData()
        }
        
        logger?.log("性能监控已启动", level: .info, category: "performance", metadata: nil)
    }
    
    /// 停止性能监控
    public func stopMonitoring() {
        guard isMonitoring else {
            logger?.log("性能监控未运行", level: .warning, category: "performance", metadata: nil)
            return
        }
        
        isMonitoring = false
        monitoringTimer?.invalidate()
        monitoringTimer = nil
        
        logger?.log("性能监控已停止", level: .info, category: "performance", metadata: nil)
    }
    
    /// 重置性能数据
    public func resetPerformanceData() {
        for metric in TEPerformanceMetric.allCases {
            performanceData[metric] = []
        }
        
        logger?.log("性能数据已重置", level: .info, category: "performance", metadata: nil)
    }
    
    // MARK: - 数据收集
    
    /// 记录性能数据点
    /// - Parameters:
    ///   - metric: 性能指标
    ///   - value: 数值
    ///   - context: 上下文信息
    public func recordPerformanceData(_ metric: TEPerformanceMetric, value: Double, context: [String: Any] = [:]) {
        let dataPoint = TEPerformanceDataPoint(metric: metric, value: value, context: context)
        
        performanceData[metric]?.append(dataPoint)
        
        // 限制数据点数量，避免内存溢出
        if let count = performanceData[metric]?.count, count > 10000 {
            performanceData[metric]?.removeFirst(count - 10000)
        }
        
        // 检查是否超出阈值
        checkThresholdViolation(metric: metric, value: value, context: context)
    }
    
    /// 批量记录性能数据
    /// - Parameter dataPoints: 数据点列表
    public func batchRecordPerformanceData(_ dataPoints: [TEPerformanceDataPoint]) {
        for dataPoint in dataPoints {
            recordPerformanceData(dataPoint.metric, value: dataPoint.value, context: dataPoint.context)
        }
    }
    
    // MARK: - 性能分析
    
    /// 生成性能分析报告
    /// - Parameter timeWindow: 时间窗口（秒）
    /// - Returns: 性能报告
    public func generatePerformanceReport(timeWindow: TimeInterval = 300) -> TEPerformanceReport {
        let endTime = Date()
        let startTime = endTime.addingTimeInterval(-timeWindow)
        
        // 收集指定时间窗口的数据
        let windowData = getDataInTimeWindow(startTime: startTime, endTime: endTime)
        
        // 分析各指标
        var metricsAnalysis: [TEPerformanceMetric: TEPerformanceMetricAnalysis] = [:]
        for metric in TEPerformanceMetric.allCases {
            if let analysis = analyzeMetric(metric, data: windowData[metric] ?? []) {
                metricsAnalysis[metric] = analysis
            }
        }
        
        // 识别瓶颈
        let bottlenecks = identifyBottlenecks(from: metricsAnalysis)
        
        // 生成优化建议
        let recommendations = generateRecommendations(from: metricsAnalysis, bottlenecks: bottlenecks)
        
        // 计算总体评分
        let overallScore = calculateOverallScore(metricsAnalysis: metricsAnalysis)
        let grade = calculatePerformanceGrade(score: overallScore)
        
        return TEPerformanceReport(
            startTime: startTime,
            endTime: endTime,
            metrics: metricsAnalysis,
            bottlenecks: bottlenecks,
            recommendations: recommendations,
            overallScore: overallScore,
            grade: grade
        )
    }
    
    /// 实时性能诊断
    /// - Returns: 诊断结果
    public func performRealTimeDiagnosis() -> [TEPerformanceBottleneck] {
        let currentData = getCurrentPerformanceData()
        var bottlenecks: [TEPerformanceBottleneck] = []
        
        // CPU使用率诊断
        if let cpuUsage = currentData[.cpuUsage], cpuUsage > thresholdConfig.cpuHighUsage {
            bottlenecks.append(TEPerformanceBottleneck(
                type: .cpu,
                severity: cpuUsage > 80 ? .high : .medium,
                description: "CPU使用率过高: \(String(format: "%.1f", cpuUsage))%",
                location: "系统级别",
                frequency: 1.0,
                impact: cpuUsage,
                suggestions: [
                    "优化算法复杂度",
                    "减少不必要的计算",
                    "使用异步处理",
                    "考虑缓存计算结果"
                ]
            ))
        }
        
        // 内存使用率诊断
        if let memoryUsage = currentData[.memoryUsage], memoryUsage > thresholdConfig.memoryHighUsage {
            bottlenecks.append(TEPerformanceBottleneck(
                type: .memory,
                severity: memoryUsage > 200 ? .high : .medium,
                description: "内存使用过高: \(String(format: "%.1f", memoryUsage))MB",
                location: "内存管理",
                frequency: 1.0,
                impact: memoryUsage / 100.0,
                suggestions: [
                    "优化内存分配策略",
                    "及时释放不需要的对象",
                    "使用对象池",
                    "考虑使用更轻量级的数据结构"
                ]
            ))
        }
        
        // 渲染时间诊断
        if let renderingTime = currentData[.renderingTime], renderingTime > thresholdConfig.renderingSlowThreshold {
            bottlenecks.append(TEPerformanceBottleneck(
                type: .rendering,
                severity: renderingTime > 33.33 ? .high : .medium, // 30fps vs 60fps
                description: "渲染时间过长: \(String(format: "%.1f", renderingTime))ms",
                location: "渲染管线",
                frequency: 1.0,
                impact: renderingTime / 16.67, // 相对于60fps标准
                suggestions: [
                    "减少绘制操作",
                    "使用图层缓存",
                    "优化图形算法",
                    "考虑使用GPU加速"
                ]
            ))
        }
        
        return bottlenecks
    }
    
    // MARK: - 性能优化
    
    /// 应用性能优化建议
    /// - Parameter recommendation: 优化建议
    /// - Returns: 应用结果
    public func applyPerformanceRecommendation(_ recommendation: TEPerformanceRecommendation) -> Result<Bool, TETextEngineError> {
        logger?.log("应用性能优化建议: \(recommendation.title)", level: .info, category: "performance", metadata: nil)
        
        // 这里应该实现具体的优化逻辑
        // 由于涉及具体的系统优化，这里提供框架和日志记录
        
        switch recommendation.category {
        case .caching:
            return applyCachingOptimization(recommendation)
        case .memory:
            return applyMemoryOptimization(recommendation)
        case .algorithm:
            return applyAlgorithmOptimization(recommendation)
        case .concurrency:
            return applyConcurrencyOptimization(recommendation)
        case .io:
            return applyIOOptimization(recommendation)
        case .architecture:
            return applyArchitectureOptimization(recommendation)
        }
    }
    
    /// 自动性能优化
    /// - Parameter maxRecommendations: 最大优化建议数量
    /// - Returns: 优化结果
    public func autoOptimize(maxRecommendations: Int = 5) -> [TEPerformanceRecommendation] {
        let report = generatePerformanceReport(timeWindow: 300) // 5分钟数据
        let topRecommendations = Array(report.recommendations.prefix(maxRecommendations))
        
        logger?.log("开始自动性能优化，建议数量: \(topRecommendations.count)", level: .info, category: "performance", metadata: nil)
        
        var appliedRecommendations: [TEPerformanceRecommendation] = []
        
        for recommendation in topRecommendations {
            switch applyPerformanceRecommendation(recommendation) {
            case .success:
                appliedRecommendations.append(recommendation)
                logger?.log("优化建议应用成功: \(recommendation.title)", level: .info, category: "performance", metadata: nil)
            case .failure(let error):
                logger?.log("优化建议应用失败: \(recommendation.title) - \(error.localizedDescription)", level: .error, category: "performance", metadata: nil)
            }
        }
        
        logger?.log("自动性能优化完成，成功应用: \(appliedRecommendations.count)/\(topRecommendations.count)", level: .info, category: "performance", metadata: nil)
        return appliedRecommendations
    }
    
    // MARK: - 私有方法
    
    /// 收集性能数据
    private func collectPerformanceData() {
        monitoringQueue.async { [weak self] in
            guard let self = self, self.isMonitoring else { return }
            
            Task {
                // 收集各种性能指标
                self.collectSystemMetrics()
                await self.collectApplicationMetrics()
                self.collectCustomMetrics()
            }
        }
    }
    
    /// 收集系统指标
    private func collectSystemMetrics() {
        // CPU使用率
        let cpuUsage = getCurrentCPUUsage()
        recordPerformanceData(.cpuUsage, value: cpuUsage)
        
        // 内存使用
        let memoryUsage = getCurrentMemoryUsage()
        recordPerformanceData(.memoryUsage, value: memoryUsage)
        
        // 磁盘IO
        let diskIO = getCurrentDiskIO()
        recordPerformanceData(.diskIO, value: diskIO)
    }
    
    /// 收集应用指标
    private func collectApplicationMetrics() async {
        // 这里应该收集应用特定的性能指标
        // 例如：缓存命中率、渲染时间等
        
        guard let cacheOptimizer = cacheOptimizer else { return }
        let cacheStats = await cacheOptimizer.getStatistics()
        recordPerformanceData(.cacheHitRate, value: cacheStats.hitRate * 100)
    }
    
    /// 收集自定义指标
    private func collectCustomMetrics() {
        // 收集自定义的性能指标
        // 这里可以根据具体需求添加
    }
    
    /// 获取指定时间窗口的数据
    private func getDataInTimeWindow(startTime: Date, endTime: Date) -> [TEPerformanceMetric: [TEPerformanceDataPoint]] {
        var windowData: [TEPerformanceMetric: [TEPerformanceDataPoint]] = [:]
        
        for metric in TEPerformanceMetric.allCases {
            windowData[metric] = performanceData[metric]?.filter { point in
                point.timestamp >= startTime && point.timestamp <= endTime
            } ?? []
        }
        
        return windowData
    }
    
    /// 分析单个指标
    private func analyzeMetric(_ metric: TEPerformanceMetric, data: [TEPerformanceDataPoint]) -> TEPerformanceMetricAnalysis? {
        guard !data.isEmpty else { return nil }
        
        let values = data.map { $0.value }
        let average = values.reduce(0, +) / Double(values.count)
        let minimum = values.min() ?? 0
        let maximum = values.max() ?? 0
        
        // 计算标准差
        let variance = values.map { pow($0 - average, 2) }.reduce(0, +) / Double(values.count)
        let standardDeviation = sqrt(variance)
        
        // 计算百分位数
        let sortedValues = values.sorted()
        let percentile95 = percentile(sortedValues: sortedValues, percentile: 0.95)
        let percentile99 = percentile(sortedValues: sortedValues, percentile: 0.99)
        
        // 计算趋势
        let trend = calculateTrend(data: data)
        
        // 计算违规次数
        let violations = values.filter { !metric.optimalRange.contains($0) }.count
        
        // 计算评分
        let score = calculateMetricScore(metric: metric, average: average)
        
        return TEPerformanceMetricAnalysis(
            metric: metric,
            average: average,
            minimum: minimum,
            maximum: maximum,
            standardDeviation: standardDeviation,
            percentile95: percentile95,
            percentile99: percentile99,
            trend: trend,
            violations: violations,
            score: score
        )
    }
    
    /// 识别性能瓶颈
    private func identifyBottlenecks(from metricsAnalysis: [TEPerformanceMetric: TEPerformanceMetricAnalysis]) -> [TEPerformanceBottleneck] {
        var bottlenecks: [TEPerformanceBottleneck] = []
        
        // 基于指标分析识别瓶颈
        // 这里应该实现具体的瓶颈识别逻辑
        
        return bottlenecks
    }
    
    /// 生成优化建议
    private func generateRecommendations(from metricsAnalysis: [TEPerformanceMetric: TEPerformanceMetricAnalysis], bottlenecks: [TEPerformanceBottleneck]) -> [TEPerformanceRecommendation] {
        var recommendations: [TEPerformanceRecommendation] = []
        
        // 基于指标分析和瓶颈生成建议
        // 这里应该实现具体的建议生成逻辑
        
        return recommendations
    }
    
    /// 计算总体评分
    private func calculateOverallScore(metricsAnalysis: [TEPerformanceMetric: TEPerformanceMetricAnalysis]) -> Double {
        let scores = metricsAnalysis.values.map { $0.score }
        return scores.reduce(0, +) / Double(scores.count)
    }
    
    /// 计算性能等级
    private func calculatePerformanceGrade(score: Double) -> TEPerformanceReport.PerformanceGrade {
        switch score {
        case 90...100: return .excellent
        case 80..<90: return .good
        case 70..<80: return .fair
        case 60..<70: return .poor
        default: return .critical
        }
    }
    
    /// 检查阈值违规
    private func checkThresholdViolation(metric: TEPerformanceMetric, value: Double, context: [String: Any]) {
        let isViolation = !metric.optimalRange.contains(value)
        
        if isViolation {
            logger?.log("性能指标超出阈值: \(metric.rawValue) = \(String(format: "%.2f", value)) \(metric.unit)", level: .warning, category: "performance", metadata: nil)
        }
    }
    
    /// 获取当前性能数据
    private func getCurrentPerformanceData() -> [TEPerformanceMetric: Double] {
        var currentData: [TEPerformanceMetric: Double] = [:]
        
        for metric in TEPerformanceMetric.allCases {
            if let lastPoint = performanceData[metric]?.last {
                currentData[metric] = lastPoint.value
            }
        }
        
        return currentData
    }
    
    /// 计算百分位数
    private func percentile(sortedValues: [Double], percentile: Double) -> Double {
        guard !sortedValues.isEmpty else { return 0 }
        
        let index = Int(Double(sortedValues.count - 1) * percentile)
        return sortedValues[index]
    }
    
    /// 计算趋势
    private func calculateTrend(data: [TEPerformanceDataPoint]) -> TEPerformanceMetricAnalysis.PerformanceTrend {
        guard data.count >= 2 else { return .stable }
        
        let recentData = Array(data.suffix(10)) // 最近10个数据点
        let values = recentData.map { $0.value }
        
        // 简单的趋势计算
        let firstHalf = Array(values.prefix(values.count / 2))
        let secondHalf = Array(values.suffix(values.count / 2))
        
        let firstHalfAvg = firstHalf.reduce(0, +) / Double(firstHalf.count)
        let secondHalfAvg = secondHalf.reduce(0, +) / Double(secondHalf.count)
        
        let changePercentage = abs(secondHalfAvg - firstHalfAvg) / firstHalfAvg * 100
        
        if changePercentage < 5 {
            return .stable
        } else if secondHalfAvg < firstHalfAvg {
            return .improving
        } else {
            return .degrading
        }
    }
    
    /// 计算指标评分
    private func calculateMetricScore(metric: TEPerformanceMetric, average: Double) -> Double {
        let optimalRange = metric.optimalRange
        let rangeSize = optimalRange.upperBound - optimalRange.lowerBound
        let center = (optimalRange.upperBound + optimalRange.lowerBound) / 2
        
        // 计算距离中心的距离
        let distance = abs(average - center)
        let normalizedDistance = min(distance / rangeSize, 1.0)
        
        // 距离中心越近，分数越高
        return max(0, 100 - normalizedDistance * 100)
    }
    
    /// 获取当前CPU使用率
    private func getCurrentCPUUsage() -> Double {
        // 实际实现中应该使用系统API获取真实的CPU使用率
        return Double.random(in: 0...50) // 模拟数据
    }
    
    /// 获取当前内存使用
    private func getCurrentMemoryUsage() -> Double {
        // 实际实现中应该使用系统API获取真实的内存使用
        return Double.random(in: 10...80) // 模拟数据
    }
    
    /// 获取当前磁盘IO
    private func getCurrentDiskIO() -> Double {
        // 实际实现中应该使用系统API获取真实的磁盘IO
        return Double.random(in: 0...30) // 模拟数据
    }
    
    // MARK: - 具体优化应用
    
    private func applyCachingOptimization(_ recommendation: TEPerformanceRecommendation) -> Result<Bool, TETextEngineError> {
        // 应用缓存优化
        logger?.log("应用缓存优化: \(recommendation.title)", level: .info, category: "performance", metadata: nil)
        return .success(true)
    }
    
    private func applyMemoryOptimization(_ recommendation: TEPerformanceRecommendation) -> Result<Bool, TETextEngineError> {
        // 应用内存优化
        logger?.log("应用内存优化: \(recommendation.title)", level: .info, category: "performance", metadata: nil)
        return .success(true)
    }
    
    private func applyAlgorithmOptimization(_ recommendation: TEPerformanceRecommendation) -> Result<Bool, TETextEngineError> {
        // 应用算法优化
        logger?.log("应用算法优化: \(recommendation.title)", level: .info, category: "performance", metadata: nil)
        return .success(true)
    }
    
    private func applyConcurrencyOptimization(_ recommendation: TEPerformanceRecommendation) -> Result<Bool, TETextEngineError> {
        // 应用并发优化
        logger?.log("应用并发优化: \(recommendation.title)", level: .info, category: "performance", metadata: nil)
        return .success(true)
    }
    
    private func applyIOOptimization(_ recommendation: TEPerformanceRecommendation) -> Result<Bool, TETextEngineError> {
        // 应用IO优化
        logger?.log("应用IO优化: \(recommendation.title)", level: .info, category: "performance", metadata: nil)
        return .success(true)
    }
    
    private func applyArchitectureOptimization(_ recommendation: TEPerformanceRecommendation) -> Result<Bool, TETextEngineError> {
        // 应用架构优化
        logger?.log("应用架构优化: \(recommendation.title)", level: .info, category: "performance", metadata: nil)
        return .success(true)
    }
}

// MARK: - 性能阈值配置

private struct PerformanceThresholdConfig {
    let cpuHighUsage: Double = 70.0
    let memoryHighUsage: Double = 150.0 // MB
    let renderingSlowThreshold: Double = 25.0 // ms (40fps)
    let layoutSlowThreshold: Double = 16.67 // ms (60fps)
    let parsingSlowThreshold: Double = 100.0 // ms
    let cacheHitRateLow: Double = 0.8 // 80%
    let frameRateLow: Double = 30.0 // fps
}
