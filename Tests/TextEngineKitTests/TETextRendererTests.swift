import XCTest
import CoreGraphics
import CoreText
@testable import TextEngineKit

final class TETextRendererTests: XCTestCase {
    
    var renderer: TETextRenderer!
    var testText: NSAttributedString!
    var testBounds: CGRect!
    
    override func setUp() {
        super.setUp()
        renderer = TETextRenderer()
        testText = NSAttributedString(string: "Test rendering text", attributes: [
            .font: TEFont.systemFont(ofSize: 16),
            .foregroundColor: TEColor.label
        ])
        testBounds = CGRect(x: 0, y: 0, width: 200, height: 100)
    }
    
    override func tearDown() {
        renderer = nil
        testText = nil
        testBounds = nil
        super.tearDown()
    }
    
    // MARK: - Basic Rendering Tests
    
    func testBasicTextRendering() {
        let options: TERenderOptions = [.antialiased, .fontSmoothing]
        let image = renderer.renderToImage(testText, size: testBounds.size, options: options)
        XCTAssertNotNil(image, "Should generate a valid image")
        XCTAssertEqual(image!.teSize.width, testBounds.width, "Image width should match bounds")
        XCTAssertEqual(image!.teSize.height, testBounds.height, "Image height should match bounds")
    }
    
    func testAsyncTextRendering() {
        let expectation = self.expectation(description: "Async rendering completion")
        let options: TERenderOptions = [.antialiased]
        renderer.renderAsynchronously(testText, size: testBounds.size, options: options) { image in
            XCTAssertNotNil(image, "Should generate a valid image")
            XCTAssertEqual(image!.teSize.width, self.testBounds.width, "Image width should match bounds")
            XCTAssertEqual(image!.teSize.height, self.testBounds.height, "Image height should match bounds")
            expectation.fulfill()
        }
        waitForExpectations(timeout: 5.0, handler: nil)
    }
    
    // MARK: - Rendering Options Tests
    
    func testRenderingWithAntialiasing() {
        let options: TERenderOptions = [.antialiased]
        let image = renderer.renderToImage(testText, size: testBounds.size, options: options)
        XCTAssertNotNil(image, "Should generate image with antialiasing")
    }
    
    func testRenderingWithoutAntialiasing() {
        let options: TERenderOptions = []
        let image = renderer.renderToImage(testText, size: testBounds.size, options: options)
        XCTAssertNotNil(image, "Should generate image without antialiasing")
    }
    
    func testRenderingWithSubpixelPositioning() {
        let options: TERenderOptions = [.subpixelPositioning]
        let image = renderer.renderToImage(testText, size: testBounds.size, options: options)
        XCTAssertNotNil(image, "Should generate image with subpixel positioning")
    }
    
    func testRenderingWithDifferentScaleFactors() {
        let scaleFactors: [CGFloat] = [1.0, 2.0, 3.0]
        for _ in scaleFactors {
            let image = renderer.renderToImage(testText, size: testBounds.size, options: [.antialiased])
            XCTAssertNotNil(image, "Should generate image")
        }
    }
    
    // MARK: - Rich Text Rendering Tests
    
    func testRichTextRendering() {
        let richText = NSMutableAttributedString(string: "Bold and colored text")
        richText.addAttribute(.font, value: TEFont.systemFont(ofSize: 18), range: NSRange(location: 0, length: 4))
        richText.addAttribute(.foregroundColor, value: TEColor.red, range: NSRange(location: 9, length: 8))
        
        let options: TERenderOptions = [.antialiased]
        let image = renderer.renderToImage(richText, size: testBounds.size, options: options)
        XCTAssertNotNil(image, "Should render rich text successfully")
    }
    
    func testTextWithAttachmentsRendering() {
        let attachment = NSTextAttachment()
        attachment.bounds = CGRect(x: 0, y: 0, width: 20, height: 20)
        let attachmentString = NSAttributedString(attachment: attachment)
        
        let combinedText = NSMutableAttributedString()
        combinedText.append(NSAttributedString(string: "Text with "))
        combinedText.append(attachmentString)
        combinedText.append(NSAttributedString(string: " attachment"))
        
        let options: TERenderOptions = [.antialiased]
        let image = renderer.renderToImage(combinedText, size: testBounds.size, options: options)
        XCTAssertNotNil(image, "Should render text with attachments")
    }
    
