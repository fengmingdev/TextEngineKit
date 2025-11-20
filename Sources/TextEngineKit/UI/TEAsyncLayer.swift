import Foundation
import QuartzCore

#if canImport(UIKit)
import UIKit
public typealias TEBaseLayer = CALayer
public typealias TEPlatformImage = UIImage
#elseif canImport(AppKit)
import AppKit
public typealias TEBaseLayer = CALayer
public typealias TEPlatformImage = NSImage
#endif

public protocol TEAsyncLayerDelegate: AnyObject {
    func draw(in context: CGContext, size: CGSize)
}

public final class TEAsyncLayer: TEBaseLayer {
    public weak var asyncDelegate: TEAsyncLayerDelegate?
    public var isAsyncEnabled: Bool = true
    public var renderScale: CGFloat = 1.0
    private let renderQueue = DispatchQueue(label: "com.textenginekit.async.layer", qos: .userInitiated, attributes: .concurrent)
    private let lock = NSLock()
    private var renderVersion: Int = 0

    public override func display() {
        guard let delegate = asyncDelegate else { super.display(); return }
        let size = bounds.size
        if !isAsyncEnabled {
            guard let context = TECreateBitmapContext(size: size, scale: TEPlatform.screenScale * max(renderScale, 0.1), opaque: false) else { return }
            delegate.draw(in: context, size: size)
            setContents(from: context)
            return
        }
        let version: Int = {
            lock.lock(); defer { lock.unlock() }
            return renderVersion
        }()
        renderQueue.async { [weak self] in
            guard let self = self else { return }
            guard let context = TECreateBitmapContext(size: size, scale: TEPlatform.screenScale * max(self.renderScale, 0.1), opaque: false) else { return }
            delegate.draw(in: context, size: size)
            DispatchQueue.main.async {
                self.lock.lock()
                let shouldApply = (version == self.renderVersion)
                self.lock.unlock()
                if shouldApply { self.setContents(from: context) }
            }
        }
    }

    public func cancelAll() {
        lock.lock(); renderVersion &+= 1; lock.unlock()
    }

    private func setContents(from context: CGContext) {
        #if canImport(UIKit)
        if let cg = context.makeImage() { contents = cg }
        #elseif canImport(AppKit)
        if let cg = context.makeImage() { contents = cg }
        #endif
    }
}

public func TECreateBitmapContext(size: CGSize, scale: CGFloat, opaque: Bool) -> CGContext? {
    let width = Int(max(1, size.width * scale))
    let height = Int(max(1, size.height * scale))
    let colorSpace = CGColorSpaceCreateDeviceRGB()
    let bitmapInfo = CGImageAlphaInfo.premultipliedLast.rawValue
    return CGContext(data: nil, width: width, height: height, bitsPerComponent: 8, bytesPerRow: 0, space: colorSpace, bitmapInfo: bitmapInfo)
}
