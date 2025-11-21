//
//  TEPerformanceProfilerTests.swift
//  TextEngineKitTests
//
//  Created by Assistant on 2025/11/21.
//
//  性能分析器测试
//

import XCTest
#if canImport(UIKit)
import UIKit
#endif
@testable import TextEngineKit

#if canImport(UIKit)
@MainActor
final class TEPerformanceProfilerTests: XCTestCase {
    
    var profiler: TEPerformanceProfiler!
    var testLabel: TELabel!
    var mockDelegate: MockProfilerDelegate!
    
    override func setUp() {
        super.setUp()
        profiler = TEPerformanceProfiler.shared
        testLabel = TELabel(frame: CGRect(x: 0, y: 0, width: 200, height: 50))
        mockDelegate = MockProfilerDelegate()
        profiler.delegate = mockDelegate
    }
    
    override func tearDown() {
        profiler.stopProfiling()
        profiler.resetPerformanceData()
        testLabel = nil
        mockDelegate = nil
        super.tearDown()
    }
    
    func testProfilerInitialization() {
        XCTAssertNotNil(profiler)
        XCTAssertFalse(profiler.isProfilingEnabled)
        XCTAssertNotNil(profiler.thresholds)
    }
    
    func testStartStopProfiling() {
        profiler.startProfiling()
        XCTAssertTrue(profiler.isProfilingEnabled)
        
        profiler.stopProfiling()
        XCTAssertFalse(profiler.isProfilingEnabled)
    }
    
    func testPerformanceThresholds() {
        let thresholds = profiler.thresholds
        
        // 验证默认阈值
        XCTAssertEqual(thresholds.maxLayoutTime, 0.016)
        XCTAssertEqual(thresholds.maxRenderTime, 0.016)
        XCTAssertEqual(thresholds.maxMemoryUsage, 10 * 1024 * 1024)
        XCTAssertEqual(thresholds.minFPS, 30.0)
        XCTAssertEqual(thresholds.maxCPUUsage, 0.8)
        XCTAssertEqual(thresholds.maxGPUUsage, 0.8)
    }
    
    func testPerformanceThresholdsCustomization() {
        var customThresholds = TEPerformanceProfiler.PerformanceThresholds()
        customThresholds.maxLayoutTime = 0.020
        customThresholds.maxRenderTime = 0.025
        customThresholds.maxMemoryUsage = 20 * 1024 * 1024
        customThresholds.minFPS = 60.0
        customThresholds.maxCPUUsage = 0.9
        customThresholds.maxGPUUsage = 0.85
        
        profiler.thresholds = customThresholds
        
        XCTAssertEqual(profiler.thresholds.maxLayoutTime, 0.020)
        XCTAssertEqual(profiler.thresholds.maxRenderTime, 0.025)
        XCTAssertEqual(profiler.thresholds.maxMemoryUsage, 20 * 1024 * 1024)
        XCTAssertEqual(profiler.thresholds.minFPS, 60.0)
        XCTAssertEqual(profiler.thresholds.maxCPUUsage, 0.9)
        XCTAssertEqual(profiler.thresholds.maxGPUUsage, 0.85)
    }
    
    func testProfileLabel() {
        profiler.startProfiling()
        
        testLabel.attributedText = NSAttributedString(string: "Test Performance")
        let metrics = profiler.profileLabel(testLabel)
        
        XCTAssertNotNil(metrics)
        XCTAssertNotNil(metrics.layoutMetrics)
        XCTAssertNotNil(metrics.renderMetrics)
        XCTAssertNotNil(metrics.overallMetrics)
        XCTAssertNotNil(metrics.timestamp)
        
        XCTAssertTrue(mockDelegate.didCompleteAnalysisCalled)
    }
    
    func testProfileTextView() {
        profiler.startProfiling()
        
        let textView = TETextView(frame: CGRect(x: 0, y: 0, width: 200, height: 100))
        textView.attributedText = NSAttributedString(string: "Test TextView Performance")
        
        let metrics = profiler.profileTextView(textView)
        
        XCTAssertNotNil(metrics)
        XCTAssertNotNil(metrics.layoutMetrics)
        XCTAssertNotNil(metrics.renderMetrics)
        XCTAssertNotNil(metrics.overallMetrics)
        
        XCTAssertTrue(mockDelegate.didCompleteAnalysisCalled)
    }
    
    func testProfileTextRendering() {
        profiler.startProfiling()
        
        let testText = NSAttributedString(string: "Test Text Rendering Performance")
        let containerSize = CGSize(width: 200, height: 100)
        
        let metrics = profiler.profileTextRendering(
            attributedText: testText,
            containerSize: containerSize
        )
        
        XCTAssertNotNil(metrics)
        XCTAssertNotNil(metrics.layoutMetrics)
        XCTAssertNotNil(metrics.renderMetrics)
        XCTAssertNotNil(metrics.overallMetrics)
        
        XCTAssertTrue(mockDelegate.didCompleteAnalysisCalled)
    }
    
