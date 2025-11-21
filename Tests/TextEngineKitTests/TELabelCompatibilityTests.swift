//
//  TELabelCompatibilityTests.swift
//  TextEngineKitTests
//
//  Created by Assistant on 2025/11/21.
//
//  UILabel API兼容性测试
//

import XCTest
#if canImport(UIKit)
import UIKit
#endif
@testable import TextEngineKit

#if canImport(UIKit)
@MainActor
final class TELabelCompatibilityTests: XCTestCase {
    
    var label: TELabel!
    
    override func setUp() {
        super.setUp()
        label = TELabel(frame: CGRect(x: 0, y: 0, width: 200, height: 50))
    }
    
    override func tearDown() {
        label = nil
        super.tearDown()
    }
    
    func testUILabelBasicProperties() {
        // 测试文本
        label.text = "Hello World"
        XCTAssertEqual(label.text, "Hello World")
        
        // 测试字体
        let testFont = UIFont.systemFont(ofSize: 16)
        label.font = testFont
        XCTAssertEqual(label.font, testFont)
        
        // 测试文本颜色
        label.textColor = .red
        XCTAssertEqual(label.textColor, .red)
        
        // 测试文本对齐
        label.textAlignment = .center
        XCTAssertEqual(label.textAlignment, .center)
        
        label.textAlignment = .right
        XCTAssertEqual(label.textAlignment, .right)
        
        label.textAlignment = .left
        XCTAssertEqual(label.textAlignment, .left)
    }
    
    func testUILabelShadowProperties() {
        // 测试阴影颜色
        label.shadowColor = .black
        XCTAssertEqual(label.shadowColor, .black)
        
        // 测试阴影偏移
        label.shadowOffset = CGSize(width: 2, height: 2)
        XCTAssertEqual(label.shadowOffset, CGSize(width: 2, height: 2))
        
        // 测试阴影半径
        label.shadowRadius = 3.0
        XCTAssertEqual(label.shadowRadius, 3.0)
    }
    
    func testUILabelAdvancedProperties() {
        // 测试numberOfLines
        label.numberOfLines = 2
        XCTAssertEqual(label.numberOfLines, 2)
        
        // 测试lineBreakMode
        label.lineBreakMode = .byTruncatingTail
        XCTAssertEqual(label.lineBreakMode, .byTruncatingTail)
        
        // 测试preferredMaxLayoutWidth
        label.preferredMaxLayoutWidth = 150
        XCTAssertEqual(label.preferredMaxLayoutWidth, 150)
    }
    
    func testTELabelSpecificProperties() {
        // 测试垂直文本对齐
        label.textVerticalAlignment = .top
        XCTAssertEqual(label.textVerticalAlignment, .top)
        
        label.textVerticalAlignment = .center
        XCTAssertEqual(label.textVerticalAlignment, .center)
        
        label.textVerticalAlignment = .bottom
        XCTAssertEqual(label.textVerticalAlignment, .bottom)
        
        // 测试文本容器内边距
        let insets = UIEdgeInsets(top: 10, left: 10, bottom: 10, right: 10)
        label.textContainerInset = insets
        XCTAssertEqual(label.textContainerInset, insets)
    }
    
    func testTELabelTruncationProperties() {
        // 测试截断标记
        let truncationToken = NSAttributedString(string: "...", attributes: [.foregroundColor: UIColor.gray])
        label.truncationAttributedToken = truncationToken
        XCTAssertEqual(label.truncationAttributedToken, truncationToken)
        
        // 测试额外截断消息
        let additionalMessage = NSAttributedString(string: "more", attributes: [.foregroundColor: UIColor.blue])
        label.additionalTruncationAttributedMessage = additionalMessage
        XCTAssertEqual(label.additionalTruncationAttributedMessage, additionalMessage)
    }
    
    func testTELabelSelectionProperties() {
        // 测试文本选择启用
        label.isTextSelectionEnabled = false
        XCTAssertFalse(label.isTextSelectionEnabled)
        
        label.isTextSelectionEnabled = true
        XCTAssertTrue(label.isTextSelectionEnabled)
        
        // 测试选择手柄启用
        label.isSelectionHandleEnabled = false
        XCTAssertFalse(label.isSelectionHandleEnabled)
        
        label.isSelectionHandleEnabled = true
        XCTAssertTrue(label.isSelectionHandleEnabled)
    }
    
