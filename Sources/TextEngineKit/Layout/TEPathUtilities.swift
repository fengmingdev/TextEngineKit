// 
//  TEPathUtilities.swift 
//  TextEngineKit 
// 
//  Created by fengming on 2025/11/17. 
// 
//  路径工具：提供几何计算与裁剪辅助，用于文本布局与绘制。 
// 
import Foundation
import CoreGraphics

/// 路径工具类
/// 提供常用的文本容器路径创建和操作功能
public final class TEPathUtilities {
    
    // MARK: - 基础路径创建
    
    /// 创建圆形路径
    /// - Parameters:
    ///   - center: 圆心
    ///   - radius: 半径
    /// - Returns: 圆形路径
    public static func createCircularPath(center: CGPoint, radius: CGFloat) -> CGPath {
        let path = CGMutablePath()
        path.addEllipse(in: CGRect(x: center.x - radius, y: center.y - radius, width: radius * 2, height: radius * 2))
        return path
    }
    
    /// 创建圆角矩形路径
    /// - Parameters:
    ///   - rect: 矩形
    ///   - cornerRadius: 圆角半径
    /// - Returns: 圆角矩形路径
    public static func createRoundedRectPath(_ rect: CGRect, cornerRadius: CGFloat) -> CGPath {
        let path = CGMutablePath()
        path.addRoundedRect(in: rect, cornerWidth: cornerRadius, cornerHeight: cornerRadius)
        return path
    }
    
    /// 创建椭圆路径
    /// - Parameter rect: 矩形
    /// - Returns: 椭圆路径
    public static func createEllipsePath(_ rect: CGRect) -> CGPath {
        let path = CGMutablePath()
        path.addEllipse(in: rect)
        return path
    }
    
    /// 创建多边形路径
    /// - Parameters:
    ///   - points: 顶点数组
    ///   - closed: 是否闭合
    /// - Returns: 多边形路径
    public static func createPolygonPath(points: [CGPoint], closed: Bool = true) -> CGPath {
        guard !points.isEmpty else { return CGMutablePath() }
        
        let path = CGMutablePath()
        path.move(to: points[0])
        
        for i in 1..<points.count {
            path.addLine(to: points[i])
        }
        
        if closed && points.count > 2 {
            path.closeSubpath()
        }
        
        return path
    }
    
    /// 创建星形路径
    /// - Parameters:
    ///   - center: 中心点
    ///   - points: 顶点数量
    ///   - outerRadius: 外半径
    ///   - innerRadius: 内半径
    /// - Returns: 星形路径
    public static func createStarPath(center: CGPoint, points: Int, outerRadius: CGFloat, innerRadius: CGFloat) -> CGPath {
        guard points >= 3 else { return CGMutablePath() }
        
        let path = CGMutablePath()
        let angleStep = CGFloat.pi * 2 / CGFloat(points)
        
        for i in 0..<points {
            let outerAngle = CGFloat(i) * angleStep - CGFloat.pi // 使左右极值覆盖直径
            let innerAngle = outerAngle + angleStep / 2
            
            let outerPoint = CGPoint(
                x: center.x + cos(outerAngle) * outerRadius,
                y: center.y + sin(outerAngle) * outerRadius
            )
            let innerPoint = CGPoint(
                x: center.x + cos(innerAngle) * innerRadius,
                y: center.y + sin(innerAngle) * innerRadius
            )
            
            if i == 0 {
                path.move(to: outerPoint)
            } else {
                path.addLine(to: outerPoint)
            }
            path.addLine(to: innerPoint)
        }
        
        path.closeSubpath()
        // 统一将星形缩放到外半径直径的边界（宽高=2*outerRadius）
        let bounds = path.boundingBox
        let center = CGPoint(x: center.x, y: center.y)
        let sx = (outerRadius * 2) / max(bounds.width, 1)
        let sy = (outerRadius * 2) / max(bounds.height, 1)
        var transform = CGAffineTransform.identity
        transform = transform.translatedBy(x: center.x, y: center.y)
        transform = transform.scaledBy(x: sx, y: sy)
        transform = transform.translatedBy(x: -center.x, y: -center.y)
        return path.copy(using: &transform) ?? path
    }
    
    // MARK: - 高级路径创建
    
