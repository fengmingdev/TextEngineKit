import XCTest
import CoreText
@testable import TextEngineKit

final class TEVerticalLayoutTests: XCTestCase {
    
    var verticalLayout: TEVerticalLayoutManager!
    var testText: NSAttributedString!
    
    override func setUp() {
        super.setUp()
        verticalLayout = TEVerticalLayoutManager()
        testText = NSAttributedString(string: "Test vertical text", attributes: [
            .font: TEFont.systemFont(ofSize: 16),
            .foregroundColor: TEColor.label
        ])
    }
    
    override func tearDown() {
        verticalLayout = nil
        testText = nil
        super.tearDown()
    }
    
    // MARK: - Basic Vertical Layout Tests
    
    func testBasicVerticalLayout() {
        let size = CGSize(width: 100, height: 200)
        let layout = verticalLayout.layoutSynchronously(testText, size: size)
        XCTAssertGreaterThan(layout.lines.count, 0, "Should have layout lines")
        XCTAssertNotNil(layout.frame, "Should have layout frame")
    }
    
    func testVerticalLayoutWithCJKText() {
        let cjkText = NSAttributedString(string: "测试中文文本", attributes: [
            .font: TEFont.systemFont(ofSize: 16),
            .foregroundColor: TEColor.label
        ])
        let size = CGSize(width: 100, height: 200)
        let layout = verticalLayout.layoutSynchronously(cjkText, size: size)
        XCTAssertGreaterThan(layout.lines.count, 0, "Should have layout lines for CJK text")
    }
    
    func testVerticalLayoutWithMixedText() {
        let mixedText = NSAttributedString(string: "Test测试Text文本", attributes: [
            .font: TEFont.systemFont(ofSize: 16),
            .foregroundColor: TEColor.label
        ])
        let size = CGSize(width: 100, height: 200)
        let layout = verticalLayout.layoutSynchronously(mixedText, size: size)
        XCTAssertGreaterThan(layout.lines.count, 0, "Should have layout lines for mixed text")
    }
    
    // MARK: - Writing Direction Tests
    
    func testRightToLeftVerticalLayout() {
        let rtlText = NSAttributedString(string: "مرحبا بالعالم", attributes: [
            .font: TEFont.systemFont(ofSize: 16),
            .foregroundColor: TEColor.label
        ])
        let size = CGSize(width: 100, height: 200)
        let layout = verticalLayout.layoutSynchronously(rtlText, size: size, options: [.rightToLeft])
        XCTAssertGreaterThan(layout.lines.count, 0, "Should have RTL layout lines")
        XCTAssertEqual(layout.writingDirection, .rightToLeft)
    }
    
    func testLeftToRightVerticalLayout() {
        let size = CGSize(width: 100, height: 200)
        let layout = verticalLayout.layoutSynchronously(testText, size: size)
        XCTAssertGreaterThan(layout.lines.count, 0, "Should have LTR layout lines")
        XCTAssertEqual(layout.writingDirection, .leftToRight)
    }
    
    // MARK: - Line Rotation Tests
    
    func testLineRotationForLatinText() {
        let latinText = NSAttributedString(string: "ABC DEF", attributes: [
            .font: TEFont.systemFont(ofSize: 16),
            .foregroundColor: TEColor.label
        ])
        let size = CGSize(width: 100, height: 200)
        let layout = verticalLayout.layoutSynchronously(latinText, size: size)
        for line in layout.lines {
            let glyphCount = CTLineGetGlyphCount(line)
            XCTAssertGreaterThan(glyphCount, 0, "Should have glyphs in line")
        }
    }
    
    func testLineRotationForCJKText() {
        let cjkText = NSAttributedString(string: "中文文本", attributes: [
            .font: TEFont.systemFont(ofSize: 16),
            .foregroundColor: TEColor.label
        ])
        let size = CGSize(width: 100, height: 200)
        let layout = verticalLayout.layoutSynchronously(cjkText, size: size)
        for line in layout.lines {
            let glyphCount = CTLineGetGlyphCount(line)
            XCTAssertGreaterThan(glyphCount, 0, "Should have glyphs in line")
        }
    }
    
    // MARK: - Bounds Constraint Tests
    
    func testConstrainedVerticalLayout() {
        let size = CGSize(width: 50, height: 100)
        let layout = verticalLayout.layoutSynchronously(testText, size: size)
        XCTAssertGreaterThan(layout.lines.count, 0, "Should have layout lines in constraints")
        let rect = layout.boundingRect
        XCTAssertLessThanOrEqual(rect.width, size.width, "Layout width should not exceed bounds")
        XCTAssertLessThanOrEqual(rect.height, size.height, "Layout height should not exceed bounds")
    }
    
    func testUnconstrainedVerticalLayout() {
        let size = CGSize(width: CGFloat.greatestFiniteMagnitude, height: CGFloat.greatestFiniteMagnitude)
        let layout = verticalLayout.layoutSynchronously(testText, size: size)
        XCTAssertGreaterThan(layout.lines.count, 0, "Should have layout lines without constraints")
    }
    
    func testZeroBoundsVerticalLayout() {
        let size = CGSize.zero
        let layout = verticalLayout.layoutSynchronously(testText, size: size)
        XCTAssertEqual(layout.lines.count, 0, "Should have no lines in zero bounds")
    }
    
    // MARK: - Rich Text Vertical Layout Tests
    
