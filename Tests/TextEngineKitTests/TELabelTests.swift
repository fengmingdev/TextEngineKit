#if canImport(UIKit)
import XCTest
import UIKit
@testable import TextEngineKit

final class TELabelTests: XCTestCase {
    
    var label: TELabel!
    var testText: NSAttributedString!
    
    override func setUp() {
        super.setUp()
        label = TELabel(frame: CGRect(x: 0, y: 0, width: 200, height: 50))
        testText = NSAttributedString(string: "Test label text", attributes: [
            .font: UIFont.systemFont(ofSize: 16),
            .foregroundColor: UIColor.black
        ])
    }
    
    override func tearDown() {
        label = nil
        testText = nil
        super.tearDown()
    }
    
    // MARK: - Basic Initialization Tests
    
    func testLabelInitialization() {
        XCTAssertNotNil(label, "Label should be initialized")
        XCTAssertEqual(label.frame.width, 200, "Should have correct width")
        XCTAssertEqual(label.frame.height, 50, "Should have correct height")
        XCTAssertNil(label.attributedText, "Should have no text initially")
    }
    
    func testAttributedTextSetting() {
        label.attributedText = testText
        
        XCTAssertEqual(label.attributedText, testText, "Should set attributed text correctly")
        XCTAssertTrue(label.needsLayout, "Should mark as needing layout")
    }
    
    func testTextSetting() {
        let plainText = "Plain text"
        label.text = plainText
        
        XCTAssertEqual(label.text, plainText, "Should set plain text correctly")
        XCTAssertNotNil(label.attributedText, "Should create attributed text from plain text")
        XCTAssertEqual(label.attributedText?.string, plainText, "Attributed text should match")
    }
    
    // MARK: - Rich Text Tests
    
    func testRichTextDisplay() {
        let richText = NSMutableAttributedString(string: "Bold and colored text")
        richText.addAttribute(.font, value: UIFont.boldSystemFont(ofSize: 18), range: NSRange(location: 0, length: 4))
        richText.addAttribute(.foregroundColor, value: UIColor.red, range: NSRange(location: 9, length: 8))
        
        label.attributedText = richText
        
        XCTAssertEqual(label.attributedText, richText, "Should display rich text correctly")
    }
    
    func testTextWithAttachments() {
        let attachment = NSTextAttachment()
        attachment.bounds = CGRect(x: 0, y: 0, width: 20, height: 20)
        let attachmentString = NSAttributedString(attachment: attachment)
        
        let combinedText = NSMutableAttributedString()
        combinedText.append(NSAttributedString(string: "Text with "))
        combinedText.append(attachmentString)
        combinedText.append(NSAttributedString(string: " attachment"))
        
        label.attributedText = combinedText
        
        XCTAssertEqual(label.attributedText, combinedText, "Should display text with attachments")
    }
    
    // MARK: - Highlight Tests
    
    func testHighlightSetting() {
        label.attributedText = testText
        
        let highlight = TETextHighlight()
        highlight.color = UIColor.blue
        highlight.backgroundColor = UIColor.lightGray
        
        label.setHighlight(highlight, range: NSRange(location: 0, length: 4))
        
        let retrievedHighlight = label.highlightAtPoint(CGPoint(x: 10, y: 10))
        XCTAssertNotNil(retrievedHighlight, "Should have highlight at point")
    }
    
    func testMultipleHighlights() {
        label.attributedText = testText
        
        let highlight1 = TETextHighlight()
        highlight1.color = UIColor.blue
        
        let highlight2 = TETextHighlight()
        highlight2.color = UIColor.red
        
        label.setHighlight(highlight1, range: NSRange(location: 0, length: 4))
        label.setHighlight(highlight2, range: NSRange(location: 10, length: 4))
        
        let retrievedHighlight1 = label.highlightAtPoint(CGPoint(x: 10, y: 10))
        let retrievedHighlight2 = label.highlightAtPoint(CGPoint(x: 50, y: 10))
        
        XCTAssertNotNil(retrievedHighlight1, "Should have first highlight")
        XCTAssertNotNil(retrievedHighlight2, "Should have second highlight")
    }
    
    func testHighlightRemoval() {
        label.attributedText = testText
        
        let highlight = TETextHighlight()
        highlight.color = UIColor.blue
        
        label.setHighlight(highlight, range: NSRange(location: 0, length: 4))
        label.removeHighlight(NSRange(location: 0, length: 4))
        
        let retrievedHighlight = label.highlightAtPoint(CGPoint(x: 10, y: 10))
        XCTAssertNil(retrievedHighlight, "Should remove highlight")
    }
    
    // MARK: - Layout Tests
    
    func testPreferredSizeCalculation() {
        label.attributedText = testText
        
        let maxSize = CGSize(width: CGFloat.greatestFiniteMagnitude, height: CGFloat.greatestFiniteMagnitude)
        let preferredSize = label.preferredSize(with: maxSize)
        
        XCTAssertGreaterThan(preferredSize.width, 0, "Should have positive width")
        XCTAssertGreaterThan(preferredSize.height, 0, "Should have positive height")
    }
    
    func testConstrainedSizeCalculation() {
        label.attributedText = testText
        
        let constrainedSize = CGSize(width: 100, height: CGFloat.greatestFiniteMagnitude)
        let preferredSize = label.preferredSize(with: constrainedSize)
        
        XCTAssertLessThanOrEqual(preferredSize.width, 100, "Should respect width constraint")
        XCTAssertGreaterThan(preferredSize.height, 0, "Should have positive height")
    }
    
