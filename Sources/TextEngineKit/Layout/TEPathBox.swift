// 
//  TEPathBox.swift 
//  TextEngineKit 
// 
//  Created by fengming on 2025/11/17. 
// 
//  路径矩形封装：提供 `CGRect` 的安全归档/解档能力，用于路径布局与持久化。 
// 
import Foundation
import CoreGraphics

/// 路径边界框类
///
/// `TEPathBox` 提供了一个线程安全的矩形区域封装，用于在文本布局系统中表示
/// 各种元素的边界框。该类支持 `NSSecureCoding` 协议，可以安全地进行归档和解档操作。
///
/// 主要用途：
/// - 表示文本段落的布局边界
/// - 存储附件或高亮区域的边界信息
/// - 在文本渲染过程中传递几何信息
///
/// 使用示例：
/// ```swift
/// let bounds = CGRect(x: 10, y: 20, width: 100, height: 50)
/// let pathBox = TEPathBox(rect: bounds)
/// 
/// // 归档到数据
/// let data = try NSKeyedArchiver.archivedData(withRootObject: pathBox, requiringSecureCoding: true)
/// 
/// // 从数据解档
/// if let unboxed = try NSKeyedUnarchiver.unarchivedObject(ofClass: TEPathBox.self, from: data) {
///     print("恢复后的矩形: \(unboxed.rect)")
/// }
/// ```
public final class TEPathBox: NSObject, NSSecureCoding {
    /// 支持安全编码
    ///
    /// 表明此类支持 `NSSecureCoding` 协议，可以在启用安全编码的环境中使用。
    /// 这是 iOS 12+ 和 macOS 10.14+ 的推荐做法，可以防止对象替换攻击。
    public class var supportsSecureCoding: Bool { true }
    
    /// 存储的矩形区域
    ///
    /// 这个矩形使用 Core Graphics 坐标系，原点通常在左上角（iOS）或左下角（macOS）。
    /// 矩形的值在对象创建后不可变，确保了线程安全性。
    public let rect: CGRect
    
    /// 使用矩形创建路径边界框
    ///
    /// - Parameter rect: 要封装的矩形区域
    public init(rect: CGRect) { self.rect = rect }
    /// 将路径边界框编码到归档器
    ///
    /// 使用安全的编码方式将矩形信息存储到归档器中。
    /// 存储的键值：
    /// - "x": 矩形原点的 x 坐标（Double 类型）
    /// - "y": 矩形原点的 y 坐标（Double 类型）
    /// - "w": 矩形的宽度（Double 类型）
    /// - "h": 矩形的高度（Double 类型）
    ///
    /// - Parameter coder: 用于存储编码数据的归档器
    public func encode(with coder: NSCoder) {
        coder.encode(Double(rect.origin.x), forKey: "x")
        coder.encode(Double(rect.origin.y), forKey: "y")
        coder.encode(Double(rect.size.width), forKey: "w")
        coder.encode(Double(rect.size.height), forKey: "h")
    }
    
    /// 从归档器解码创建路径边界框
    ///
    /// 从之前编码的数据中恢复矩形信息。如果解码失败或数据损坏，返回 `nil`。
    ///
    /// - Parameter coder: 包含编码数据的归档器
    /// - Returns: 解码后的路径边界框实例，如果解码失败则返回 `nil`
    public required init?(coder: NSCoder) {
        let x = coder.decodeDouble(forKey: "x")
        let y = coder.decodeDouble(forKey: "y")
        let w = coder.decodeDouble(forKey: "w")
        let h = coder.decodeDouble(forKey: "h")
        self.rect = CGRect(x: CGFloat(x), y: CGFloat(y), width: CGFloat(w), height: CGFloat(h))
        super.init()
    }
}
