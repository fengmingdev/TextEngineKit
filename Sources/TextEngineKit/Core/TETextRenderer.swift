// 
//  TETextRenderer.swift 
//  TextEngineKit 
// 
//  Created by fengming on 2025/11/17. 
// 
//  文本渲染器：高性能同步/异步渲染、统计与装饰选项，支持图像输出。 
// 
import Foundation
import CoreText
import CoreGraphics

/// 文本渲染器
/// 负责高性能文本渲染和绘制
public final class TETextRenderer: TERendererProtocol {
    
    // MARK: - 属性
    
    /// 取消中的任务集合
    private var cancelledTasks = Set<UUID>()
    
    /// 渲染队列
    private let renderQueue: DispatchQueue
    
    /// 渲染统计信息
    private var renderStatistics = TERenderStatistics()
    
    /// 线程安全锁
    private let lock = NSLock()
    
    /// 是否启用异步渲染
    private let enableAsyncRendering: Bool
    
    /// 高亮状态提供者（根据 NSRange 判断是否激活）
    public var highlightStateProvider: ((NSRange) -> Bool)?
    /// 高亮进度提供者（0..1），用于淡入淡出动画
    public var highlightProgressProvider: ((NSRange) -> CGFloat)?

    /// 装饰混合模式
    public var decorationBlendMode: CGBlendMode = .normal
    
    // MARK: - 初始化
    
    public init(enableAsyncRendering: Bool = true) {
        self.enableAsyncRendering = enableAsyncRendering
        self.renderQueue = DispatchQueue(
            label: "com.textenginekit.render",
            qos: .userInitiated,
            attributes: .concurrent
        )
        
        TETextEngine.shared.logDebug("文本渲染器初始化完成，异步渲染: \(enableAsyncRendering)", category: "rendering")
    }
    
    // MARK: - 公共方法
    
    /// 同步渲染文本
    /// - Parameters:
    ///   - attributedString: 属性字符串
    ///   - context: 图形上下文
    ///   - rect: 渲染矩形
    ///   - options: 渲染选项
    public func renderSynchronously(
        _ attributedString: NSAttributedString,
        in context: CGContext,
        rect: CGRect,
        options: TERenderOptions = []
    ) {
        let startTime = CFAbsoluteTimeGetCurrent()
        
        // 保存图形状态
        context.saveGState()
        
        // 应用渲染选项
        applyRenderOptions(options, to: context)
        
        // 创建布局管理器
        let layoutManager = TELayoutManager()
        let layoutInfo = layoutManager.layoutSynchronously(attributedString, size: rect.size)
        
        // 渲染文本
        renderLayoutInfo(layoutInfo, in: context, rect: rect)
        
        // 恢复图形状态
        context.restoreGState()
        
        let duration = (CFAbsoluteTimeGetCurrent() - startTime) * 1000
        updateStatistics(frameCount: 1, totalDuration: duration, averageFrameTime: duration)
        
        TETextEngine.shared.logRenderingPerformance(
            frameCount: 1,
            totalDuration: duration,
            averageFrameTime: duration
        )
        
        }
    
    /// 异步渲染文本
    /// - Parameters:
    ///   - attributedString: 属性字符串
    ///   - size: 渲染尺寸
    ///   - options: 渲染选项
    ///   - completion: 完成回调，返回渲染后的图像
    public func renderAsynchronously(
        _ attributedString: NSAttributedString,
        size: CGSize,
        options: TERenderOptions = [],
        completion: @escaping (TEImage?) -> Void
    ) {
        guard enableAsyncRendering else {
            // 如果禁用异步渲染，使用同步方式
            let image = renderToImage(attributedString, size: size, options: options)
            completion(image)
            return
        }
        
        renderQueue.async { [weak self] in
            guard let self = self else {
                completion(nil)
                return
            }
            
            let startTime = CFAbsoluteTimeGetCurrent()
            
            // 创建图像上下文
            let format = TEPlatform.makeRendererFormat(scale: TEPlatform.screenScale, opaque: !options.contains(.transparentBackground), extendedRange: true)
            
            let safeSize = CGSize(width: max(1, abs(size.width)), height: max(1, abs(size.height)))
            let renderer = TEPlatform.createGraphicsRenderer(size: safeSize, format: format)
            let image = renderer.render { context in
                self.renderSynchronously(attributedString, in: context, rect: CGRect(origin: .zero, size: safeSize), options: options)
            }
            
            let duration = (CFAbsoluteTimeGetCurrent() - startTime) * 1000
            self.updateStatistics(frameCount: 1, totalDuration: duration, averageFrameTime: duration)
            
            TETextEngine.shared.logRenderingPerformance(
                frameCount: 1,
                totalDuration: duration,
                averageFrameTime: duration
            )
            
            DispatchQueue.main.async {
                completion(image)
            }
        }
    }