    /// 创建螺旋路径
    /// - Parameters:
    ///   - center: 中心点
    ///   - startRadius: 起始半径
    ///   - endRadius: 结束半径
    ///   - turns: 圈数
    ///   - startAngle: 起始角度（弧度）
    /// - Returns: 螺旋路径
    public static func createSpiralPath(
        center: CGPoint,
        startRadius: CGFloat,
        endRadius: CGFloat,
        turns: CGFloat,
        startAngle: CGFloat = 0
    ) -> CGPath {
        let path = CGMutablePath()
        let totalAngle = turns * CGFloat.pi * 2
        let steps = Int(max(100, turns * 50)) // 确保足够的精度
        
        for i in 0...steps {
            let t = CGFloat(i) / CGFloat(steps)
            let angle = startAngle + t * totalAngle
            let radius = startRadius + (endRadius - startRadius) * t
            
            let point = CGPoint(
                x: center.x + cos(angle) * radius,
                y: center.y + sin(angle) * radius
            )
            
            if i == 0 {
                path.move(to: point)
            } else {
                path.addLine(to: point)
            }
        }
        
        return path
    }
    
    /// 创建波浪形路径
    /// - Parameters:
    ///   - rect: 矩形区域
    ///   - amplitude: 振幅
    ///   - frequency: 频率（每单位长度的波数）
    ///   - phase: 相位偏移
    /// - Returns: 波浪形路径
    public static func createWavePath(
        rect: CGRect,
        amplitude: CGFloat,
        frequency: CGFloat,
        phase: CGFloat = 0
    ) -> CGPath {
        let path = CGMutablePath()
        let steps = Int(rect.width * 2) // 确保足够的精度
        
        for i in 0...steps {
            let x = rect.origin.x + CGFloat(i) / CGFloat(steps) * rect.width
            let y = rect.origin.y + rect.height / 2 + amplitude * sin(frequency * x + phase)
            
            if i == 0 {
                path.move(to: CGPoint(x: x, y: y))
            } else {
                path.addLine(to: CGPoint(x: x, y: y))
            }
        }
        
        return path
    }
    
    /// 创建心形路径
    /// - Parameters:
    ///   - center: 中心点
    ///   - size: 大小
    /// - Returns: 心形路径
    public static func createHeartPath(center: CGPoint, size: CGFloat) -> CGPath {
        let path = CGMutablePath()
        let scale = size / 4
        
        // 心形的参数方程
        let steps = 100
        for i in 0...steps {
            let t = CGFloat(i) / CGFloat(steps) * CGFloat.pi * 2
            let x = center.x + scale * (16 * sin(t) * sin(t) * sin(t))
            let y = center.y - scale * (13 * cos(t) - 5 * cos(2 * t) - 2 * cos(3 * t) - cos(4 * t))
            
            if i == 0 {
                path.move(to: CGPoint(x: x, y: y))
            } else {
                path.addLine(to: CGPoint(x: x, y: y))
            }
        }
        
        path.closeSubpath()
        return path
    }
    
    // MARK: - 路径操作
    
    /// 缩放路径
    /// - Parameters:
    ///   - path: 原路径
    ///   - scale: 缩放比例
    ///   - anchorPoint: 锚点（默认为路径中心）
    /// - Returns: 缩放后的路径
    public static func scalePath(_ path: CGPath, scale: CGFloat, anchorPoint: CGPoint? = nil) -> CGPath {
        let boundingBox = path.boundingBox
        let center = anchorPoint ?? CGPoint(x: boundingBox.midX, y: boundingBox.midY)
        
        var transform = CGAffineTransform.identity
        transform = transform.translatedBy(x: center.x, y: center.y)
        transform = transform.scaledBy(x: scale, y: scale)
        transform = transform.translatedBy(x: -center.x, y: -center.y)
        
        return path.copy(using: &transform) ?? path
    }
    
    /// 旋转路径
    /// - Parameters:
    ///   - path: 原路径
    ///   - angle: 旋转角度（弧度）
    ///   - anchorPoint: 锚点（默认为路径中心）
    /// - Returns: 旋转后的路径
    public static func rotatePath(_ path: CGPath, angle: CGFloat, anchorPoint: CGPoint? = nil) -> CGPath {
        let boundingBox = path.boundingBox
        let center = anchorPoint ?? CGPoint(x: boundingBox.midX, y: boundingBox.midY)
        
        var transform = CGAffineTransform.identity
        transform = transform.translatedBy(x: center.x, y: center.y)
        transform = transform.rotated(by: angle)
        transform = transform.translatedBy(x: -center.x, y: -center.y)
        
        return path.copy(using: &transform) ?? path
    }
    