    func testTELabelDebugProperties() {
        // 测试调试模式
        label.isDebugModeEnabled = true
        XCTAssertTrue(label.isDebugModeEnabled)
        
        label.isDebugModeEnabled = false
        XCTAssertFalse(label.isDebugModeEnabled)
        
        // 测试性能分析
        label.isPerformanceProfilingEnabled = true
        XCTAssertTrue(label.isPerformanceProfilingEnabled)
        
        label.isPerformanceProfilingEnabled = false
        XCTAssertFalse(label.isPerformanceProfilingEnabled)
    }
    
    func testTELabelSelectionMethods() {
        label.text = "Hello World"
        
        // 测试选择所有文本
        label.selectAll()
        // 验证选择功能正常工作（需要模拟实际的文本布局）
        
        // 测试清除选择
        label.clearSelection()
        
        // 测试获取选中文本
        let selectedText = label.selectedText()
        // 在没有实际选择的情况下应该返回nil
        XCTAssertNil(selectedText)
        
        // 测试复制选中文本
        label.copySelectedText()
        // 验证复制功能不会崩溃
    }
    
    func testTELabelExclusionPathMethods() {
        // 测试添加排除路径
        let exclusionPath = TEExclusionPath.rect(CGRect(x: 50, y: 10, width: 50, height: 30))
        label.addExclusionPath(exclusionPath)
        // 验证添加功能不会崩溃
        
        // 测试移除排除路径
        label.removeExclusionPath(exclusionPath)
        // 验证移除功能不会崩溃
        
        // 测试清除所有排除路径
        label.clearExclusionPaths()
        // 验证清除功能不会崩溃
    }
    
    func testTELabelTextMethods() {
        label.text = "Hello World"
        
        // 测试获取指定点的字符索引
        let point = CGPoint(x: 10, y: 10)
        let characterIndex = label.characterIndex(at: point)
        // 在没有实际布局的情况下返回NSNotFound
        XCTAssertEqual(characterIndex, NSNotFound)
        
        // 测试获取指定字符索引的边界矩形
        let boundingRect = label.boundingRect(forCharacterAt: 0)
        // 在没有实际布局的情况下返回.zero
        XCTAssertEqual(boundingRect, .zero)
        
        // 测试获取指定范围的边界矩形
        let rangeRect = label.boundingRect(for: NSRange(location: 0, length: 5))
        // 在没有实际布局的情况下返回.zero
        XCTAssertEqual(rangeRect, .zero)
    }
    
    func testTELabelFontSizeAdjustment() {
        label.text = "Test Font Size Adjustment"
        label.font = UIFont.systemFont(ofSize: 20)
        
        // 测试字体大小调整
        label.adjustFontSizeToFitWidth()
        // 验证字体大小调整功能不会崩溃
        XCTAssertNotNil(label.font)
    }
    
    func testTELabelAttributedTextCompatibility() {
        // 测试属性文本设置
        let attributedText = NSAttributedString(
            string: "Attributed Text",
            attributes: [
                .font: UIFont.boldSystemFont(ofSize: 16),
                .foregroundColor: UIColor.blue
            ]
        )
        
        label.attributedText = attributedText
        XCTAssertEqual(label.attributedText, attributedText)
        
        // 验证基本属性也正确设置
        XCTAssertEqual(label.text, "Attributed Text")
        XCTAssertEqual(label.textColor, .blue)
    }
    
    func testUILabelCompatibilityWithSuperclass() {
        // 验证TELabel是UILabel的子类
        XCTAssertTrue(label is UILabel)
        
        // 验证可以向上转型为UILabel
        let uiLabel: UILabel = label
        XCTAssertNotNil(uiLabel)
        
        // 验证UILabel的基本功能正常工作
        uiLabel.text = "UILabel Compatibility"
        XCTAssertEqual(uiLabel.text, "UILabel Compatibility")
    }
}
#endif
