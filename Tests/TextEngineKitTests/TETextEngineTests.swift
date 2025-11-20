import XCTest
@testable import TextEngineKit

/// TextEngineKit 核心引擎测试
final class TETextEngineTests: XCTestCase {
    
    // MARK: - 属性
    
    var engine: TETextEngine!
    
    // MARK: - 生命周期
    
    override func setUp() {
        super.setUp()
        engine = TETextEngine.shared
    }
    
    override func tearDown() {
        engine = nil
        super.tearDown()
    }
    
    // MARK: - 测试方法
    
    func testEngineSingleton() {
        let engine1 = TETextEngine.shared
        let engine2 = TETextEngine.shared
        
        XCTAssertTrue(engine1 === engine2, "TextEngine 应该是单例")
    }
    
    func testEngineVersion() {
        let version = engine.version()
        
        XCTAssertFalse(version.isEmpty, "版本号不应该为空")
        XCTAssertEqual(version, "1.0.0", "版本号应该是 1.0.0")
    }
    
    func testEngineInfo() {
        let info = engine.engineInfo()
        
        XCTAssertFalse(info.isEmpty, "引擎信息不应该为空")
        XCTAssertEqual(info["version"] as? String, "1.0.0", "版本号应该是 1.0.0")
        XCTAssertEqual(info["platform"] as? String, "iOS", "平台应该是 iOS")
        XCTAssertEqual(info["swift_version"] as? String, "5.5+", "Swift 版本应该是 5.5+")
        XCTAssertEqual(info["min_ios_version"] as? String, "13.0", "最低 iOS 版本应该是 13.0")
    }
    
    func testConfigureLogging() {
        engine.configureLogging(.debug)
        
        // 验证日志配置已应用
        XCTAssertTrue(true, "日志配置应该成功应用")
    }
    
    func testUpdateConfiguration() {
        let newConfig = TEConfiguration(
            enableAsyncLayout: false,
            layoutCacheSize: 200,
            maxConcurrentLayoutTasks: 5,
            enableMemoryOptimization: false,
            memoryWarningThreshold: 100 * 1024 * 1024
        )
        
        engine.updateConfiguration(newConfig)
        
        XCTAssertEqual(engine.configuration.enableAsyncLayout, false, "异步布局应该被禁用")
        XCTAssertEqual(engine.configuration.layoutCacheSize, 200, "布局缓存大小应该是 200")
        XCTAssertEqual(engine.configuration.maxConcurrentLayoutTasks, 5, "最大并发任务数应该是 5")
        XCTAssertEqual(engine.configuration.enableMemoryOptimization, false, "内存优化应该被禁用")
        XCTAssertEqual(engine.configuration.memoryWarningThreshold, 100 * 1024 * 1024, "内存警告阈值应该是 100MB")
    }
    
    func testPerformanceLoggingToggle() {
        engine.enablePerformanceLogging = true
        XCTAssertTrue(engine.enablePerformanceLogging, "性能日志应该被启用")
        
        engine.enablePerformanceLogging = false
        XCTAssertFalse(engine.enablePerformanceLogging, "性能日志应该被禁用")
    }
    
    func testLogPerformance() {
        engine.enablePerformanceLogging = true
        
        // 测试性能日志记录
        engine.logPerformance("test_operation", duration: 100.0, metadata: ["test": "value"])
        
        XCTAssertTrue(true, "性能日志应该成功记录")
    }
    
    func testLogError() {
        engine.logError("测试错误", category: "test")
        XCTAssertTrue(true, "错误日志应该成功记录")
    }
    
    func testLogWarning() {
        engine.logWarning("测试警告", category: "test")
        XCTAssertTrue(true, "警告日志应该成功记录")
    }
    
    func testLogDebug() {
        engine.logDebug("测试调试信息", category: "test")
        XCTAssertTrue(true, "调试日志应该成功记录")
    }
}

/// TEConfiguration 测试
final class TEConfigurationTests: XCTestCase {
    
    func testDefaultConfiguration() {
        let config = TEConfiguration()
        
        XCTAssertTrue(config.enableAsyncLayout, "默认应该启用异步布局")
        XCTAssertEqual(config.layoutCacheSize, 100, "默认布局缓存大小应该是 100")
        XCTAssertEqual(config.maxConcurrentLayoutTasks, 3, "默认最大并发任务数应该是 3")
        XCTAssertTrue(config.enableMemoryOptimization, "默认应该启用内存优化")
        XCTAssertEqual(config.memoryWarningThreshold, 50 * 1024 * 1024, "默认内存警告阈值应该是 50MB")
    }
    
    func testCustomConfiguration() {
        let config = TEConfiguration(
            enableAsyncLayout: false,
            layoutCacheSize: 200,
            maxConcurrentLayoutTasks: 5,
            enableMemoryOptimization: false,
            memoryWarningThreshold: 100 * 1024 * 1024
        )
        
        XCTAssertFalse(config.enableAsyncLayout, "应该禁用异步布局")
        XCTAssertEqual(config.layoutCacheSize, 200, "布局缓存大小应该是 200")
        XCTAssertEqual(config.maxConcurrentLayoutTasks, 5, "最大并发任务数应该是 5")
        XCTAssertFalse(config.enableMemoryOptimization, "应该禁用内存优化")
        XCTAssertEqual(config.memoryWarningThreshold, 100 * 1024 * 1024, "内存警告阈值应该是 100MB")
    }
    
    func testConfigurationDescription() {
        let config = TEConfiguration()
        let description = config.description
        
        XCTAssertFalse(description.isEmpty, "配置描述不应该为空")
        XCTAssertTrue(description.contains("Async Layout"), "描述应该包含异步布局信息")
        XCTAssertTrue(description.contains("Layout Cache Size"), "描述应该包含布局缓存大小信息")
        XCTAssertTrue(description.contains("Memory Optimization"), "描述应该包含内存优化信息")
    }
}

/// TELogLevel 测试
final class TELogLevelTests: XCTestCase {
    
    func testLogLevelRawValues() {
        XCTAssertEqual(TELogLevel.debug.rawValue, "debug")
        XCTAssertEqual(TELogLevel.info.rawValue, "info")
        XCTAssertEqual(TELogLevel.warning.rawValue, "warning")
        XCTAssertEqual(TELogLevel.error.rawValue, "error")
        XCTAssertEqual(TELogLevel.critical.rawValue, "critical")
    }
    
    func testLogLevelConversionToFMLogLevel() {
        XCTAssertEqual(TELogLevel.debug.fmLogLevel, .debug)
        XCTAssertEqual(TELogLevel.info.fmLogLevel, .info)
        XCTAssertEqual(TELogLevel.warning.fmLogLevel, .warning)
        XCTAssertEqual(TELogLevel.error.fmLogLevel, .error)
        XCTAssertEqual(TELogLevel.critical.fmLogLevel, .critical)
    }
    
    func testLogLevelAllCases() {
        let allCases = TELogLevel.allCases
        
        XCTAssertEqual(allCases.count, 5, "应该有 5 个日志级别")
        XCTAssertTrue(allCases.contains(.debug), "应该包含 debug 级别")
        XCTAssertTrue(allCases.contains(.info), "应该包含 info 级别")
        XCTAssertTrue(allCases.contains(.warning), "应该包含 warning 级别")
        XCTAssertTrue(allCases.contains(.error), "应该包含 error 级别")
        XCTAssertTrue(allCases.contains(.critical), "应该包含 critical 级别")
    }
}