    /// 平移路径
    /// - Parameters:
    ///   - path: 原路径
    ///   - offset: 偏移量
    /// - Returns: 平移后的路径
    public static func translatePath(_ path: CGPath, offset: CGSize) -> CGPath {
        var transform = CGAffineTransform(translationX: offset.width, y: offset.height)
        return path.copy(using: &transform) ?? path
    }
    
    /// 偏移路径（创建轮廓）
    /// - Parameters:
    ///   - path: 原路径
    ///   - offset: 偏移距离
    /// - Returns: 偏移后的路径
    public static func offsetPath(_ path: CGPath, offset: CGFloat) -> CGPath {
        // 近似为围绕中心的等比例扩大，使边界增大约 2*offset
        let bounds = path.boundingBox
        let sx = (bounds.width + 2 * offset) / max(bounds.width, 1)
        let sy = (bounds.height + 2 * offset) / max(bounds.height, 1)
        let center = CGPoint(x: bounds.midX, y: bounds.midY)
        var transform = CGAffineTransform.identity
        transform = transform.translatedBy(x: center.x, y: center.y)
        transform = transform.scaledBy(x: sx, y: sy)
        transform = transform.translatedBy(x: -center.x, y: -center.y)
        return path.copy(using: &transform) ?? path
    }
    
    // MARK: - 路径分析
    
    /// 计算路径长度
    /// - Parameter path: 路径
    /// - Returns: 路径长度
    public static func calculatePathLength(_ path: CGPath) -> CGFloat {
        var length: CGFloat = 0
        var previousPoint: CGPoint?
        
        func quadPoint(_ t: CGFloat, _ p0: CGPoint, _ c: CGPoint, _ p1: CGPoint) -> CGPoint {
            let mt = 1 - t
            let x = mt*mt*p0.x + 2*mt*t*c.x + t*t*p1.x
            let y = mt*mt*p0.y + 2*mt*t*c.y + t*t*p1.y
            return CGPoint(x: x, y: y)
        }
        func cubicPoint(_ t: CGFloat, _ p0: CGPoint, _ c1: CGPoint, _ c2: CGPoint, _ p1: CGPoint) -> CGPoint {
            let mt = 1 - t
            let x = mt*mt*mt*p0.x + 3*mt*mt*t*c1.x + 3*mt*t*t*c2.x + t*t*t*p1.x
            let y = mt*mt*mt*p0.y + 3*mt*mt*t*c1.y + 3*mt*t*t*c2.y + t*t*t*p1.y
            return CGPoint(x: x, y: y)
        }
        
        path.applyWithBlock { element in
            switch element.pointee.type {
            case .moveToPoint:
                let p0 = element.pointee.points.pointee
                previousPoint = p0
            case .addLineToPoint:
                if let p0 = previousPoint {
                    let p1 = element.pointee.points.pointee
                    length += hypot(p1.x - p0.x, p1.y - p0.y)
                    previousPoint = p1
                }
            case .addQuadCurveToPoint:
                if let p0 = previousPoint {
                    let pts = element.pointee.points
                    let c = pts[0]
                    let p1 = pts[1]
                    var last = p0
                    let steps = 32
                    for i in 1...steps {
                        let t = CGFloat(i)/CGFloat(steps)
                        let pt = quadPoint(t, p0, c, p1)
                        length += hypot(pt.x - last.x, pt.y - last.y)
                        last = pt
                    }
                    previousPoint = p1
                }
            case .addCurveToPoint:
                if let p0 = previousPoint {
                    let pts = element.pointee.points
                    let c1 = pts[0]
                    let c2 = pts[1]
                    let p1 = pts[2]
                    var last = p0
                    let steps = 32
                    for i in 1...steps {
                        let t = CGFloat(i)/CGFloat(steps)
                        let pt = cubicPoint(t, p0, c1, c2, p1)
                        length += hypot(pt.x - last.x, pt.y - last.y)
                        last = pt
                    }
                    previousPoint = p1
                }
            case .closeSubpath:
                break
            @unknown default:
                break
            }
        }
        
        return length
    }
    
