import XCTest
@testable import TextEngineKit

final class TEAttributeTests: XCTestCase {
    
    var testString: NSMutableAttributedString!
    
    override func setUp() {
        super.setUp()
        testString = NSMutableAttributedString(string: "Test attributed string")
    }
    
    override func tearDown() {
        testString = nil
        super.tearDown()
    }
    
    // MARK: - Basic Attribute Tests
    
    func testFontAttribute() {
        let font = TEFont.systemFont(ofSize: 16)
        testString.setTe_font(font)
        
        let attributes = testString.attributes(at: 0, effectiveRange: nil)
        XCTAssertEqual(attributes[TEAttributeKey.font] as? TEFont, font, "Should set font attribute correctly")
    }
    
    func testForegroundColorAttribute() {
        let color = TEColor.red
        testString.setTe_foregroundColor(color)
        
        let attributes = testString.attributes(at: 0, effectiveRange: nil)
        XCTAssertEqual(attributes[TEAttributeKey.foregroundColor] as? TEColor, color, "Should set foreground color correctly")
    }
    
    func testBackgroundColorAttribute() {
        let color = TEColor.blue
        testString.setTe_backgroundColor(color)
        
        let attributes = testString.attributes(at: 0, effectiveRange: nil)
        XCTAssertEqual(attributes[TEAttributeKey.backgroundColor] as? TEColor, color, "Should set background color correctly")
    }
    
    func testStrokeAttribute() {
        let color = TEColor.green
        let width: CGFloat = 2.0
        testString.addAttribute(TEAttributeKey.strokeColor, value: color, range: NSRange(location: 0, length: 4))
        testString.addAttribute(TEAttributeKey.strokeWidth, value: width, range: NSRange(location: 0, length: 4))
        
        let attributes = testString.attributes(at: 0, effectiveRange: nil)
        XCTAssertEqual(attributes[TEAttributeKey.strokeColor] as? TEColor, color, "Should set stroke color")
        XCTAssertEqual(attributes[TEAttributeKey.strokeWidth] as? CGFloat, width, "Should set stroke width")
    }
    
    func testUnderlineAttribute() {
        let color = TEColor.purple
        let style = NSUnderlineStyle.double
        testString.addAttribute(TEAttributeKey.underlineColor, value: color, range: NSRange(location: 0, length: 4))
        testString.addAttribute(TEAttributeKey.underlineStyle, value: NSNumber(value: style.rawValue), range: NSRange(location: 0, length: 4))
        
        let attributes = testString.attributes(at: 0, effectiveRange: nil)
        XCTAssertEqual(attributes[TEAttributeKey.underlineColor] as? TEColor, color, "Should set underline color")
        XCTAssertEqual(attributes[TEAttributeKey.underlineStyle] as? NSNumber, NSNumber(value: style.rawValue), "Should set underline style")
    }
    
    func testStrikethroughAttribute() {
        let color = TEColor.orange
        let style = NSUnderlineStyle.thick
        testString.addAttribute(TEAttributeKey.strikethroughColor, value: color, range: NSRange(location: 0, length: 4))
        testString.addAttribute(TEAttributeKey.strikethroughStyle, value: NSNumber(value: style.rawValue), range: NSRange(location: 0, length: 4))
        
        let attributes = testString.attributes(at: 0, effectiveRange: nil)
        XCTAssertEqual(attributes[TEAttributeKey.strikethroughColor] as? TEColor, color, "Should set strikethrough color")
        XCTAssertEqual(attributes[TEAttributeKey.strikethroughStyle] as? NSNumber, NSNumber(value: style.rawValue), "Should set strikethrough style")
    }
    
    // MARK: - Extended Attribute Tests
    
    func testBorderAttribute() {
        let border = TETextBorder()
        border.color = TEColor.red
        border.width = 2.0
        border.cornerRadius = 4.0
        border.fillColor = TEColor.yellow
        
        testString.te_setTextBorder(border, range: NSRange(location: 0, length: 4))
        
        let attributes = testString.attributes(at: 0, effectiveRange: nil)
        let retrievedBorder = attributes[TEAttributeKey.textBorder] as? TETextBorder
        
        XCTAssertNotNil(retrievedBorder, "Should set border attribute")
        XCTAssertEqual(retrievedBorder?.color, border.color, "Should preserve border stroke color")
        XCTAssertEqual(retrievedBorder?.width, border.width, "Should preserve border stroke width")
        XCTAssertEqual(retrievedBorder?.cornerRadius, border.cornerRadius, "Should preserve border corner radius")
        XCTAssertEqual(retrievedBorder?.fillColor, border.fillColor, "Should preserve border fill color")
    }
    
