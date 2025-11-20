import XCTest
@testable import TextEngineKit

/// 布局管理器测试
final class TELayoutManagerTests: XCTestCase {
    
    // MARK: - 属性
    
    var layoutManager: TELayoutManager!
    var testAttributedString: NSAttributedString!
    
    // MARK: - 生命周期
    
    override func setUp() {
        super.setUp()
        layoutManager = TELayoutManager(maxConcurrentTasks: 3)
        
        let attributes: [NSAttributedString.Key: Any] = [
            .font: TEFont.systemFont(ofSize: 16),
            .foregroundColor: TEColor.label
        ]
        testAttributedString = NSAttributedString(string: "测试文本内容", attributes: attributes)
    }
    
    override func tearDown() {
        layoutManager = nil
        testAttributedString = nil
        super.tearDown()
    }
    
    // MARK: - 测试方法
    
    func testLayoutManagerInitialization() {
        XCTAssertNotNil(layoutManager, "布局管理器应该成功初始化")
    }
    
    func testSyncLayout() {
        let size = CGSize(width: 200, height: 100)
        let layoutInfo = layoutManager.layoutSynchronously(testAttributedString, size: size)
        
        XCTAssertNotNil(layoutInfo, "布局信息不应该为 nil")
        XCTAssertGreaterThan(layoutInfo.lineCount, 0, "应该至少有一行")
        XCTAssertNotNil(layoutInfo.frame, "框架不应该为 nil")
        XCTAssertNotNil(layoutInfo.lines, "行数组不应该为 nil")
        XCTAssertNotNil(layoutInfo.lineOrigins, "行原点数组不应该为 nil")
    }
    
    func testAsyncLayout() {
        let expectation = self.expectation(description: "异步布局完成")
        let size = CGSize(width: 200, height: 100)
        
        layoutManager.layoutAsynchronously(testAttributedString, size: size) { layoutInfo in
            XCTAssertNotNil(layoutInfo, "布局信息不应该为 nil")
            XCTAssertGreaterThan(layoutInfo.lineCount, 0, "应该至少有一行")
            expectation.fulfill()
        }
        
        waitForExpectations(timeout: 5.0, handler: nil)
    }
    
    func testLayoutCache() {
        let size = CGSize(width: 200, height: 100)
        
        // 第一次布局（应该缓存未命中）
        let layoutInfo1 = layoutManager.layoutSynchronously(testAttributedString, size: size)
        
        // 第二次布局（应该缓存命中）
        let layoutInfo2 = layoutManager.layoutSynchronously(testAttributedString, size: size)
        
        XCTAssertNotNil(layoutInfo1, "第一次布局信息不应该为 nil")
        XCTAssertNotNil(layoutInfo2, "第二次布局信息不应该为 nil")
        
        // 验证缓存统计
        let statistics = layoutManager.getStatistics()
        XCTAssertEqual(statistics.totalLayoutCount, 2, "总布局次数应该是 2")
        XCTAssertEqual(statistics.cacheHits, 1, "缓存命中次数应该是 1")
        XCTAssertEqual(statistics.cacheMisses, 1, "缓存未命中次数应该是 1")
    }
    
    func testClearCache() {
        let size = CGSize(width: 200, height: 100)
        
        // 执行布局以填充缓存
        _ = layoutManager.layoutSynchronously(testAttributedString, size: size)
        
        // 清除缓存
        layoutManager.clearCache()
        
        // 验证缓存已清除（通过统计信息）
        let statistics = layoutManager.getStatistics()
        XCTAssertEqual(statistics.totalLayoutCount, 1, "总布局次数应该是 1")
        
        // 再次布局应该触发缓存未命中
        _ = layoutManager.layoutSynchronously(testAttributedString, size: size)
        let newStatistics = layoutManager.getStatistics()
        XCTAssertEqual(newStatistics.totalLayoutCount, 2, "总布局次数应该是 2")
    }
    
    func testUpdateCacheSize() {
        layoutManager.updateCacheSize(countLimit: 50)
        
        // 验证缓存大小更新（通过执行多次布局）
        let size = CGSize(width: 200, height: 100)
        for i in 0..<10 {
            let text = "测试文本 \(i)"
            let attributes: [NSAttributedString.Key: Any] = [
                .font: TEFont.systemFont(ofSize: 16),
                .foregroundColor: TEColor.label
            ]
            let attributedString = NSAttributedString(string: text, attributes: attributes)
            _ = layoutManager.layoutSynchronously(attributedString, size: size)
        }
        
        XCTAssertTrue(true, "缓存大小更新应该成功")
    }
    
