import XCTest
@testable import TextEngineKit
import CoreGraphics

final class TETextContainerTests: XCTestCase {
    
    func testBasicContainerCreation() {
        let container = TETextContainer()
        XCTAssertNotNil(container)
        XCTAssertNil(container.path)
        XCTAssertEqual(container.exclusionPaths.count, 0)
    }
    
    func testCircularPathCreation() {
        let path = TEPathUtilities.createCircularPath(center: CGPoint(x: 100, y: 100), radius: 50)
        XCTAssertNotNil(path)
        
        let bounds = path.boundingBox
        XCTAssertEqual(bounds.width, 100, accuracy: 0.1)
        XCTAssertEqual(bounds.height, 100, accuracy: 0.1)
    }
    
    func testRoundedRectPathCreation() {
        let rect = CGRect(x: 0, y: 0, width: 200, height: 100)
        let path = TEPathUtilities.createRoundedRectPath(rect, cornerRadius: 10)
        XCTAssertNotNil(path)
        
        let bounds = path.boundingBox
        XCTAssertEqual(bounds.width, 200, accuracy: 0.1)
        XCTAssertEqual(bounds.height, 100, accuracy: 0.1)
    }
    
    func testStarPathCreation() {
        let path = TEPathUtilities.createStarPath(
            center: CGPoint(x: 100, y: 100),
            points: 5,
            outerRadius: 50,
            innerRadius: 25
        )
        XCTAssertNotNil(path)
        
        let bounds = path.boundingBox
        XCTAssertEqual(bounds.width, 100, accuracy: 0.1)
        XCTAssertEqual(bounds.height, 100, accuracy: 0.1)
    }
    
    func testPathOffset() {
        let originalPath = TEPathUtilities.createCircularPath(center: CGPoint(x: 100, y: 100), radius: 50)
        let offsetPath = TEPathUtilities.offsetPath(originalPath, offset: 10)
        
        XCTAssertNotNil(offsetPath)
        
        let originalBounds = originalPath.boundingBox
        let offsetBounds = offsetPath.boundingBox
        
        // Offset path should be larger
        XCTAssertGreaterThan(offsetBounds.width, originalBounds.width)
        XCTAssertGreaterThan(offsetBounds.height, originalBounds.height)
    }
    
    func testPathLengthCalculation() {
        let path = TEPathUtilities.createCircularPath(center: CGPoint(x: 100, y: 100), radius: 50)
        let length = TEPathUtilities.calculatePathLength(path)
        
        // Circumference should be approximately 2 * pi * r
        let expectedLength = 2 * CGFloat.pi * 50
        XCTAssertEqual(length, expectedLength, accuracy: 10.0) // Allow some tolerance for path approximation
    }
    
    func testPointOnPath() {
        let path = TEPathUtilities.createCircularPath(center: CGPoint(x: 100, y: 100), radius: 50)
        let pathLength = TEPathUtilities.calculatePathLength(path)
        
        let point = TEPathUtilities.getPointOnPath(path, distance: pathLength / 4)
        XCTAssertNotNil(point)
    }
    
    func testContainerWithPath() {
        let container = TETextContainer()
        let path = TEPathUtilities.createCircularPath(center: CGPoint(x: 100, y: 100), radius: 50)
        
        container.path = path
        XCTAssertNotNil(container.path)
        
        let bounds = container.pathBounds
        XCTAssertEqual(bounds.width, 100, accuracy: 0.1)
        XCTAssertEqual(bounds.height, 100, accuracy: 0.1)
    }
    
    func testExclusionPaths() {
        let container = TETextContainer()
        let exclusionPath = TEPathUtilities.createCircularPath(center: CGPoint(x: 100, y: 100), radius: 20)
        
        container.exclusionPaths = [exclusionPath]
        XCTAssertEqual(container.exclusionPaths.count, 1)
        
        let exclusionBounds = container.exclusionPathBounds
        XCTAssertEqual(exclusionBounds.width, 40, accuracy: 0.1)
        XCTAssertEqual(exclusionBounds.height, 40, accuracy: 0.1)
    }
    
    func testContainerSerialization() {
        let container = TETextContainer()
        let path = TEPathUtilities.createCircularPath(center: CGPoint(x: 100, y: 100), radius: 50)
        container.path = path
        
        let exclusionPath = TEPathUtilities.createCircularPath(center: CGPoint(x: 100, y: 100), radius: 20)
        container.exclusionPaths = [exclusionPath]
        
        // Test archiving
        let data = try? NSKeyedArchiver.archivedData(withRootObject: container, requiringSecureCoding: true)
        XCTAssertNotNil(data, "Container should be archivable")
        
        // Test unarchiving (secure with allowed classes)
        let unarchivedContainer = TETextContainer.unarchiveSecureManual(from: data!)
        XCTAssertNotNil(unarchivedContainer, "Container should be unarchivable")
        
        // Verify properties
        XCTAssertNotNil(unarchivedContainer?.path)
        XCTAssertEqual(unarchivedContainer?.exclusionPaths.count, 1)
    }
    
    func testTextWrapPathCreation() {
        let rect = CGRect(x: 0, y: 0, width: 300, height: 200)
        let imageRect = CGRect(x: 100, y: 50, width: 100, height: 100)
        
        let wrapPath = TEPathUtilities.createTextWrapPath(rect: rect, imageRect: imageRect, margin: 10)
        XCTAssertNotNil(wrapPath)
        
        let bounds = wrapPath.boundingBox
        XCTAssertGreaterThan(bounds.width, 0)
        XCTAssertGreaterThan(bounds.height, 0)
    }
    
    func testExclusionPathCreation() {
        let rect = CGRect(x: 50, y: 50, width: 100, height: 100)
        
        let exclusionPath = TEPathUtilities.createExclusionPath(rect: rect, cornerRadius: 10)
        XCTAssertNotNil(exclusionPath)
        
        let bounds = exclusionPath.boundingBox
        XCTAssertEqual(bounds.width, 100, accuracy: 0.1)
        XCTAssertEqual(bounds.height, 100, accuracy: 0.1)
    }
    
    func testCGPathExtension() {
        let path = TEPathUtilities.createCircularPath(center: CGPoint(x: 100, y: 100), radius: 50)
        
        // Test point inside circle
        let insidePoint = CGPoint(x: 100, y: 100)
        XCTAssertTrue(path.contains(insidePoint))
        
        // Test point outside circle
        let outsidePoint = CGPoint(x: 200, y: 200)
        XCTAssertFalse(path.contains(outsidePoint))
    }
}