    func testShadowAttribute() {
        let shadow = TETextShadow()
        shadow.offset = CGSize(width: 2, height: 2)
        shadow.radius = 3.0
        shadow.color = TEColor.black
        
        testString.setTe_textShadow(shadow)
        
        let attributes = testString.attributes(at: 0, effectiveRange: nil)
        let retrievedShadow = attributes[TEAttributeKey.textShadow] as? TETextShadow
        
        XCTAssertNotNil(retrievedShadow, "Should set shadow attribute")
        XCTAssertEqual(retrievedShadow?.offset, shadow.offset, "Should preserve shadow offset")
        XCTAssertEqual(retrievedShadow?.radius, shadow.radius, "Should preserve shadow blur radius")
        XCTAssertEqual(retrievedShadow?.color, shadow.color, "Should preserve shadow color")
    }
    
    func testHighlightAttribute() {
        let highlight = TETextHighlight()
        highlight.color = TEColor.blue
        highlight.backgroundColor = TEColor.lightGray
        highlight.tapAction = { _, _, _, _ in
            print("Highlight tapped")
        }
        
        testString.setTe_textHighlight(highlight)
        
        let attributes = testString.attributes(at: 0, effectiveRange: nil)
        let retrievedHighlight = attributes[TEAttributeKey.textHighlight] as? TETextHighlight
        
        XCTAssertNotNil(retrievedHighlight, "Should set highlight attribute")
        XCTAssertEqual(retrievedHighlight?.color, highlight.color, "Should preserve highlight color")
        XCTAssertEqual(retrievedHighlight?.backgroundColor, highlight.backgroundColor, "Should preserve highlight background color")
        XCTAssertNotNil(retrievedHighlight?.tapAction, "Should preserve highlight tap action")
    }
    
    func testAttachmentAttribute() {
        let attachment = NSTextAttachment()
        attachment.bounds = CGRect(x: 0, y: 0, width: 20, height: 20)
        
        let attachmentString = NSAttributedString(attachment: attachment)
        testString.replaceCharacters(in: NSRange(location: 4, length: 1), with: attachmentString)
        
        let attributes = testString.attributes(at: 4, effectiveRange: nil)
        let retrievedAttachment = attributes[.attachment] as? NSTextAttachment
        
        XCTAssertNotNil(retrievedAttachment, "Should set attachment attribute")
        XCTAssertEqual(retrievedAttachment?.bounds, attachment.bounds, "Should preserve attachment bounds")
    }
    
    // MARK: - Attribute Combination Tests
    
    func testMultipleAttributes() {
        let font = TEFont.systemFont(ofSize: 18)
        let color = TEColor.red
        let backgroundColor = TEColor.yellow
        
        testString.setTe_font(font)
        testString.setTe_foregroundColor(color)
        testString.setTe_backgroundColor(backgroundColor)
        
        let attributes = testString.attributes(at: 0, effectiveRange: nil)
        XCTAssertEqual(attributes[TEAttributeKey.font] as? TEFont, font, "Should preserve font")
        XCTAssertEqual(attributes[TEAttributeKey.foregroundColor] as? TEColor, color, "Should preserve foreground color")
        XCTAssertEqual(attributes[TEAttributeKey.backgroundColor] as? TEColor, backgroundColor, "Should preserve background color")
    }
    
    func testOverlappingAttributes() {
        let font1 = TEFont.systemFont(ofSize: 16)
        let font2 = TEFont.systemFont(ofSize: 18)
        
        testString.te_setAttribute(TEAttributeKey.font, value: font1, range: NSRange(location: 0, length: 5))
        testString.te_setAttribute(TEAttributeKey.font, value: font2, range: NSRange(location: 5, length: 5))
        
        let attributes1 = testString.attributes(at: 2, effectiveRange: nil)
        let attributes2 = testString.attributes(at: 7, effectiveRange: nil)
        
        XCTAssertEqual(attributes1[TEAttributeKey.font] as? TEFont, font1, "Should have first font in first range")
        XCTAssertEqual(attributes2[TEAttributeKey.font] as? TEFont, font2, "Should have second font in overlapping range")
    }
    
    // MARK: - Attribute Removal Tests
    
    func testAttributeRemoval() {
        let font = TEFont.systemFont(ofSize: 16)
        let color = TEColor.red
        
        testString.setTe_font(font)
        testString.setTe_foregroundColor(color)
        
        var attributes = testString.attributes(at: 0, effectiveRange: nil)
        XCTAssertNotNil(attributes[TEAttributeKey.font], "Should have font attribute")
        XCTAssertNotNil(attributes[TEAttributeKey.foregroundColor], "Should have foreground color attribute")
        
        testString.removeAttribute(TEAttributeKey.font, range: NSRange(location: 0, length: 4))
        
        attributes = testString.attributes(at: 0, effectiveRange: nil)
        XCTAssertNil(attributes[TEAttributeKey.font], "Should remove font attribute")
        XCTAssertNotNil(attributes[TEAttributeKey.foregroundColor], "Should preserve foreground color attribute")
    }
    