    func testProfileTextRenderingWithExclusionPaths() {
        profiler.startProfiling()
        
        let testText = NSAttributedString(string: "Test Text with Exclusion Paths")
        let containerSize = CGSize(width: 300, height: 200)
        let exclusionPath = TEExclusionPath.rect(CGRect(x: 100, y: 50, width: 100, height: 100))
        
        let metrics = profiler.profileTextRendering(
            attributedText: testText,
            containerSize: containerSize,
            exclusionPaths: [exclusionPath]
        )
        
        XCTAssertNotNil(metrics)
        XCTAssertTrue(mockDelegate.didCompleteAnalysisCalled)
    }
    
    func testGetPerformanceHistory() {
        profiler.startProfiling()
        
        // 添加多个性能记录
        for i in 0..<5 {
            let testText = NSAttributedString(string: "Test \(i)")
            let containerSize = CGSize(width: 200, height: 100)
            _ = profiler.profileTextRendering(
                attributedText: testText,
                containerSize: containerSize
            )
        }
        
        let history = profiler.getPerformanceHistory()
        XCTAssertEqual(history.count, 5)
    }
    
    func testGetPerformanceReport() {
        profiler.startProfiling()
        
        let testText = NSAttributedString(string: "Test Performance Report")
        let containerSize = CGSize(width: 200, height: 100)
        
        _ = profiler.profileTextRendering(
            attributedText: testText,
            containerSize: containerSize
        )
        
        let report = profiler.getPerformanceReport()
        
        XCTAssertTrue(report.contains("TextEngineKit Performance Report"))
        XCTAssertTrue(report.contains("Generated:"))
        XCTAssertTrue(report.contains("Average Performance:"))
    }
    
    func testResetPerformanceData() {
        profiler.startProfiling()
        
        let testText = NSAttributedString(string: "Test Reset")
        let containerSize = CGSize(width: 200, height: 100)
        
        _ = profiler.profileTextRendering(
            attributedText: testText,
            containerSize: containerSize
        )
        
        XCTAssertEqual(profiler.getPerformanceHistory().count, 1)
        
        profiler.resetPerformanceData()
        XCTAssertEqual(profiler.getPerformanceHistory().count, 0)
    }
    
    func testPerformanceMetricsStructures() {
        // 测试布局性能指标
        let layoutMetrics = TEPerformanceMetrics.LayoutMetrics(
            layoutTime: 0.016,
            lineCount: 3,
            glyphCount: 50,
            characterCount: 45,
            cacheHit: true,
            memoryUsage: 2048
        )
        
        XCTAssertEqual(layoutMetrics.layoutTime, 0.016)
        XCTAssertEqual(layoutMetrics.lineCount, 3)
        XCTAssertEqual(layoutMetrics.glyphCount, 50)
        XCTAssertEqual(layoutMetrics.characterCount, 45)
        XCTAssertTrue(layoutMetrics.cacheHit)
        XCTAssertEqual(layoutMetrics.memoryUsage, 2048)
        
        // 测试渲染性能指标
        let renderMetrics = TEPerformanceMetrics.RenderMetrics(
            renderTime: 0.008,
            pixelCount: 20000,
            drawCallCount: 2,
            memoryUsage: 1024,
            gpuUsage: 0.2
        )
        
        XCTAssertEqual(renderMetrics.renderTime, 0.008)
        XCTAssertEqual(renderMetrics.pixelCount, 20000)
        XCTAssertEqual(renderMetrics.drawCallCount, 2)
        XCTAssertEqual(renderMetrics.memoryUsage, 1024)
        XCTAssertEqual(renderMetrics.gpuUsage, 0.2)
        
        // 测试整体性能指标
        let overallMetrics = TEPerformanceMetrics.OverallMetrics(
            totalTime: 0.024,
            fps: 60.0,
            cpuUsage: 0.3,
            memoryUsage: 3072,
            energyUsage: 0.1
        )
        
        XCTAssertEqual(overallMetrics.totalTime, 0.024)
        XCTAssertEqual(overallMetrics.fps, 60.0)
        XCTAssertEqual(overallMetrics.cpuUsage, 0.3)
        XCTAssertEqual(overallMetrics.memoryUsage, 3072)
        XCTAssertEqual(overallMetrics.energyUsage, 0.1)
        
        // 测试整体性能指标
        let metrics = TEPerformanceMetrics(
            layoutMetrics: layoutMetrics,
            renderMetrics: renderMetrics,
            overallMetrics: overallMetrics
        )
        
        XCTAssertEqual(metrics.layoutMetrics.layoutTime, 0.016)
        XCTAssertEqual(metrics.renderMetrics.renderTime, 0.008)
        XCTAssertEqual(metrics.overallMetrics.totalTime, 0.024)
        XCTAssertNotNil(metrics.timestamp)
    }
    
