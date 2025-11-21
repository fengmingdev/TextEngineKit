//
//  TETextDebuggerTests.swift
//  TextEngineKitTests
//
//  Created by Assistant on 2025/11/21.
//
//  调试可视化工具测试
//

import XCTest
#if canImport(UIKit)
import UIKit
#endif
@testable import TextEngineKit

#if canImport(UIKit)
@MainActor
final class TETextDebuggerTests: XCTestCase {
    
    var debugger: TETextDebugger!
    var testLabel: TELabel!
    var mockDelegate: MockDebuggerDelegate!
    
    override func setUp() {
        super.setUp()
        debugger = TETextDebugger.shared
        testLabel = TELabel(frame: CGRect(x: 0, y: 0, width: 200, height: 50))
        mockDelegate = MockDebuggerDelegate()
        debugger.delegate = mockDelegate
    }
    
    override func tearDown() {
        debugger.disableDebugging()
        debugger.clearAllDebugLayers()
        testLabel = nil
        mockDelegate = nil
        super.tearDown()
    }
    
    func testDebuggerInitialization() {
        XCTAssertNotNil(debugger)
        XCTAssertFalse(debugger.isDebuggingEnabled)
        XCTAssertNotNil(debugger.options)
    }
    
    func testEnableDisableDebugging() {
        debugger.enableDebugging()
        XCTAssertTrue(debugger.isDebuggingEnabled)
        
        debugger.disableDebugging()
        XCTAssertFalse(debugger.isDebuggingEnabled)
    }
    
    func testDebugOptions() {
        let options = debugger.options
        
        // 验证默认选项
        XCTAssertTrue(options.showBaselines)
        XCTAssertTrue(options.showLineFragments)
        XCTAssertFalse(options.showGlyphs)
        XCTAssertTrue(options.showExclusionPaths)
        XCTAssertTrue(options.showSelection)
        XCTAssertTrue(options.showAttachments)
        XCTAssertTrue(options.showHighlights)
        XCTAssertEqual(options.lineWidth, 1.0)
        XCTAssertEqual(options.debugFontSize, 10.0)
        XCTAssertEqual(options.debugTextColor, .black)
    }
    
    func testDebugOptionsCustomization() {
        var options = TETextDebugOptions()
        
        options.showBaselines = false
        options.baselineColor = .blue
        options.showLineFragments = false
        options.lineFragmentBorderColor = .green
        options.showGlyphs = true
        options.glyphBorderColor = .red
        options.showExclusionPaths = false
        options.exclusionPathColor = .purple
        options.showSelection = false
        options.selectionColor = .yellow
        options.lineWidth = 2.0
        options.debugFontSize = 12.0
        options.debugTextColor = .white
        
        debugger.options = options
        
        XCTAssertEqual(debugger.options.showBaselines, false)
        XCTAssertEqual(debugger.options.baselineColor, .blue)
        XCTAssertEqual(debugger.options.showLineFragments, false)
        XCTAssertEqual(debugger.options.lineFragmentBorderColor, .green)
        XCTAssertEqual(debugger.options.showGlyphs, true)
        XCTAssertEqual(debugger.options.glyphBorderColor, .red)
        XCTAssertEqual(debugger.options.showExclusionPaths, false)
        XCTAssertEqual(debugger.options.exclusionPathColor, .purple)
        XCTAssertEqual(debugger.options.showSelection, false)
        XCTAssertEqual(debugger.options.selectionColor, .yellow)
        XCTAssertEqual(debugger.options.lineWidth, 2.0)
        XCTAssertEqual(debugger.options.debugFontSize, 12.0)
        XCTAssertEqual(debugger.options.debugTextColor, .white)
    }
    
    func testDebugLabel() {
        debugger.enableDebugging()
        
        let testText = NSAttributedString(string: "Test Debug Label")
        testLabel.attributedText = testText
        
        debugger.debugLabel(testLabel)
        
        XCTAssertTrue(debugger.isDebuggingEnabled)
        XCTAssertTrue(mockDelegate.didCollectDebugInfoCalled)
    }
    
    func testDebugLayout() {
        debugger.enableDebugging()
        
        let testText = NSAttributedString(string: "Test Debug Layout")
        let containerSize = CGSize(width: 200, height: 50)
        
        debugger.debugLayout(attributedText: testText, containerSize: containerSize)
        
        XCTAssertTrue(debugger.isDebuggingEnabled)
        XCTAssertTrue(mockDelegate.didCollectDebugInfoCalled)
    }
    
    func testClearAllDebugLayers() {
        debugger.enableDebugging()
        
        let testText = NSAttributedString(string: "Test Debug")
        testLabel.attributedText = testText
        
        debugger.debugLabel(testLabel)
        debugger.clearAllDebugLayers()
        
        XCTAssertTrue(debugger.isDebuggingEnabled)
    }
    
    func testGetDebugInfoHistory() {
        debugger.enableDebugging()
        
        let testText = NSAttributedString(string: "Test Debug History")
        let containerSize = CGSize(width: 200, height: 50)
        
        // 添加多个调试信息
        for i in 0..<5 {
            let text = NSAttributedString(string: "Test \(i)")
            debugger.debugLayout(attributedText: text, containerSize: containerSize)
        }
        
        let history = debugger.getDebugInfoHistory()
        XCTAssertEqual(history.count, 5)
    }
    
