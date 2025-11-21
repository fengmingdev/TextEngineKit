import XCTest
import Foundation
import CoreText
@testable import TextEngineKit

final class HighlightTests: XCTestCase {
    func testBoundingRectForLinkRange() {
        let text = NSMutableAttributedString(string: "Hello World")
        let linkRange = NSRange(location: 6, length: 5)
        text.addAttribute(.link, value: "https://example.com", range: linkRange)

        let lm = TELayoutManager()
        let info = lm.layoutSynchronously(text, size: CGSize(width: 200, height: 50), options: [])

        let mgr = TEHighlightManager()
        let rect = mgr.boundingRect(for: linkRange, in: text, textRect: CGRect(x: 0, y: 0, width: 200, height: 50), layoutInfo: info)
        XCTAssertFalse(rect.equalTo(.zero))
        XCTAssertGreaterThan(rect.width, 0)
        XCTAssertGreaterThan(rect.height, 0)
    }

    func testCharacterIndexHitOnLinkMidpoint() {
        let text = NSMutableAttributedString(string: "Hello World")
        let linkRange = NSRange(location: 6, length: 5)
        text.addAttribute(.link, value: "https://example.com", range: linkRange)

        let lm = TELayoutManager()
        let info = lm.layoutSynchronously(text, size: CGSize(width: 200, height: 50), options: [])

        let mgr = TEHighlightManager()
        let rect = mgr.boundingRect(for: linkRange, in: text, textRect: CGRect(x: 0, y: 0, width: 200, height: 50), layoutInfo: info)
        let midpoint = CGPoint(x: rect.midX, y: rect.midY)
        let idx = mgr.characterIndex(at: midpoint, in: text, textRect: CGRect(x: 0, y: 0, width: 200, height: 50), layoutInfo: info)
        XCTAssertNotEqual(idx, NSNotFound)
        XCTAssertTrue(NSLocationInRange(idx, linkRange))
    }
}