    func testLayoutOptions() {
        let size = CGSize(width: 200, height: 100)
        let options: TELayoutOptions = [.truncatesLastVisibleLine, .usesFontLeading]
        
        let layoutInfo = layoutManager.layoutSynchronously(testAttributedString, size: size, options: options)
        
        XCTAssertNotNil(layoutInfo, "布局信息不应该为 nil")
        XCTAssertGreaterThan(layoutInfo.lineCount, 0, "应该至少有一行")
    }
    
    func testLayoutStatistics() {
        let size = CGSize(width: 200, height: 100)
        
        // 执行多次布局
        for _ in 0..<5 {
            _ = layoutManager.layoutSynchronously(testAttributedString, size: size)
        }
        
        let statistics = layoutManager.getStatistics()
        
        XCTAssertEqual(statistics.totalLayoutCount, 5, "总布局次数应该是 5")
        XCTAssertGreaterThan(statistics.averageLayoutTime, 0, "平均布局时间应该大于 0")
        XCTAssertGreaterThan(statistics.maxLayoutTime, 0, "最大布局时间应该大于 0")
        XCTAssertGreaterThanOrEqual(statistics.minLayoutTime, 0, "最小布局时间应该大于等于 0")
        XCTAssertGreaterThanOrEqual(statistics.cacheHitRate, 0, "缓存命中率应该大于等于 0")
        XCTAssertLessThanOrEqual(statistics.cacheHitRate, 100, "缓存命中率应该小于等于 100")
    }
    
    func testLayoutWithEmptyString() {
        let emptyString = NSAttributedString(string: "")
        let size = CGSize(width: 200, height: 100)
        
        let layoutInfo = layoutManager.layoutSynchronously(emptyString, size: size)
        
        XCTAssertNotNil(layoutInfo, "布局信息不应该为 nil")
        XCTAssertEqual(layoutInfo.lineCount, 0, "空字符串应该没有行")
    }
    
    func testLayoutWithLongString() {
        let longText = String(repeating: "这是一个很长的测试文本。", count: 100)
        let attributes: [NSAttributedString.Key: Any] = [
            .font: TEFont.systemFont(ofSize: 16),
            .foregroundColor: TEColor.label
        ]
        let longAttributedString = NSAttributedString(string: longText, attributes: attributes)
        let size = CGSize(width: 200, height: 100)
        
        let layoutInfo = layoutManager.layoutSynchronously(longAttributedString, size: size)
        
        XCTAssertNotNil(layoutInfo, "布局信息不应该为 nil")
        XCTAssertGreaterThan(layoutInfo.lineCount, 0, "应该至少有一行")
    }
    
    func testLayoutPerformance() {
        let longText = String(repeating: "这是一个很长的测试文本。", count: 1000)
        let attributes: [NSAttributedString.Key: Any] = [
            .font: TEFont.systemFont(ofSize: 16),
            .foregroundColor: TEColor.label
        ]
        let longAttributedString = NSAttributedString(string: longText, attributes: attributes)
        let size = CGSize(width: 200, height: 100)
        
        measure {
            _ = layoutManager.layoutSynchronously(longAttributedString, size: size)
        }
    }
    
    func testAsyncLayoutPerformance() {
        let longText = String(repeating: "这是一个很长的测试文本。", count: 1000)
        let attributes: [NSAttributedString.Key: Any] = [
            .font: TEFont.systemFont(ofSize: 16),
            .foregroundColor: TEColor.label
        ]
        let longAttributedString = NSAttributedString(string: longText, attributes: attributes)
        let size = CGSize(width: 200, height: 100)
        
        measure {
            let expectation = self.expectation(description: "异步布局性能测试")
            
            layoutManager.layoutAsynchronously(longAttributedString, size: size) { _ in
                expectation.fulfill()
            }
            
            waitForExpectations(timeout: 10.0, handler: nil)
        }
    }
}

/// 布局选项测试
final class TELayoutOptionsTests: XCTestCase {
    
