//
//  TETextSelectionManagerTests.swift
//  TextEngineKitTests
//
//  Created by Assistant on 2025/11/21.
//
//  文本选择管理器测试
//

import XCTest
#if canImport(UIKit)
import UIKit
#endif
@testable import TextEngineKit

#if canImport(UIKit)
@MainActor
final class TETextSelectionManagerTests: XCTestCase {
    
    var selectionManager: TETextSelectionManager!
    var testLabel: TELabel!
    var mockDelegate: MockSelectionDelegate!
    
    override func setUp() {
        super.setUp()
        selectionManager = TETextSelectionManager()
        testLabel = TELabel(frame: CGRect(x: 0, y: 0, width: 200, height: 50))
        mockDelegate = MockSelectionDelegate()
        selectionManager.delegate = mockDelegate
    }
    
    override func tearDown() {
        selectionManager = nil
        testLabel = nil
        mockDelegate = nil
        super.tearDown()
    }
    
    func testSelectionManagerInitialization() {
        XCTAssertNotNil(selectionManager)
        XCTAssertTrue(selectionManager.isSelectionEnabled)
        XCTAssertTrue(selectionManager.isSelectionHandleEnabled)
        XCTAssertEqual(selectionManager.selectedRange, nil)
    }
    
    func testSetupContainerView() {
        selectionManager.setupContainerView(testLabel)
        // 验证容器视图设置成功
        XCTAssertNotNil(testLabel)
    }
    
    func testTextSelectionRangeCreation() {
        let range = TETextSelectionRange(location: 0, length: 10)
        XCTAssertEqual(range.location, 0)
        XCTAssertEqual(range.length, 10)
        XCTAssertEqual(range.nsRange.location, 0)
        XCTAssertEqual(range.nsRange.length, 10)
    }
    
    func testSetSelection() {
        let testText = NSAttributedString(string: "Hello, World!")
        selectionManager.updateText(testText, layoutInfo: nil)
        
        let range = TETextSelectionRange(location: 0, length: 5)
        selectionManager.setSelection(range)
        
        XCTAssertNotNil(selectionManager.selectedRange)
        XCTAssertEqual(selectionManager.selectedRange?.location, 0)
        XCTAssertEqual(selectionManager.selectedRange?.length, 5)
        XCTAssertTrue(mockDelegate.didChangeSelectionCalled)
    }
    
    func testClearSelection() {
        let testText = NSAttributedString(string: "Hello, World!")
        selectionManager.updateText(testText, layoutInfo: nil)
        
        let range = TETextSelectionRange(location: 0, length: 5)
        selectionManager.setSelection(range)
        selectionManager.clearSelection()
        
        XCTAssertNil(selectionManager.selectedRange)
        XCTAssertTrue(mockDelegate.didChangeSelectionCalled)
    }
    
    func testSelectAll() {
        let testText = NSAttributedString(string: "Hello, World!")
        selectionManager.updateText(testText, layoutInfo: nil)
        
        selectionManager.selectAll()
        
        XCTAssertNotNil(selectionManager.selectedRange)
        XCTAssertEqual(selectionManager.selectedRange?.location, 0)
        XCTAssertEqual(selectionManager.selectedRange?.length, testText.length)
    }
    
    func testSelectedText() {
        let testText = NSAttributedString(string: "Hello, World!")
        selectionManager.updateText(testText, layoutInfo: nil)
        
        let range = TETextSelectionRange(location: 0, length: 5)
        selectionManager.setSelection(range)
        
        let selectedText = selectionManager.selectedText()
        XCTAssertEqual(selectedText, "Hello")
    }
    
    func testCopySelectedText() {
        let testText = NSAttributedString(string: "Hello, World!")
        selectionManager.updateText(testText, layoutInfo: nil)
        
        let range = TETextSelectionRange(location: 0, length: 5)
        selectionManager.setSelection(range)
        
        // 模拟复制操作
        selectionManager.copySelectedText()
        
        XCTAssertTrue(mockDelegate.shouldCopyTextCalled)
    }
    
    func testSelectionProperties() {
        // 测试选择颜色
        selectionManager.selectionColor = .red
        XCTAssertEqual(selectionManager.selectionColor, .red)
        
        // 测试选择文本颜色
        selectionManager.selectionTextColor = .blue
        XCTAssertEqual(selectionManager.selectionTextColor, .blue)
        
        // 测试手柄颜色
        selectionManager.handleColor = .green
        XCTAssertEqual(selectionManager.handleColor, .green)
        
        // 测试手柄大小
        let customSize = CGSize(width: 25, height: 25)
        selectionManager.handleSize = customSize
        XCTAssertEqual(selectionManager.handleSize, customSize)
    }
    
    func testEnableDisableSelection() {
        selectionManager.isSelectionEnabled = false
        XCTAssertFalse(selectionManager.isSelectionEnabled)
        
        selectionManager.isSelectionEnabled = true
        XCTAssertTrue(selectionManager.isSelectionEnabled)
    }
    
    func testEnableDisableSelectionHandles() {
        selectionManager.isSelectionHandleEnabled = false
        XCTAssertFalse(selectionManager.isSelectionHandleEnabled)
        
        selectionManager.isSelectionHandleEnabled = true
        XCTAssertTrue(selectionManager.isSelectionHandleEnabled)
    }
    
    func testHandleType() {
        let startHandle = TESelectionHandleView(type: .start)
        let endHandle = TESelectionHandleView(type: .end)
        
        XCTAssertEqual(startHandle.handleType, .start)
        XCTAssertEqual(endHandle.handleType, .end)
    }
    
    func testSelectionHandleViewInitialization() {
        let handleView = TESelectionHandleView(type: .start)
        
        XCTAssertEqual(handleView.handleType, .start)
        XCTAssertEqual(handleView.frame.size, CGSize(width: 20, height: 20))
        XCTAssertEqual(handleView.layer.cornerRadius, 10)
        XCTAssertEqual(handleView.layer.borderWidth, 2)
        XCTAssertEqual(handleView.layer.borderColor, UIColor.white.cgColor)
    }
    
    func testSelectionManagerDelegateMethods() {
        let testText = NSAttributedString(string: "Hello, World!")
        selectionManager.updateText(testText, layoutInfo: nil)
        
        let range = TETextSelectionRange(location: 0, length: 5)
        selectionManager.setSelection(range)
        
        // 验证委托方法被调用
        XCTAssertTrue(mockDelegate.didChangeSelectionCalled)
        XCTAssertEqual(mockDelegate.lastRange?.location, 0)
        XCTAssertEqual(mockDelegate.lastRange?.length, 5)
    }
}
#endif

// MARK: - Mock Delegate

#if canImport(UIKit)
class MockSelectionDelegate: TETextSelectionManagerDelegate {
    var didChangeSelectionCalled = false
    var willShowMenuCalled = false
    var shouldCopyTextCalled = false
    var lastRange: TETextSelectionRange?
    var lastMenu: UIMenu?
    var lastText: String?
    
    func selectionManager(_ manager: TETextSelectionManager, didChangeSelection range: TETextSelectionRange?) {
        didChangeSelectionCalled = true
        lastRange = range
    }
    
    func selectionManager(_ manager: TETextSelectionManager, willShowMenu menu: UIMenu) {
        willShowMenuCalled = true
        lastMenu = menu
    }
    
    func selectionManager(_ manager: TETextSelectionManager, shouldCopyText text: String) -> Bool {
        shouldCopyTextCalled = true
        lastText = text
        return true
    }
}
#endif