    /// 可取消的异步渲染，返回取消标识
    public func renderAsynchronouslyCancelable(
        _ attributedString: NSAttributedString,
        size: CGSize,
        options: TERenderOptions = [],
        completion: @escaping (TEImage?) -> Void
    ) -> UUID {
        let id = UUID()
        renderQueue.async { [weak self] in
            guard let self = self else { return }
            let format = TEPlatform.makeRendererFormat(scale: TEPlatform.screenScale, opaque: !options.contains(.transparentBackground), extendedRange: true)
            let safeSize = CGSize(width: max(1, abs(size.width)), height: max(1, abs(size.height)))
            let renderer = TEPlatform.createGraphicsRenderer(size: safeSize, format: format)
            let image = renderer.render { context in
                self.renderSynchronously(attributedString, in: context, rect: CGRect(origin: .zero, size: safeSize), options: options)
            }
            DispatchQueue.main.async {
                self.lock.lock()
                let isCancelled = self.cancelledTasks.contains(id)
                self.lock.unlock()
                if !isCancelled { completion(image) }
            }
        }
        return id
    }
    
    /// 渲染到图像
    /// - Parameters:
    ///   - attributedString: 属性字符串
    ///   - size: 图像尺寸
    ///   - options: 渲染选项
    /// - Returns: 渲染后的图像
    public func renderToImage(
        _ attributedString: NSAttributedString,
        size: CGSize,
        options: TERenderOptions = []
    ) -> TEImage? {
        let format = TEPlatform.makeRendererFormat(scale: TEPlatform.screenScale, opaque: !options.contains(.transparentBackground), extendedRange: true)
        
        let safeSize = CGSize(width: max(1, abs(size.width)), height: max(1, abs(size.height)))
        let renderer = TEPlatform.createGraphicsRenderer(size: safeSize, format: format)
        
        return renderer.render { context in
            self.renderSynchronously(attributedString, in: context, rect: CGRect(origin: .zero, size: safeSize), options: options)
        }
    }
    
    /// 获取渲染统计信息
    /// - Returns: 统计信息
    public func getStatistics() -> TERenderStatistics {
        lock.lock()
        defer { lock.unlock() }
        return renderStatistics
    }
    
    /// 清除渲染统计
    public func clearStatistics() {
        lock.lock()
        defer { lock.unlock() }
        renderStatistics = TERenderStatistics()
    }

    /// 取消异步渲染
    public func cancelRendering(task id: UUID) {
        lock.lock(); cancelledTasks.insert(id); lock.unlock()
    }
    
    // MARK: - 私有方法
    
    /// 应用渲染选项
    /// - Parameters:
    ///   - options: 渲染选项
    ///   - context: 图形上下文
    private func applyRenderOptions(_ options: TERenderOptions, to context: CGContext) {
        if options.contains(.antialiased) {
            context.setShouldAntialias(true)
        }
        
        if options.contains(.subpixelPositioning) {
            context.setAllowsFontSubpixelPositioning(true)
            context.setShouldSubpixelPositionFonts(true)
        }
        
        if options.contains(.subpixelQuantization) {
            context.setAllowsFontSubpixelQuantization(true)
            context.setShouldSubpixelQuantizeFonts(true)
        }
        
        if options.contains(.fontSmoothing) {
            context.setAllowsFontSmoothing(true)
            context.setShouldSmoothFonts(true)
        }
    }
    
    /// 渲染布局信息
    /// - Parameters:
    ///   - layoutInfo: 布局信息
    ///   - context: 图形上下文
    ///   - rect: 渲染矩形
    private func renderLayoutInfo(_ layoutInfo: TELayoutInfo, in context: CGContext, rect: CGRect) {
        guard !layoutInfo.lines.isEmpty else { return }
        setupTextDrawingContext(context, rect: rect)
        let didClip = applyExclusionClippingIfNeeded(context, layoutInfo: layoutInfo)
        for (index, line) in layoutInfo.lines.enumerated() {
            let origin = layoutInfo.lineOrigins[index]
            drawLine(line, origin: CGPoint(x: origin.x + rect.origin.x, y: origin.y + rect.origin.y), in: context, rect: rect, layoutInfo: layoutInfo)
        }
        finalizeExclusionClipping(context, didClip: didClip)
    }