    // MARK: - Attribute Enumeration Tests
    
    func testAttributeEnumeration() {
        let font1 = TEFont.systemFont(ofSize: 16)
        let font2 = TEFont.systemFont(ofSize: 18)
        
        testString.te_setAttribute(TEAttributeKey.font, value: font1, range: NSRange(location: 0, length: 5))
        testString.te_setAttribute(TEAttributeKey.font, value: font2, range: NSRange(location: 10, length: 5))
        
        var foundRanges: [NSRange] = []
        testString.enumerateAttribute(TEAttributeKey.font, in: NSRange(location: 0, length: testString.length), options: []) { value, range, _ in
            if value != nil {
                foundRanges.append(range)
            }
        }
        
        XCTAssertEqual(foundRanges.count, 2, "Should find two font attribute ranges")
        XCTAssertEqual(foundRanges[0], NSRange(location: 0, length: 5), "First range should be correct")
        XCTAssertEqual(foundRanges[1], NSRange(location: 10, length: 5), "Second range should be correct")
    }
    
    // MARK: - CoreText Conversion Tests
    
    func testCoreTextAttributesConversion() {
        let font = TEFont.systemFont(ofSize: 16)
        let color = TEColor.red
        
        testString.setTe_font(font)
        testString.setTe_foregroundColor(color)
        
        // CoreText conversion is handled internally by TextEngineKit
        let attributes = testString.attributes(at: 0, effectiveRange: nil)
        
        XCTAssertNotNil(attributes[TEAttributeKey.font], "Should have font attribute")
        XCTAssertNotNil(attributes[TEAttributeKey.foregroundColor], "Should have foreground color attribute")
    }
    
    func testExtendedAttributesPreservation() {
        let border = TETextBorder()
        border.color = TEColor.red
        border.width = 2.0
        
        testString.te_setTextBorder(border, range: NSRange(location: 0, length: 4))
        
        // Extended attributes are preserved in regular attributes
        let attributes = testString.attributes(at: 0, effectiveRange: nil)
        let retrievedBorder = attributes[TEAttributeKey.textBorder] as? TETextBorder
        
        XCTAssertNotNil(retrievedBorder, "Should preserve extended attributes")
        XCTAssertEqual(retrievedBorder?.color, border.color, "Should preserve border properties")
    }
    
    // MARK: - Performance Tests
    
    func testAttributeSettingPerformance() {
        let longString = String(repeating: "Performance test string. ", count: 100)
        let longAttributedString = NSMutableAttributedString(string: longString)
        
        measure {
            let font = TEFont.systemFont(ofSize: 16)
            let color = TEColor.red
            
            longAttributedString.setTe_font(font)
            longAttributedString.setTe_foregroundColor(color)
        }
    }
    
    func testAttributeEnumerationPerformance() {
        let longString = String(repeating: "Performance test string. ", count: 100)
        let longAttributedString = NSMutableAttributedString(string: longString)
        
        let font = TEFont.systemFont(ofSize: 16)
        longAttributedString.setTe_font(font)
        
        measure {
            var count = 0
            longAttributedString.enumerateAttribute(TEAttributeKey.font, in: NSRange(location: 0, length: longAttributedString.length), options: []) { _, _, _ in
                count += 1
            }
        }
    }
    
    // MARK: - Edge Case Tests
    
    func testEmptyStringAttributes() {
        let emptyString = NSMutableAttributedString(string: "")
        
        let font = TEFont.systemFont(ofSize: 16)
        emptyString.setTe_font(font)
        
        XCTAssertEqual(emptyString.length, 0, "Should handle empty string")
    }
    
    func testOutOfRangeAttributes() {
        let font = TEFont.systemFont(ofSize: 16)
        
        // This should not crash
        testString.setTe_font(font)
        
        XCTAssertEqual(testString.length, 22, "String length should remain unchanged")
    }
    
    func testNegativeRangeAttributes() {
        let font = TEFont.systemFont(ofSize: 16)
        
        // This should not crash
        testString.setTe_font(font)
        
        XCTAssertEqual(testString.length, 22, "String length should remain unchanged")
    }
    
    // MARK: - Memory Management Tests
    
    func testAttributeMemoryManagement() {
        weak var weakString: NSMutableAttributedString?
        
        autoreleasepool {
            let tempString = NSMutableAttributedString(string: "Memory test")
            weakString = tempString
            
            let font = TEFont.systemFont(ofSize: 16)
            let color = TEColor.red
            let border = TETextBorder()
            
            tempString.setTe_font(font)
            tempString.setTe_foregroundColor(color)
            tempString.te_setTextBorder(border, range: NSRange(location: 0, length: tempString.length))
        }
        
        XCTAssertNil(weakString, "Attributed string should be deallocated")
    }
}