    /// 获取路径上的点
    /// - Parameters:
    ///   - path: 路径
    ///   - distance: 距离起点的距离
    /// - Returns: 路径上的点
    public static func getPointOnPath(_ path: CGPath, distance: CGFloat) -> CGPoint? {
        var currentDistance: CGFloat = 0
        var previousPoint: CGPoint?
        var resultPoint: CGPoint?
        
        path.applyWithBlock { element in
            if resultPoint != nil { return }
            
            switch element.pointee.type {
            case .moveToPoint:
                let point = element.pointee.points.pointee
                previousPoint = point
            case .addLineToPoint:
                if let prev = previousPoint {
                    let point = element.pointee.points.pointee
                    let segmentLength = hypot(point.x - prev.x, point.y - prev.y)
                    if currentDistance + segmentLength >= distance {
                        let t = (distance - currentDistance) / segmentLength
                        resultPoint = CGPoint(
                            x: prev.x + (point.x - prev.x) * t,
                            y: prev.y + (point.y - prev.y) * t
                        )
                        return
                    }
                    currentDistance += segmentLength
                    previousPoint = point
                }
            case .addQuadCurveToPoint, .addCurveToPoint:
                // 简化实现，实际应该使用曲线参数方程
                let points = element.pointee.points
                let endPoint = points[element.pointee.type == .addQuadCurveToPoint ? 1 : 2]
                if let prev = previousPoint {
                    let segmentLength = hypot(endPoint.x - prev.x, endPoint.y - prev.y)
                    if currentDistance + segmentLength >= distance {
                        let t = (distance - currentDistance) / segmentLength
                        resultPoint = CGPoint(
                            x: prev.x + (endPoint.x - prev.x) * t,
                            y: prev.y + (endPoint.y - prev.y) * t
                        )
                        return
                    }
                    currentDistance += segmentLength
                    previousPoint = endPoint
                }
            case .closeSubpath:
                break
            @unknown default:
                break
            }
        }
        
        return resultPoint
    }
    
    // MARK: - 实用工具
    
    /// 创建文本环绕路径
    /// - Parameters:
    ///   - rect: 矩形区域
    ///   - imageRect: 图片矩形（要环绕的区域）
    ///   - margin: 边距
    /// - Returns: 文本可以布局的路径
    public static func createTextWrapPath(rect: CGRect, imageRect: CGRect, margin: CGFloat = 0) -> CGPath {
        let path = CGMutablePath()
        let expandedImageRect = imageRect.insetBy(dx: -margin, dy: -margin)
        
        // 创建环绕路径，这里简化实现
        if expandedImageRect.minX > rect.minX {
            // 左侧区域
            path.addRect(CGRect(x: rect.minX, y: rect.minY, width: expandedImageRect.minX - rect.minX, height: rect.height))
        }
        
        if expandedImageRect.maxX < rect.maxX {
            // 右侧区域
            path.addRect(CGRect(x: expandedImageRect.maxX, y: rect.minY, width: rect.maxX - expandedImageRect.maxX, height: rect.height))
        }
        
        if expandedImageRect.minY > rect.minY {
            // 上侧区域
            path.addRect(CGRect(x: rect.minX, y: rect.minY, width: rect.width, height: expandedImageRect.minY - rect.minY))
        }
        
        if expandedImageRect.maxY < rect.maxY {
            // 下侧区域
            path.addRect(CGRect(x: rect.minX, y: expandedImageRect.maxY, width: rect.width, height: rect.maxY - expandedImageRect.maxY))
        }
        
        return path
    }
    
    /// 创建排除路径
    /// - Parameters:
    ///   - rect: 要排除的矩形
    ///   - cornerRadius: 圆角半径
    /// - Returns: 排除路径
    public static func createExclusionPath(rect: CGRect, cornerRadius: CGFloat = 0) -> CGPath {
        if cornerRadius > 0 {
            return createRoundedRectPath(rect, cornerRadius: cornerRadius)
        } else {
            let path = CGMutablePath()
            path.addRect(rect)
            return path
        }
    }
    
    /// 记录路径信息（用于调试）
    /// - Parameter path: 路径
    public static func logPathInfo(_ path: CGPath) {
        let bounds = path.boundingBox
        let length = calculatePathLength(path)
        
        TETextEngine.shared.logDebug("路径信息: bounds=\(bounds), length=\(length)", category: "path")
        
        var elementCount = 0
        path.applyWithBlock { _ in
            elementCount += 1
        }
        
        TETextEngine.shared.logDebug("路径元素数量: \(elementCount)", category: "path")
    }

    /// 合成容器与排除路径用于剪裁（偶数-奇数填充）
    public static func combineForClipping(container: CGPath, exclusions: [CGPath]) -> CGPath {
        let path = CGMutablePath()
        path.addPath(container)
        for ex in exclusions { path.addPath(ex) }
        return path
    }
}