    private func setupTextDrawingContext(_ context: CGContext, rect: CGRect) {
        context.textMatrix = .identity
        context.translateBy(x: 0, y: rect.height)
        context.scaleBy(x: 1.0, y: -1.0)
    }

    private func applyExclusionClippingIfNeeded(_ context: CGContext, layoutInfo: TELayoutInfo) -> Bool {
        guard !layoutInfo.exclusionPaths.isEmpty else { return false }
        let framePath = CTFrameGetPath(layoutInfo.frame)
        let clipPath = TEPathUtilities.combineForClipping(container: framePath, exclusions: layoutInfo.exclusionPaths)
        context.saveGState()
        context.addPath(clipPath)
        context.clip(using: .evenOdd)
        return true
    }

    private func finalizeExclusionClipping(_ context: CGContext, didClip: Bool) {
        if didClip { context.restoreGState() }
    }

    private func drawLine(_ line: CTLine, origin: CGPoint, in context: CGContext, rect: CGRect, layoutInfo: TELayoutInfo) {
        context.textPosition = origin
        let cfRuns = CTLineGetGlyphRuns(line)
        let runs = (cfRuns as NSArray as? [CTRun]) ?? []
        for run in runs {
            drawRun(run, line: line, adjustedOrigin: origin, in: context, layoutInfo: layoutInfo)
        }
    }

    private func drawRun(_ run: CTRun, line: CTLine, adjustedOrigin: CGPoint, in context: CGContext, layoutInfo: TELayoutInfo) {
        let attrs = CTRunGetAttributes(run) as NSDictionary
        var ascent: CGFloat = 0
        var descent: CGFloat = 0
        var leading: CGFloat = 0
        let width = CGFloat(CTRunGetTypographicBounds(run, CFRange(location: 0, length: 0), &ascent, &descent, &leading))
        let runRange = CTRunGetStringRange(run)
        let offset = CTLineGetOffsetForStringIndex(line, runRange.location, nil)
        let runRect = CGRect(x: adjustedOrigin.x + CGFloat(offset), y: adjustedOrigin.y - descent, width: width, height: ascent + descent)
        if let border = attrs[TEAttributeKey.textBorder] as? TETextBorder {
            border.draw(in: context, rect: runRect, lineOrigin: adjustedOrigin, lineAscent: ascent, lineDescent: descent, lineHeight: ascent + descent)
        }
        if let bgBorder = attrs[TEAttributeKey.textBackgroundBorder] as? TETextBorder {
            bgBorder.draw(in: context, rect: runRect, lineOrigin: adjustedOrigin, lineAscent: ascent, lineDescent: descent, lineHeight: ascent + descent)
        }
        if let highlight = attrs[TEAttributeKey.textHighlight] as? TETextHighlight {
            let range = NSRange(location: runRange.location, length: runRange.length)
            let isActive = highlightStateProvider?(range) ?? true
            if isActive {
                context.saveGState()
                context.setBlendMode(decorationBlendMode)
                let progress = highlightProgressProvider?(range) ?? 1
                context.setAlpha(progress)
                highlight.draw(in: context, rect: runRect, isHighlighted: true)
                context.restoreGState()
            }
        }
        var hasTransform = false
        var transform = CGAffineTransform.identity
        if let t = attrs[TEAttributeKey.glyphTransform] as? CGAffineTransform {
            transform = t
            hasTransform = true
        }
        let hasExclusions = !layoutInfo.exclusionPaths.isEmpty
        let intersectsExclusions = hasExclusions && layoutInfo.exclusionPaths.contains { $0.boundingBox.intersects(runRect) }
        if intersectsExclusions {
            let glyphCount = CTRunGetGlyphCount(run)
            var positions = [CGPoint](repeating: .zero, count: glyphCount)
            CTRunGetPositions(run, CFRange(location: 0, length: 0), &positions)
            for i in 0..<glyphCount {
                var gAsc: CGFloat = 0
                var gDesc: CGFloat = 0
                var gLead: CGFloat = 0
                let gWidth = CGFloat(CTRunGetTypographicBounds(run, CFRange(location: i, length: 1), &gAsc, &gDesc, &gLead))
                let gx = adjustedOrigin.x + positions[i].x
                let gy = adjustedOrigin.y
                let gRect = CGRect(x: gx, y: gy - gDesc, width: max(gWidth, 0.1), height: gAsc + gDesc)
                let center = CGPoint(x: gRect.midX, y: gRect.midY)
                let excluded = layoutInfo.exclusionPaths.contains { $0.contains(center) }
                if excluded { continue }
                context.saveGState()
                context.translateBy(x: gx, y: gy)
                if hasTransform { context.concatenate(transform) }
                context.textPosition = .zero
                CTRunDraw(run, context, CFRange(location: i, length: 1))
                context.restoreGState()
            }
        } else {
            context.saveGState()
            context.translateBy(x: adjustedOrigin.x + CGFloat(offset), y: adjustedOrigin.y)
            if hasTransform { context.concatenate(transform) }
            context.textPosition = .zero
            CTRunDraw(run, context, CFRange(location: 0, length: 0))
            context.restoreGState()
        }
    }

    
    /// 更新统计信息
    /// - Parameters:
    ///   - frameCount: 帧数
    ///   - totalDuration: 总耗时
    ///   - averageFrameTime: 平均每帧时间
    private func updateStatistics(frameCount: Int, totalDuration: TimeInterval, averageFrameTime: TimeInterval) {
        lock.lock()
        defer { lock.unlock() }
        
        renderStatistics.totalFrameCount += frameCount
        renderStatistics.totalRenderTime += totalDuration
        renderStatistics.averageFrameTime = renderStatistics.totalRenderTime / Double(renderStatistics.totalFrameCount)
        
        if totalDuration > renderStatistics.maxFrameTime {
            renderStatistics.maxFrameTime = totalDuration
        }
        
        if renderStatistics.minFrameTime == 0 || totalDuration < renderStatistics.minFrameTime {
            renderStatistics.minFrameTime = totalDuration
        }
        
        // 计算 FPS
        if totalDuration > 0 {
            let fps = Double(frameCount) / (totalDuration / 1000.0)
            renderStatistics.averageFPS = fps
            
            if fps > renderStatistics.maxFPS {
                renderStatistics.maxFPS = fps
            }
            
            if renderStatistics.minFPS == 0 || fps < renderStatistics.minFPS {
                renderStatistics.minFPS = fps
            }
        }
    }
}

