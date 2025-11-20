#if canImport(UIKit)
import XCTest
import UIKit
@testable import TextEngineKit

final class TETextViewTests: XCTestCase {
    
    var textView: TETextView!
    var testText: NSAttributedString!
    
    override func setUp() {
        super.setUp()
        textView = TETextView(frame: CGRect(x: 0, y: 0, width: 300, height: 200))
        testText = NSAttributedString(string: "Test text view content", attributes: [
            .font: UIFont.systemFont(ofSize: 16),
            .foregroundColor: UIColor.black
        ])
    }
    
    override func tearDown() {
        textView = nil
        testText = nil
        super.tearDown()
    }
    
    // MARK: - Basic Initialization Tests
    
    func testTextViewInitialization() {
        XCTAssertNotNil(textView, "Text view should be initialized")
        XCTAssertEqual(textView.frame.width, 300, "Should have correct width")
        XCTAssertEqual(textView.frame.height, 200, "Should have correct height")
        XCTAssertNotNil(textView.text, "Should have default text")
        XCTAssertTrue(textView.isEditable, "Should be editable by default")
        XCTAssertTrue(textView.isSelectable, "Should be selectable by default")
    }
    
    func testAttributedTextSetting() {
        textView.attributedText = testText
        
        XCTAssertEqual(textView.attributedText, testText, "Should set attributed text correctly")
        XCTAssertEqual(textView.text, testText.string, "Plain text should match")
    }
    
    func testTextSetting() {
        let plainText = "Plain text content"
        textView.text = plainText
        
        XCTAssertEqual(textView.text, plainText, "Should set plain text correctly")
        XCTAssertEqual(textView.attributedText?.string, plainText, "Attributed text should match")
    }
    
    // MARK: - Parser Integration Tests
    
    func testMarkdownParser() {
        textView.enableMarkdownParsing = true
        let markdownText = "**Bold text** and *italic text*"
        
        textView.text = markdownText
        
        XCTAssertNotEqual(textView.attributedText?.string, markdownText, "Should parse markdown")
        
        // Check if attributes were applied
        let attributedString = textView.attributedText!
        var hasBold = false
        var hasItalic = false
        
        attributedString.enumerateAttributes(in: NSRange(location: 0, length: attributedString.length), options: []) { attributes, _, _ in
            if let font = attributes[.font] as? UIFont {
                if font.fontDescriptor.symbolicTraits.contains(.traitBold) {
                    hasBold = true
                }
                if font.fontDescriptor.symbolicTraits.contains(.traitItalic) {
                    hasItalic = true
                }
            }
        }
        
        XCTAssertTrue(hasBold, "Should have bold text")
        XCTAssertTrue(hasItalic, "Should have italic text")
    }
    
    func testEmojiParser() {
        textView.enableEmojiParsing = true
        let emojiText = "Hello :smile: and :heart:"
        
        textView.text = emojiText
        
        XCTAssertNotEqual(textView.attributedText?.string, emojiText, "Should parse emoji")
        
        // Check if emoji were substituted
        let attributedString = textView.attributedText!
        XCTAssertTrue(attributedString.string.contains("😄"), "Should have smile emoji")
        XCTAssertTrue(attributedString.string.contains("❤️"), "Should have heart emoji")
    }
    
    func testCompositeParser() {
        textView.enableMarkdownParsing = true
        textView.enableEmojiParsing = true
        
        let compositeText = "**Bold** with :smile: emoji"
        textView.text = compositeText
        
        let attributedString = textView.attributedText!
        
        // Check both markdown and emoji parsing
        var hasBold = false
        attributedString.enumerateAttributes(in: NSRange(location: 0, length: attributedString.length), options: []) { attributes, _, _ in
            if let font = attributes[.font] as? UIFont {
                if font.fontDescriptor.symbolicTraits.contains(.traitBold) {
                    hasBold = true
                }
            }
        }
        
        XCTAssertTrue(hasBold, "Should have bold text")
        XCTAssertTrue(attributedString.string.contains("😄"), "Should have emoji")
    }
    
    // MARK: - Undo/Redo Tests
    
    func testBasicUndo() {
        textView.text = "Initial text"
        textView.text = "Modified text"
        
        XCTAssertTrue(textView.canUndo, "Should be able to undo")
        
        textView.undo()
        
        XCTAssertEqual(textView.text, "Initial text", "Should undo to initial text")
        XCTAssertTrue(textView.canRedo, "Should be able to redo")
    }
    