    func testExportDebugReport() {
        debugger.enableDebugging()
        
        let testText = NSAttributedString(string: "Test Debug Report")
        let containerSize = CGSize(width: 200, height: 50)
        
        debugger.debugLayout(attributedText: testText, containerSize: containerSize)
        
        let report = debugger.exportDebugReport()
        
        XCTAssertTrue(report.contains("TextEngineKit Debug Report"))
        XCTAssertTrue(report.contains("Generated:"))
        XCTAssertTrue(report.contains("Debug Info #1"))
    }
    
    func testDebugInfoStructures() {
        // 测试布局信息
        let lineFragment = TETextDebugInfo.LayoutInfo.LineFragmentInfo(
            rect: CGRect(x: 0, y: 0, width: 100, height: 20),
            usedRect: CGRect(x: 0, y: 0, width: 80, height: 20),
            glyphCount: 10,
            characterRange: NSRange(location: 0, length: 10),
            isTruncated: false
        )
        
        XCTAssertEqual(lineFragment.rect, CGRect(x: 0, y: 0, width: 100, height: 20))
        XCTAssertEqual(lineFragment.glyphCount, 10)
        XCTAssertEqual(lineFragment.characterRange.location, 0)
        XCTAssertEqual(lineFragment.characterRange.length, 10)
        XCTAssertFalse(lineFragment.isTruncated)
        
        // 测试基线信息
        let baseline = TETextDebugInfo.LayoutInfo.BaselineInfo(
            y: 15.0,
            ascent: 10.0,
            descent: 3.0,
            leading: 2.0
        )
        
        XCTAssertEqual(baseline.y, 15.0)
        XCTAssertEqual(baseline.ascent, 10.0)
        XCTAssertEqual(baseline.descent, 3.0)
        XCTAssertEqual(baseline.leading, 2.0)
        
        // 测试布局信息
        let layoutInfo = TETextDebugInfo.LayoutInfo(
            lineCount: 2,
            totalGlyphCount: 20,
            totalCharacterCount: 25,
            lineFragments: [lineFragment],
            baselines: [baseline]
        )
        
        XCTAssertEqual(layoutInfo.lineCount, 2)
        XCTAssertEqual(layoutInfo.totalGlyphCount, 20)
        XCTAssertEqual(layoutInfo.totalCharacterCount, 25)
        XCTAssertEqual(layoutInfo.lineFragments.count, 1)
        XCTAssertEqual(layoutInfo.baselines.count, 1)
        
        // 测试性能信息
        let performanceInfo = TETextDebugInfo.PerformanceInfo(
            layoutTime: 0.016,
            renderTime: 0.008,
            totalTime: 0.024,
            memoryUsage: 1024,
            cacheHit: true
        )
        
        XCTAssertEqual(performanceInfo.layoutTime, 0.016)
        XCTAssertEqual(performanceInfo.renderTime, 0.008)
        XCTAssertEqual(performanceInfo.totalTime, 0.024)
        XCTAssertEqual(performanceInfo.memoryUsage, 1024)
        XCTAssertTrue(performanceInfo.cacheHit)
        
        // 测试排除路径信息
        let path = UIBezierPath(rect: CGRect(x: 0, y: 0, width: 50, height: 50))
        let exclusionPathInfo = TETextDebugInfo.ExclusionPathInfo(
            paths: [path],
            validRects: [CGRect(x: 0, y: 0, width: 100, height: 100)],
            excludedArea: 2500.0,
            totalArea: 10000.0
        )
        
        XCTAssertEqual(exclusionPathInfo.paths.count, 1)
        XCTAssertEqual(exclusionPathInfo.validRects.count, 1)
        XCTAssertEqual(exclusionPathInfo.excludedArea, 2500.0)
        XCTAssertEqual(exclusionPathInfo.totalArea, 10000.0)
        
        // 测试选择信息
        let selectionInfo = TETextDebugInfo.SelectionInfo(
            selectedRange: NSRange(location: 0, length: 5),
            selectionRects: [CGRect(x: 0, y: 0, width: 50, height: 20)],
            handlePositions: [CGPoint(x: 0, y: 10), CGPoint(x: 50, y: 10)]
        )
        
        XCTAssertEqual(selectionInfo.selectedRange?.location, 0)
        XCTAssertEqual(selectionInfo.selectedRange?.length, 5)
        XCTAssertEqual(selectionInfo.selectionRects.count, 1)
        XCTAssertEqual(selectionInfo.handlePositions.count, 2)
        
        // 测试调试信息
        let debugInfo = TETextDebugInfo(
            layoutInfo: layoutInfo,
            performanceInfo: performanceInfo,
            exclusionPathInfo: exclusionPathInfo,
            selectionInfo: selectionInfo,
            timestamp: Date()
        )
        
        XCTAssertNotNil(debugInfo.layoutInfo)
        XCTAssertNotNil(debugInfo.performanceInfo)
        XCTAssertNotNil(debugInfo.exclusionPathInfo)
        XCTAssertNotNil(debugInfo.selectionInfo)
        XCTAssertNotNil(debugInfo.timestamp)
    }
}
#endif

// MARK: - Mock Delegate

#if canImport(UIKit)
class MockDebuggerDelegate: TETextDebuggerDelegate {
    var didCollectDebugInfoCalled = false
    var lastDebugInfo: TETextDebugInfo?
    var lastView: UIView?
    
    func debugger(_ debugger: TETextDebugger, didCollectDebugInfo debugInfo: TETextDebugInfo, for view: UIView?) {
        didCollectDebugInfoCalled = true
        lastDebugInfo = debugInfo
        lastView = view
    }
}
#endif