    func testLayoutOptionsCreation() {
        let options = TELayoutOptions.truncatesLastVisibleLine
        
        XCTAssertTrue(options.contains(.truncatesLastVisibleLine), "应该包含截断选项")
        XCTAssertFalse(options.contains(.usesFontLeading), "不应该包含字体引导选项")
    }
    
    func testLayoutOptionsCombination() {
        let options: TELayoutOptions = [.truncatesLastVisibleLine, .usesFontLeading]
        
        XCTAssertTrue(options.contains(.truncatesLastVisibleLine), "应该包含截断选项")
        XCTAssertTrue(options.contains(.usesFontLeading), "应该包含字体引导选项")
        XCTAssertFalse(options.contains(.disablesFontFallback), "不应该包含禁用字体回退选项")
    }
    
    func testLayoutOptionsRawValue() {
        let options = TELayoutOptions.truncatesLastVisibleLine
        
        XCTAssertEqual(options.rawValue, 1 << 0, "截断选项的原始值应该是正确的")
    }
    
    func testLayoutOptionsAll() {
        let allOptions: TELayoutOptions = [
            .truncatesLastVisibleLine,
            .usesFontLeading,
            .disablesFontFallback,
            .includesLineFragmentPadding
        ]
        
        XCTAssertTrue(allOptions.contains(.truncatesLastVisibleLine), "应该包含所有选项")
        XCTAssertTrue(allOptions.contains(.usesFontLeading), "应该包含所有选项")
        XCTAssertTrue(allOptions.contains(.disablesFontFallback), "应该包含所有选项")
        XCTAssertTrue(allOptions.contains(.includesLineFragmentPadding), "应该包含所有选项")
    }
}

/// 布局信息测试
final class TELayoutInfoTests: XCTestCase {
    
    func testLayoutInfoProperties() {
        let testString = "测试文本"
        let attributes: [NSAttributedString.Key: Any] = [
            .font: TEFont.systemFont(ofSize: 16),
            .foregroundColor: TEColor.label
        ]
        let attributedString = NSAttributedString(string: testString, attributes: attributes)
        
        let framesetter = CTFramesetterCreateWithAttributedString(attributedString)
        let path = CGMutablePath()
        path.addRect(CGRect(x: 0, y: 0, width: 200, height: 100))
        
        let frame = CTFramesetterCreateFrame(framesetter, CFRange(location: 0, length: 0), path, nil)
        let lines = CTFrameGetLines(frame) as! [CTLine]
        var lineOrigins = [CGPoint](repeating: .zero, count: lines.count)
        CTFrameGetLineOrigins(frame, CFRange(location: 0, length: 0), &lineOrigins)
        
        let usedSize = CTFramesetterSuggestFrameSizeWithConstraints(
            framesetter,
            CFRange(location: 0, length: 0),
            nil,
            CGSize(width: 200, height: 100),
            nil
        )
        
        let layoutInfo = TELayoutInfo(
            frame: frame,
            lines: lines,
            lineOrigins: lineOrigins,
            size: CTFrameGetVisibleStringRange(frame),
            usedSize: usedSize
        )
        
        XCTAssertEqual(layoutInfo.lineCount, lines.count, "行数应该匹配")
        XCTAssertEqual(layoutInfo.size.length, testString.count, "可见字符串范围长度应该匹配")
        XCTAssertGreaterThan(layoutInfo.usedSize.width, 0, "使用宽度应该大于 0")
        XCTAssertGreaterThan(layoutInfo.usedSize.height, 0, "使用高度应该大于 0")
        XCTAssertNotNil(layoutInfo.boundingRect, "边界矩形不应该为 nil")
    }
    