    func testBasicRedo() {
        textView.text = "Initial text"
        textView.text = "Modified text"
        textView.undo()
        
        XCTAssertTrue(textView.canRedo, "Should be able to redo")
        
        textView.redo()
        
        XCTAssertEqual(textView.text, "Modified text", "Should redo to modified text")
        XCTAssertFalse(textView.canRedo, "Should not be able to redo again")
    }
    
    func testMultipleUndoRedo() {
        textView.text = "First"
        textView.text = "Second"
        textView.text = "Third"
        
        textView.undo()
        XCTAssertEqual(textView.text, "Second", "Should undo to second")
        
        textView.undo()
        XCTAssertEqual(textView.text, "First", "Should undo to first")
        
        textView.redo()
        XCTAssertEqual(textView.text, "Second", "Should redo to second")
        
        textView.redo()
        XCTAssertEqual(textView.text, "Third", "Should redo to third")
    }
    
    func testAttributedTextUndo() {
        let initialText = NSAttributedString(string: "Initial", attributes: [.font: UIFont.systemFont(ofSize: 16)])
        let modifiedText = NSAttributedString(string: "Modified", attributes: [.font: UIFont.boldSystemFont(ofSize: 18)])
        
        textView.attributedText = initialText
        textView.attributedText = modifiedText
        
        textView.undo()
        
        XCTAssertEqual(textView.attributedText?.string, "Initial", "Should undo attributed text")
        
        let attributes = textView.attributedText?.attributes(at: 0, effectiveRange: nil)
        let font = attributes?[.font] as? UIFont
        XCTAssertEqual(font?.pointSize, 16, "Should preserve attributes during undo")
    }
    
    // MARK: - Clipboard Tests
    
    func testCopy() {
        textView.attributedText = testText
        textView.selectedRange = NSRange(location: 0, length: 4)
        
        textView.copy(nil)
        
        let pasteboard = UIPasteboard.general
        XCTAssertEqual(pasteboard.string, "Test", "Should copy selected text")
    }
    
    func testCut() {
        textView.attributedText = testText
        textView.selectedRange = NSRange(location: 0, length: 4)
        
        textView.cut(nil)
        
        let pasteboard = UIPasteboard.general
        XCTAssertEqual(pasteboard.string, "Test", "Should cut selected text")
        XCTAssertEqual(textView.text, " text view content", "Should remove cut text")
    }
    
    func testPaste() {
        // First copy some text
        let pasteboard = UIPasteboard.general
        pasteboard.string = "Pasted"
        
        textView.attributedText = testText
        textView.selectedRange = NSRange(location: 0, length: 0) // Cursor at beginning
        
        textView.paste(nil)
        
        XCTAssertEqual(textView.text, "PastedTest text view content", "Should paste text")
    }
    
    func testAttributedPaste() {
        // Create attributed string for pasteboard
        let attributedString = NSAttributedString(string: "Bold", attributes: [.font: UIFont.boldSystemFont(ofSize: 16)])
        let pasteboard = UIPasteboard.general
        
        // Set attributed string on pasteboard
        pasteboard.items = [[NSAttributedString.pasteboardType: attributedString]]
        
        textView.attributedText = testText
        textView.selectedRange = NSRange(location: 0, length: 0)
        
        textView.paste(nil)
        
        XCTAssertTrue(textView.text.hasPrefix("Bold"), "Should paste attributed text")
    }
    
    // MARK: - Text Length Limit Tests
    
    func testTextLengthLimit() {
        textView.maxTextLength = 10
        
        textView.text = "Short"
        XCTAssertEqual(textView.text, "Short", "Should accept short text")
        
        textView.text = "This is too long"
        XCTAssertEqual(textView.text.count, 10, "Should limit text length")
    }
    
    func testMaxTextLengthChange() {
        textView.text = "This is a longer text"
        
        textView.maxTextLength = 10
        XCTAssertEqual(textView.text.count, 10, "Should truncate existing text when limit is applied")
    }
    
    // MARK: - Placeholder Tests
    
    func testPlaceholderDisplay() {
        let placeholder = "Enter text here..."
        textView.placeholderText = placeholder
        
        XCTAssertEqual(textView.placeholderText, placeholder, "Should set placeholder text")
        XCTAssertTrue(textView.shouldShowPlaceholder, "Should show placeholder when empty")
        
        textView.text = "Actual text"
        XCTAssertFalse(textView.shouldShowPlaceholder, "Should hide placeholder when text is present")
        
        textView.text = ""
        XCTAssertTrue(textView.shouldShowPlaceholder, "Should show placeholder when text is empty")
    }
    
    func testAttributedPlaceholder() {
        let placeholder = NSAttributedString(string: "Placeholder", attributes: [
            .foregroundColor: UIColor.lightGray,
            .font: UIFont.italicSystemFont(ofSize: 14)
        ])
        textView.attributedPlaceholder = placeholder
        
        XCTAssertEqual(textView.attributedPlaceholder, placeholder, "Should set attributed placeholder")
    }
    