    func testPerformanceBottleneck() {
        let metrics = createTestMetrics()
        
        let bottleneck = TEPerformanceBottleneck(
            type: .layoutSlow,
            severity: 0.5,
            description: "Layout time is slow",
            suggestion: "Consider optimizing text layout",
            metrics: metrics
        )
        
        XCTAssertEqual(bottleneck.type, .layoutSlow)
        XCTAssertEqual(bottleneck.severity, 0.5)
        XCTAssertEqual(bottleneck.description, "Layout time is slow")
        XCTAssertEqual(bottleneck.suggestion, "Consider optimizing text layout")
        XCTAssertEqual(bottleneck.metrics.layoutMetrics.layoutTime, 0.020)
    }
    
    func testProfilingWithoutEnabling() {
        // 不启用性能分析直接调用
        let metrics = profiler.profileLabel(testLabel)
        
        // 应该返回空性能指标
        XCTAssertEqual(metrics.layoutMetrics.layoutTime, 0)
        XCTAssertEqual(metrics.renderMetrics.renderTime, 0)
        XCTAssertEqual(metrics.overallMetrics.totalTime, 0)
    }
    
    func testPerformanceBottleneckDetection() {
        profiler.startProfiling()
        
        // 创建性能指标超出阈值的情况
        var customThresholds = TEPerformanceProfiler.PerformanceThresholds()
        customThresholds.maxLayoutTime = 0.001 // 设置很低的阈值
        customThresholds.maxRenderTime = 0.001
        customThresholds.maxMemoryUsage = 100
        customThresholds.minFPS = 120.0
        profiler.thresholds = customThresholds
        
        let testText = NSAttributedString(string: "Test Bottleneck Detection")
        let containerSize = CGSize(width: 200, height: 100)
        
        _ = profiler.profileTextRendering(
            attributedText: testText,
            containerSize: containerSize
        )
        
        // 验证性能瓶颈被检测到
        XCTAssertTrue(mockDelegate.didDetectBottleneckCalled || mockDelegate.didTriggerWarningCalled)
    }
    
    // 辅助方法
    private func createTestMetrics() -> TEPerformanceMetrics {
        let layoutMetrics = TEPerformanceMetrics.LayoutMetrics(
            layoutTime: 0.020,
            lineCount: 2,
            glyphCount: 30,
            characterCount: 25,
            cacheHit: false,
            memoryUsage: 2048
        )
        
        let renderMetrics = TEPerformanceMetrics.RenderMetrics(
            renderTime: 0.015,
            pixelCount: 15000,
            drawCallCount: 1,
            memoryUsage: 1024,
            gpuUsage: 0.3
        )
        
        let overallMetrics = TEPerformanceMetrics.OverallMetrics(
            totalTime: 0.035,
            fps: 45.0,
            cpuUsage: 0.4,
            memoryUsage: 3072,
            energyUsage: 0.2
        )
        
        return TEPerformanceMetrics(
            layoutMetrics: layoutMetrics,
            renderMetrics: renderMetrics,
            overallMetrics: overallMetrics
        )
    }
}

#endif

// MARK: - Mock Delegate

#if canImport(UIKit)
class MockProfilerDelegate: TEPerformanceProfilerDelegate {
    var didCompleteAnalysisCalled = false
    var didDetectBottleneckCalled = false
    var didTriggerWarningCalled = false
    var lastMetrics: TEPerformanceMetrics?
    var lastBottleneck: TEPerformanceBottleneck?
    var lastWarning: String?
    var lastWarningSeverity: Float?
    
    func profiler(_ profiler: TEPerformanceProfiler, didCompleteAnalysis metrics: TEPerformanceMetrics) {
        didCompleteAnalysisCalled = true
        lastMetrics = metrics
    }
    
    func profiler(_ profiler: TEPerformanceProfiler, didDetectBottleneck bottleneck: TEPerformanceBottleneck) {
        didDetectBottleneckCalled = true
        lastBottleneck = bottleneck
    }
    
    func profiler(_ profiler: TEPerformanceProfiler, didTriggerWarning warning: String, severity: Float) {
        didTriggerWarningCalled = true
        lastWarning = warning
        lastWarningSeverity = severity
    }
}
#endif