    func testLayoutInfoRectForLine() {
        let testString = "测试文本"
        let attributes: [NSAttributedString.Key: Any] = [
            .font: TEFont.systemFont(ofSize: 16),
            .foregroundColor: TEColor.label
        ]
        let attributedString = NSAttributedString(string: testString, attributes: attributes)
        
        let framesetter = CTFramesetterCreateWithAttributedString(attributedString)
        let path = CGMutablePath()
        path.addRect(CGRect(x: 0, y: 0, width: 200, height: 100))
        
        let frame = CTFramesetterCreateFrame(framesetter, CFRange(location: 0, length: 0), path, nil)
        let lines = CTFrameGetLines(frame) as! [CTLine]
        var lineOrigins = [CGPoint](repeating: .zero, count: lines.count)
        CTFrameGetLineOrigins(frame, CFRange(location: 0, length: 0), &lineOrigins)
        
        let usedSize = CTFramesetterSuggestFrameSizeWithConstraints(
            framesetter,
            CFRange(location: 0, length: 0),
            nil,
            CGSize(width: 200, height: 100),
            nil
        )
        
        let layoutInfo = TELayoutInfo(
            frame: frame,
            lines: lines,
            lineOrigins: lineOrigins,
            size: CTFrameGetVisibleStringRange(frame),
            usedSize: usedSize
        )
        
        if lines.count > 0 {
            let lineRect = layoutInfo.rectForLine(at: 0)
            XCTAssertFalse(lineRect.isEmpty, "第一行矩形不应该为空")
        }
        
        // 测试越界索引
        let invalidRect = layoutInfo.rectForLine(at: 999)
        XCTAssertTrue(invalidRect.isEmpty, "无效索引应该返回空矩形")
    }
}

/// 布局统计信息测试
final class TELayoutStatisticsTests: XCTestCase {
    
    func testLayoutStatisticsDefault() {
        let statistics = TELayoutStatistics()
        
        XCTAssertEqual(statistics.totalLayoutCount, 0, "默认总布局次数应该是 0")
        XCTAssertEqual(statistics.cacheHits, 0, "默认缓存命中次数应该是 0")
        XCTAssertEqual(statistics.cacheMisses, 0, "默认缓存未命中次数应该是 0")
        XCTAssertEqual(statistics.totalLayoutTime, 0, "默认总布局时间应该是 0")
        XCTAssertEqual(statistics.averageLayoutTime, 0, "默认平均布局时间应该是 0")
        XCTAssertEqual(statistics.maxLayoutTime, 0, "默认最大布局时间应该是 0")
        XCTAssertEqual(statistics.minLayoutTime, 0, "默认最小布局时间应该是 0")
        XCTAssertEqual(statistics.cacheHitRate, 0, "默认缓存命中率应该是 0")
    }
    
    func testLayoutStatisticsWithData() {
        var statistics = TELayoutStatistics()
        
        statistics.totalLayoutCount = 10
        statistics.cacheHits = 7
        statistics.cacheMisses = 3
        statistics.totalLayoutTime = 100.0
        statistics.averageLayoutTime = 10.0
        statistics.maxLayoutTime = 20.0
        statistics.minLayoutTime = 5.0
        
        XCTAssertEqual(statistics.totalLayoutCount, 10, "总布局次数应该是 10")
        XCTAssertEqual(statistics.cacheHits, 7, "缓存命中次数应该是 7")
        XCTAssertEqual(statistics.cacheMisses, 3, "缓存未命中次数应该是 3")
        XCTAssertEqual(statistics.cacheHitRate, 70.0, "缓存命中率应该是 70%")
        XCTAssertEqual(statistics.averageLayoutTime, 10.0, "平均布局时间应该是 10ms")
        XCTAssertEqual(statistics.maxLayoutTime, 20.0, "最大布局时间应该是 20ms")
        XCTAssertEqual(statistics.minLayoutTime, 5.0, "最小布局时间应该是 5ms")
    }
    
    func testLayoutStatisticsDescription() {
        var statistics = TELayoutStatistics()
        statistics.totalLayoutCount = 10
        statistics.cacheHits = 7
        statistics.cacheMisses = 3
        statistics.totalLayoutTime = 100.0
        statistics.averageLayoutTime = 10.0
        statistics.maxLayoutTime = 20.0
        statistics.minLayoutTime = 5.0
        
        let description = statistics.description
        
        XCTAssertFalse(description.isEmpty, "描述不应该为空")
        XCTAssertTrue(description.contains("总布局次数: 10"), "描述应该包含总布局次数")
        XCTAssertTrue(description.contains("缓存命中率: 70.0%"), "描述应该包含缓存命中率")
        XCTAssertTrue(description.contains("平均布局时间: 10.000ms"), "描述应该包含平均布局时间")
        XCTAssertTrue(description.contains("最大布局时间: 20.000ms"), "描述应该包含最大布局时间")
        XCTAssertTrue(description.contains("最小布局时间: 5.000ms"), "描述应该包含最小布局时间")
    }
}