    // MARK: - Highlight Tests
    
    func testHighlightInTextView() {
        textView.attributedText = testText
        
        let highlight = TETextHighlight()
        highlight.color = UIColor.blue
        highlight.backgroundColor = UIColor.lightGray
        
        textView.setHighlight(highlight, range: NSRange(location: 0, length: 4))
        
        let retrievedHighlight = textView.highlightAtPoint(CGPoint(x: 10, y: 10))
        XCTAssertNotNil(retrievedHighlight, "Should have highlight in text view")
    }
    
    // MARK: - Editing Tests
    
    func testEditingDelegate() {
        class MockDelegate: NSObject, UITextViewDelegate {
            var shouldBeginEditingCalled = false
            var didBeginEditingCalled = false
            var shouldEndEditingCalled = false
            var didEndEditingCalled = false
            
            func textViewShouldBeginEditing(_ textView: UITextView) -> Bool {
                shouldBeginEditingCalled = true
                return true
            }
            
            func textViewDidBeginEditing(_ textView: UITextView) {
                didBeginEditingCalled = true
            }
            
            func textViewShouldEndEditing(_ textView: UITextView) -> Bool {
                shouldEndEditingCalled = true
                return true
            }
            
            func textViewDidEndEditing(_ textView: UITextView) {
                didEndEditingCalled = true
            }
        }
        
        let mockDelegate = MockDelegate()
        textView.delegate = mockDelegate
        
        textView.becomeFirstResponder()
        XCTAssertTrue(mockDelegate.shouldBeginEditingCalled, "Should call shouldBeginEditing")
        XCTAssertTrue(mockDelegate.didBeginEditingCalled, "Should call didBeginEditing")
        
        textView.resignFirstResponder()
        XCTAssertTrue(mockDelegate.shouldEndEditingCalled, "Should call shouldEndEditing")
        XCTAssertTrue(mockDelegate.didEndEditingCalled, "Should call didEndEditing")
    }
    
    // MARK: - Performance Tests
    
    func testTextViewPerformance() {
        let longText = NSAttributedString(string: String(repeating: "Performance test text. ", count: 100))
        
        measure {
            textView.attributedText = longText
            textView.layoutIfNeeded()
        }
    }
    
    func testUndoRedoPerformance() {
        measure {
            for i in 0..<10 {
                textView.text = "Text \(i)"
            }
            
            for _ in 0..<10 {
                if textView.canUndo {
                    textView.undo()
                }
            }
        }
    }
    
    // MARK: - Edge Case Tests
    
    func testEmptyTextView() {
        textView.text = ""
        
        XCTAssertEqual(textView.text, "", "Should handle empty text")
        XCTAssertTrue(textView.canUndo, "Should be able to undo to previous text")
    }
    
    func testVeryLongText() {
        let veryLongText = String(repeating: "Very long text. ", count: 1000)
        
        textView.text = veryLongText
        
        XCTAssertEqual(textView.text, veryLongText, "Should handle very long text")
        XCTAssertTrue(textView.canUndo, "Should be able to undo very long text")
    }
    
    func testRapidTextChanges() {
        for i in 0..<50 {
            textView.text = "Rapid change \(i)"
        }
        
        XCTAssertTrue(textView.canUndo, "Should handle rapid text changes")
        
        // Test undo after rapid changes
        let currentText = textView.text
        textView.undo()
        XCTAssertNotEqual(textView.text, currentText, "Should be able to undo after rapid changes")
    }
    
    // MARK: - Memory Management Tests
    
    func testMemoryManagement() {
        weak var weakTextView: TETextView?
        
        autoreleasepool {
            let tempTextView = TETextView()
            weakTextView = tempTextView
            
            tempTextView.attributedText = testText
            tempTextView.enableMarkdownParsing = true
            tempTextView.enableEmojiParsing = true
            
            let highlight = TETextHighlight()
            tempTextView.setHighlight(highlight, range: NSRange(location: 0, length: 4))
        }
        
        XCTAssertNil(weakTextView, "Text view should be deallocated")
    }
    
    // MARK: - Concurrent Access Tests
    
    func testConcurrentTextModification() {
        let expectation = self.expectation(description: "Concurrent modification completion")
        let iterations = 50
        var completed = 0
        let queue = DispatchQueue(label: "test.concurrent", attributes: .concurrent)
        
        for i in 0..<iterations {
            queue.async {
                self.textView.text = "Concurrent modification \(i)"
                
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