    func testSizeToFit() {
        label.attributedText = testText
        let originalSize = label.frame.size
        
        label.sizeToFit()
        
        XCTAssertNotEqual(label.frame.size, originalSize, "Should change size to fit")
        XCTAssertGreaterThan(label.frame.width, 0, "Should have positive width")
        XCTAssertGreaterThan(label.frame.height, 0, "Should have positive height")
    }
    
    // MARK: - Interaction Tests
    
    func testTapGestureRecognition() {
        label.attributedText = testText
        
        let highlight = TETextHighlight()
        var tapDetected = false
        highlight.tapAction = { _, _, _ in
            tapDetected = true
        }
        
        label.setHighlight(highlight, range: NSRange(location: 0, length: 4))
        
        // Simulate tap at the beginning of text
        let tapPoint = CGPoint(x: 10, y: 10)
        label.handleTap(tapPoint)
        
        XCTAssertTrue(tapDetected, "Should detect tap on highlight")
    }
    
    func testLongPressGestureRecognition() {
        label.attributedText = testText
        
        let highlight = TETextHighlight()
        var longPressDetected = false
        highlight.longPressAction = { _, _, _ in
            longPressDetected = true
        }
        
        label.setHighlight(highlight, range: NSRange(location: 0, length: 4))
        
        // Simulate long press at the beginning of text
        let pressPoint = CGPoint(x: 10, y: 10)
        label.handleLongPress(pressPoint)
        
        XCTAssertTrue(longPressDetected, "Should detect long press on highlight")
    }
    
    // MARK: - Performance Tests
    
    func testLabelLayoutPerformance() {
        let longText = NSAttributedString(string: String(repeating: "Performance test text. ", count: 100))
        label.attributedText = longText
        
        measure {
            label.layoutSubviews()
        }
    }
    
    func testHighlightPerformance() {
        let longText = NSAttributedString(string: String(repeating: "Performance test text. ", count: 100))
        label.attributedText = longText
        
        measure {
            let highlight = TETextHighlight()
            label.setHighlight(highlight, range: NSRange(location: 0, length: 10))
        }
    }
    
    // MARK: - Configuration Tests
    
    func testNumberOfLinesSetting() {
        label.numberOfLines = 2
        XCTAssertEqual(label.numberOfLines, 2, "Should set number of lines")
        
        label.numberOfLines = 0 // Unlimited
        XCTAssertEqual(label.numberOfLines, 0, "Should set unlimited lines")
    }
    
    func testLineBreakModeSetting() {
        label.lineBreakMode = .byTruncatingTail
        XCTAssertEqual(label.lineBreakMode, .byTruncatingTail, "Should set line break mode")
        
        label.lineBreakMode = .byWordWrapping
        XCTAssertEqual(label.lineBreakMode, .byWordWrapping, "Should set word wrapping")
    }
    
    func testTextAlignmentSetting() {
        label.textAlignment = .center
        XCTAssertEqual(label.textAlignment, .center, "Should set text alignment")
        
        label.textAlignment = .right
        XCTAssertEqual(label.textAlignment, .right, "Should set right alignment")
    }
    
    // MARK: - Edge Case Tests
    
    func testEmptyTextHandling() {
        label.attributedText = NSAttributedString(string: "")
        
        XCTAssertEqual(label.attributedText?.string, "", "Should handle empty text")
        
        let preferredSize = label.preferredSize(with: CGSize(width: CGFloat.greatestFiniteMagnitude, height: CGFloat.greatestFiniteMagnitude))
        XCTAssertEqual(preferredSize, CGSize.zero, "Should have zero size for empty text")
    }
    
    func testNilTextHandling() {
        label.attributedText = nil
        
        XCTAssertNil(label.attributedText, "Should handle nil text")
        XCTAssertNil(label.text, "Should have nil plain text")
    }
    
    func testVeryLongTextHandling() {
        let veryLongText = NSAttributedString(string: String(repeating: "Very long text. ", count: 1000))
        label.attributedText = veryLongText
        
        XCTAssertEqual(label.attributedText, veryLongText, "Should handle very long text")
        
        let preferredSize = label.preferredSize(with: CGSize(width: 300, height: CGFloat.greatestFiniteMagnitude))
        XCTAssertGreaterThan(preferredSize.height, 0, "Should calculate size for very long text")
    }
    
    // MARK: - Memory Management Tests
    
    func testMemoryManagement() {
        weak var weakLabel: TELabel?
        
        autoreleasepool {
            let tempLabel = TELabel()
            weakLabel = tempLabel
            
            tempLabel.attributedText = testText
            
            let highlight = TETextHighlight()
            tempLabel.setHighlight(highlight, range: NSRange(location: 0, length: 4))
        }
        
        XCTAssertNil(weakLabel, "Label should be deallocated")
    }
    
    // MARK: - Concurrent Access Tests
    
    func testConcurrentTextSetting() {
        let expectation = self.expectation(description: "Concurrent text setting completion")
        let iterations = 100
        var completed = 0
        let queue = DispatchQueue(label: "test.concurrent", attributes: .concurrent)
        
        for i in 0..<iterations {
            queue.async {
                let text = NSAttributedString(string: "Concurrent text \(i)")
                self.label.attributedText = text
                
                DispatchQueue.main.async {
                    completed += 1
                    if completed == iterations {
                        expectation.fulfill()
                    }
                }
            }
        }
        
        waitForExpectations(timeout: 5.0, handler: nil)
    }
}
#endif