    // MARK: - Performance Tests
    
    func testRenderingPerformance() {
        let longText = NSAttributedString(string: String(repeating: "Performance test text. ", count: 100))
        let options: TERenderOptions = [.antialiased]
        measure {
            _ = renderer.renderToImage(longText, size: testBounds.size, options: options)
        }
    }
    
    func testAsyncRenderingPerformance() {
        let expectation = self.expectation(description: "Multiple async renders")
        let iterations = 10
        var completed = 0
        
        let longText = NSAttributedString(string: String(repeating: "Async performance test. ", count: 50))
        let options: TERenderOptions = [.antialiased]
        for _ in 0..<iterations {
            renderer.renderAsynchronously(longText, size: testBounds.size, options: options) { image in
                XCTAssertNotNil(image)
                completed += 1
                if completed == iterations { expectation.fulfill() }
            }
        }
        
        waitForExpectations(timeout: 10.0, handler: nil)
    }
    
    // MARK: - Error Handling Tests
    
    func testRenderingWithEmptyText() {
        let emptyText = NSAttributedString(string: "")
        let options: TERenderOptions = [.antialiased]
        let image = renderer.renderToImage(emptyText, size: testBounds.size, options: options)
        XCTAssertNotNil(image, "Should handle empty text")
    }
    
    func testRenderingWithZeroBounds() {
        let zeroBounds = CGRect.zero
        let options: TERenderOptions = [.antialiased]
        let image = renderer.renderToImage(testText, size: zeroBounds.size, options: options)
        XCTAssertNotNil(image, "Should handle zero bounds")
    }
    
    func testRenderingWithNegativeBounds() {
        let negativeBounds = CGRect(x: 0, y: 0, width: -100, height: -100)
        let options: TERenderOptions = [.antialiased]
        let image = renderer.renderToImage(testText, size: negativeBounds.size, options: options)
        XCTAssertNotNil(image, "Should handle negative bounds")
    }
    
    // MARK: - Statistics Tests
    
    func testPerformanceStatistics() {
        let options: TERenderOptions = [.antialiased]
        for _ in 0..<5 { _ = renderer.renderToImage(testText, size: testBounds.size, options: options) }
        let stats = renderer.getStatistics()
        XCTAssertGreaterThan(stats.totalFrameCount, 0, "Should track total renders")
        XCTAssertGreaterThan(stats.averageFrameTime, 0, "Should calculate average render time")
        XCTAssertGreaterThan(stats.totalRenderTime, 0, "Should track total render time")
        XCTAssertGreaterThanOrEqual(stats.minFrameTime, 0, "Should track minimum render time")
        XCTAssertGreaterThanOrEqual(stats.maxFrameTime, stats.minFrameTime, "Max should be >= min")
    }
    
    func testStatisticsReset() {
        let options: TERenderOptions = [.antialiased]
        _ = renderer.renderToImage(testText, size: testBounds.size, options: options)
        var stats = renderer.getStatistics()
        XCTAssertGreaterThan(stats.totalFrameCount, 0, "Should have renders before reset")
        renderer.clearStatistics()
        stats = renderer.getStatistics()
        XCTAssertEqual(stats.totalFrameCount, 0, "Should have zero renders after reset")
        XCTAssertEqual(stats.totalRenderTime, 0, "Should have zero total time after reset")
    }
    
    // MARK: - Concurrent Rendering Tests
    
    func testConcurrentRendering() {
        let expectation = self.expectation(description: "Concurrent rendering completion")
        let iterations = 20
        var completed = 0
        let queue = DispatchQueue(label: "test.concurrent", attributes: .concurrent)
        
        for i in 0..<iterations {
            queue.async {
                let text = NSAttributedString(string: "Concurrent text \(i)")
                let image = self.renderer.renderToImage(text, size: self.testBounds.size, options: [.antialiased])
                XCTAssertNotNil(image, "Should render in concurrent context")
                
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
    
    // MARK: - Memory Management Tests
    
    func testMemoryManagement() {
        weak var weakRenderer: TETextRenderer?
        
        autoreleasepool {
            let tempRenderer = TETextRenderer()
            weakRenderer = tempRenderer
            _ = tempRenderer.renderToImage(testText, size: testBounds.size, options: [.antialiased])
        }
        
        XCTAssertNil(weakRenderer, "Renderer should be deallocated")
    }
}