    func testVerticalLayoutWithRichText() {
        let richText = NSMutableAttributedString(string: "Bold and colored text")
        richText.addAttribute(.font, value: TEFont.systemFont(ofSize: 18), range: NSRange(location: 0, length: 4))
        richText.addAttribute(.foregroundColor, value: TEColor.red, range: NSRange(location: 9, length: 8))
        let size = CGSize(width: 100, height: 200)
        let layout = verticalLayout.layoutSynchronously(richText, size: size)
        XCTAssertGreaterThan(layout.lines.count, 0, "Should have layout lines for rich text")
    }
    
    func testVerticalLayoutWithAttachments() {
        let attachment = NSTextAttachment()
        attachment.bounds = CGRect(x: 0, y: 0, width: 20, height: 20)
        let attachmentString = NSAttributedString(attachment: attachment)
        let combinedText = NSMutableAttributedString()
        combinedText.append(NSAttributedString(string: "Text with "))
        combinedText.append(attachmentString)
        combinedText.append(NSAttributedString(string: " attachment"))
        let size = CGSize(width: 100, height: 200)
        let layout = verticalLayout.layoutSynchronously(combinedText, size: size)
        XCTAssertGreaterThan(layout.lines.count, 0, "Should have layout lines with attachments")
    }
    
    // MARK: - Performance Tests
    
    func testVerticalLayoutPerformance() {
        let longText = NSAttributedString(string: String(repeating: "Performance test text. ", count: 100))
        let size = CGSize(width: 100, height: 1000)
        measure {
            _ = verticalLayout.layoutSynchronously(longText, size: size)
        }
    }
    
    func testCJKVerticalLayoutPerformance() {
        let longCJKText = NSAttributedString(string: String(repeating: "性能测试中文文本。", count: 100))
        let size = CGSize(width: 100, height: 1000)
        measure {
            _ = verticalLayout.layoutSynchronously(longCJKText, size: size)
        }
    }
    
    // MARK: - Layout Line Tests
    
    func testLayoutLineProperties() {
        let size = CGSize(width: 100, height: 200)
        let layout = verticalLayout.layoutSynchronously(testText, size: size)
        XCTAssertGreaterThan(layout.lines.count, 0, "Should have layout lines")
        let firstLine = layout.lines.first!
        let rect = layout.rectForLine(at: 0)
        XCTAssertFalse(rect.isEmpty, "Should have line frame")
        let glyphCount = CTLineGetGlyphCount(firstLine)
        XCTAssertGreaterThan(glyphCount, 0, "Should have glyph runs")
    }
    
    func testLayoutGlyphRunProperties() {
        let size = CGSize(width: 100, height: 200)
        let layout = verticalLayout.layoutSynchronously(testText, size: size)
        if let firstLine = layout.lines.first {
            let glyphCount = CTLineGetGlyphCount(firstLine)
            XCTAssertGreaterThan(glyphCount, 0, "Should have glyphs")
        } else {
            XCTFail("Should have lines in layout")
        }
    }
    
    // MARK: - Error Handling Tests
    
    func testVerticalLayoutWithEmptyText() {
        let emptyText = NSAttributedString(string: "")
        let size = CGSize(width: 100, height: 200)
        let layout = verticalLayout.layoutSynchronously(emptyText, size: size)
        XCTAssertEqual(layout.lines.count, 0, "Should have no lines for empty text")
    }
    
    func testVerticalLayoutWithNilText() {
        let size = CGSize(width: 100, height: 200)
        let layout = verticalLayout.layoutSynchronously(NSAttributedString(string: ""), size: size)
        XCTAssertEqual(layout.lines.count, 0, "Should have no lines for nil text")
    }
    
    // MARK: - Memory Management Tests
    
    func testMemoryManagement() {
        weak var weakLayout: TEVerticalLayoutManager?
        autoreleasepool {
            let tempLayout = TEVerticalLayoutManager()
            weakLayout = tempLayout
            let size = CGSize(width: 100, height: 200)
            _ = tempLayout.layoutSynchronously(testText, size: size)
        }
        XCTAssertNil(weakLayout, "Vertical layout should be deallocated")
    }
    
    func testLayoutResultMemoryManagement() {
        weak var weakLayoutResult: TEVerticalLayoutInfo?
        autoreleasepool {
            let size = CGSize(width: 100, height: 200)
            var layoutResult: TEVerticalLayoutInfo? = verticalLayout.layoutSynchronously(testText, size: size)
            weakLayoutResult = layoutResult
            XCTAssertNotNil(layoutResult, "Should have layout result")
            layoutResult = nil
        }
        XCTAssertNil(weakLayoutResult, "Layout result should be deallocated")
    }
    
    // MARK: - Concurrent Access Tests
    
    func testConcurrentVerticalLayout() {
        let expectation = self.expectation(description: "Concurrent layout completion")
        let iterations = 20
        var completed = 0
        let queue = DispatchQueue(label: "test.concurrent", attributes: .concurrent)
        for i in 0..<iterations {
            queue.async {
                let text = NSAttributedString(string: "Concurrent text \(i)")
                let size = CGSize(width: 100, height: 200)
                let layout = self.verticalLayout.layoutSynchronously(text, size: size)
                XCTAssertGreaterThan(layout.lines.count, 0, "Should have layout lines")
                DispatchQueue.main.async {
                    completed += 1
                    if completed == iterations {
                        expectation.fulfill()
                    }
                }
            }
        }
        waitForExpectations(timeout: 10.0, handler: nil)
    }
}