// MARK: - 渲染选项

/// 渲染选项
public struct TERenderOptions: OptionSet {
    public let rawValue: Int
    
    public init(rawValue: Int) {
        self.rawValue = rawValue
    }
    
    /// 抗锯齿
    public static let antialiased = TERenderOptions(rawValue: 1 << 0)
    
    /// 透明背景
    public static let transparentBackground = TERenderOptions(rawValue: 1 << 1)
    
    /// 子像素定位
    public static let subpixelPositioning = TERenderOptions(rawValue: 1 << 2)
    
    /// 子像素量化
    public static let subpixelQuantization = TERenderOptions(rawValue: 1 << 3)
    
    /// 字体平滑
    public static let fontSmoothing = TERenderOptions(rawValue: 1 << 4)
    
    /// 高质量渲染（包含所有优化选项）
    public static let highQuality: TERenderOptions = [
        .antialiased,
        .subpixelPositioning,
        .subpixelQuantization,
        .fontSmoothing
    ]
    
    /// 默认渲染选项
    public static let `default`: TERenderOptions = [.antialiased, .fontSmoothing]
}

// MARK: - 渲染统计信息

/// 渲染统计信息
public struct TERenderStatistics {
    /// 总帧数
    public var totalFrameCount: Int = 0
    
    /// 总渲染时间（毫秒）
    public var totalRenderTime: TimeInterval = 0
    
    /// 平均每帧时间（毫秒）
    public var averageFrameTime: TimeInterval = 0
    
    /// 最大帧时间（毫秒）
    public var maxFrameTime: TimeInterval = 0
    
    /// 最小帧时间（毫秒）
    public var minFrameTime: TimeInterval = 0
    
    /// 平均 FPS
    public var averageFPS: Double = 0
    
    /// 最大 FPS
    public var maxFPS: Double = 0
    
    /// 最小 FPS
    public var minFPS: Double = 0
    
    /// 描述信息
    public var description: String {
        return """
        渲染统计:
        - 总帧数: \(totalFrameCount)
        - 平均帧时间: \(String(format: "%.3f", averageFrameTime))ms
        - 最大帧时间: \(String(format: "%.3f", maxFrameTime))ms
        - 最小帧时间: \(String(format: "%.3f", minFrameTime))ms
        - 平均 FPS: \(String(format: "%.1f", averageFPS))
        - 最大 FPS: \(String(format: "%.1f", maxFPS))
        - 最小 FPS: \(String(format: "%.1f", minFPS))
        """
    }
}
public protocol TERendererProtocol {
    func renderSynchronously(_ text: NSAttributedString, in context: CGContext, rect: CGRect, options: TERenderOptions)
}
