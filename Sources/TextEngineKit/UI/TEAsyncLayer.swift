// 
//  TEAsyncLayer.swift 
//  TextEngineKit 
// 
//  Created by fengming on 2025/11/17. 
// 
//  异步图层：并发离屏绘制与版本控制，支持主线程安全更新与跨平台图像适配。 
// 
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

/// 异步图层绘制委托协议
///
/// 通过实现此协议，可以自定义 `TEAsyncLayer` 的绘制内容，支持在后台线程进行复杂的图形渲染，
/// 然后将结果异步应用到图层上，避免阻塞主线程。
///
/// 使用示例：
/// ```swift
/// class CustomAsyncDelegate: TEAsyncLayerDelegate {
///     func draw(in context: CGContext, size: CGSize) {
///         // 在后台线程执行复杂的绘制操作
///         context.setFillColor(UIColor.blue.cgColor)
///         context.fillEllipse(in: CGRect(origin: .zero, size: size))
///     }
/// }
///
/// let layer = TEAsyncLayer()
/// layer.asyncDelegate = CustomAsyncDelegate()
/// ```
public protocol TEAsyncLayerDelegate: AnyObject {
    /// 在指定的图形上下文中绘制内容
    ///
    /// 此方法会在后台线程被调用，可以安全地执行耗时的绘制操作。
    /// 绘制完成后，结果会自动应用到图层上。
    ///
    /// - Parameters:
    ///   - context: 用于绘制的图形上下文
    ///   - size: 绘制区域的大小
    func draw(in context: CGContext, size: CGSize)
}

/// 异步渲染图层类
///
/// `TEAsyncLayer` 提供了一个高性能的异步渲染解决方案，支持在后台线程执行复杂的绘制操作，
/// 避免阻塞主线程，从而保持用户界面的流畅性。
///
/// 主要特性：
/// - 支持异步和同步两种渲染模式
/// - 内置版本控制机制，自动取消过期的渲染任务
/// - 线程安全的渲染队列管理
/// - 支持自定义渲染缩放比例
///
/// 使用示例：
/// ```swift
/// class CustomDrawingView: UIView {
///     private let asyncLayer = TEAsyncLayer()
///     
///     override init(frame: CGRect) {
///         super.init(frame: frame)
///         layer.addSublayer(asyncLayer)
///         asyncLayer.asyncDelegate = self
///         asyncLayer.isAsyncEnabled = true // 启用异步渲染
///     }
/// }
///
/// extension CustomDrawingView: TEAsyncLayerDelegate {
///     func draw(in context: CGContext, size: CGSize) {
///         // 执行复杂的绘制操作
///         let path = UIBezierPath(ovalIn: CGRect(origin: .zero, size: size))
///         context.setFillColor(UIColor.systemBlue.cgColor)
///         context.addPath(path.cgPath)
///         context.fillPath()
///     }
/// }
/// ```
public final class TEAsyncLayer: TEBaseLayer {
    /// 异步绘制委托
    ///
    /// 设置此属性来接收绘制回调。委托对象会在后台线程收到绘制请求，
    /// 可以安全地执行耗时的绘制操作而不会阻塞主线程。
    public weak var asyncDelegate: TEAsyncLayerDelegate?
    
    /// 是否启用异步渲染
    ///
    /// 当设置为 `true` 时，绘制操作会在后台线程执行，然后异步应用到图层。
    /// 当设置为 `false` 时，绘制操作会同步执行，适用于简单的绘制场景。
    /// 默认值为 `true`。
    public var isAsyncEnabled: Bool = true
    
    /// 渲染缩放比例
    ///
    /// 控制渲染内容的缩放比例。较高的值会产生更清晰的图像，但会增加内存使用。
    /// 默认值为 `1.0`，通常不需要修改，除非需要支持高 DPI 显示。
    public var renderScale: CGFloat = 1.0
    private let renderQueue = DispatchQueue(label: "com.textenginekit.async.layer", qos: .userInitiated, attributes: .concurrent)
    private let lock = NSLock()
    private var renderVersion: Int = 0

    /// 触发图层内容更新
    ///
    /// 当图层需要重绘时，系统会自动调用此方法。
    /// 如果启用了异步渲染，绘制操作会在后台线程执行，然后通过版本控制机制确保只应用最新的渲染结果。
    ///
    /// 版本控制机制说明：
    /// - 每次调用 `display()` 时，会记录当前的渲染版本号
    /// - 异步渲染完成后，会检查版本号是否仍然匹配
    /// - 如果不匹配（表示有新的渲染请求），则丢弃当前结果
    /// - 这样可以确保用户界面始终显示最新的内容，避免闪烁
    public override func display() {
        guard let delegate = asyncDelegate else { super.display(); return }
        let size = bounds.size
        let format = TEPlatform.makeRendererFormat(scale: TEPlatform.screenScale * max(renderScale, 0.1), opaque: false, extendedRange: true)
        if !isAsyncEnabled {
            let renderer = TEPlatform.createGraphicsRenderer(size: size, format: format)
            let image = renderer.render { context in
                delegate.draw(in: context, size: size)
            }
            setContents(from: image)
            return
        }
        let version: Int = {
            lock.lock(); defer { lock.unlock() }
            return renderVersion
        }()
        renderQueue.async { [weak self] in
            guard let self = self else { return }
            let f = TEPlatform.makeRendererFormat(scale: TEPlatform.screenScale * max(self.renderScale, 0.1), opaque: false, extendedRange: true)
            let renderer = TEPlatform.createGraphicsRenderer(size: size, format: f)
            let image = renderer.render { context in
                delegate.draw(in: context, size: size)
            }
            DispatchQueue.main.async {
                self.lock.lock()
                let shouldApply = (version == self.renderVersion)
                self.lock.unlock()
                if shouldApply { self.setContents(from: image) }
            }
        }
    }

    /// 取消所有正在进行的异步渲染任务
    ///
    /// 调用此方法会递增渲染版本号，导致所有正在进行的异步渲染任务的结果被丢弃。
    /// 这通常在图层即将被销毁或需要立即重新渲染时使用。
    ///
    /// 使用场景：
    /// - 视图控制器被释放时
    /// - 需要立即中断当前渲染并重新开始时
    /// - 图层属性发生重要变化，需要丢弃旧结果时
    public func cancelAll() {
        lock.lock(); renderVersion &+= 1; lock.unlock()
    }

    private func setContents(from image: TEPlatformImage?) {
        if let image = image, let cg = TEPlatform.cgImage(from: image) { contents = cg }
    }
}

// removed
