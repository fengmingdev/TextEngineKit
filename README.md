# TextEngineKit

一个高性能、企业级的 iOS 富文本渲染框架，基于 YYText 重构，支持 Swift 5.5+ 和 iOS 13+

## 特性

🚀 **高性能** - 异步文本布局和渲染，优化的内存管理
🧵 **线程安全** - 完全线程安全的实现，可在多线程环境中安全使用
🎨 **富文本支持** - 支持扩展的 CoreText 属性和自定义文本效果
📱 **多平台支持** - 支持 iOS、macOS、tvOS、watchOS
🔧 **易于集成** - Swift Package Manager 支持，一行代码集成
📊 **企业级** - 内置性能监控、内存优化和错误处理
🛡️ **安全日志** - 集成 FMLogger，提供完整的日志和调试支持

### MPITextKit 兼容特性

🎯 **文本选择管理器** - 完整的文本选择管理器，支持范围选择、复制和编辑菜单
- 支持 `TETextSelectionRange` 选择范围管理
- 提供 `TETextSelectionManagerDelegate` 委托回调
- 集成编辑菜单和复制功能
- 支持选择状态管理和事件处理

🔄 **排除路径系统** - 灵活的文本排除路径系统，支持复杂几何形状和内外排除模式
- 支持 `UIBezierPath` 任意路径形状
- 提供内外两种排除模式（`inside`/`outside`）
- 内置矩形、圆形、椭圆等常用形状工厂方法
- 支持可配置的内边距和边界检测

🔍 **调试可视化工具** - 强大的调试工具，可视化显示基线、行片段、字形边界等
- 实时显示文本基线、行片段边界
- 支持字形边界显示（字符级调试）
- 可视化排除路径和选择范围
- 显示文本附件和高亮区域
- 提供详细的调试信息数据结构

📈 **性能分析器** - 详细的性能分析器，监控布局、渲染和内存使用指标
- 实时性能指标收集（布局时间、渲染时间、内存使用）
- 自动性能瓶颈检测和警告
- 支持性能历史记录和趋势分析
- 生成详细的性能报告
- 提供性能优化建议

## 系统要求

- iOS 13.0+ / macOS 10.15+ / tvOS 13.0+ / watchOS 6.0+
- Swift 5.5+
- Xcode 13.0+

## 安装

### Swift Package Manager

在 `Package.swift` 中添加：

```swift
dependencies: [
    .package(url: "https://github.com/yourusername/TextEngineKit.git", from: "1.0.0")
]
```

或者在 Xcode 中添加：

1. 打开 Xcode 项目
2. 选择 File → Add Package Dependencies
3. 输入 URL: `https://github.com/yourusername/TextEngineKit.git`
4. 点击 Add Package

## 快速开始

### 基础使用

```swift
import TextEngineKit

// 创建富文本标签
let label = TELabel()
label.text = "Hello, TextEngineKit!"
label.font = .systemFont(ofSize: 16)
label.textColor = .label
label.frame = CGRect(x: 20, y: 100, width: 200, height: 30)
view.addSubview(label)

// 创建富文本视图
let textView = TETextView()
textView.attributedText = NSAttributedString(string: "富文本内容")
textView.frame = CGRect(x: 20, y: 150, width: 300, height: 200)
view.addSubview(textView)
```

### 富文本属性

```swift
import TextEngineKit

// 创建带属性的文本
let text = NSMutableAttributedString(string: "TextEngineKit 富文本")
text.setAttribute(.font, value: UIFont.boldSystemFont(ofSize: 24), range: NSRange(location: 0, length: 12))
text.setAttribute(.foregroundColor, value: UIColor.systemBlue, range: NSRange(location: 0, length: 12))

// 设置文本阴影
let shadow = TETextShadow()
shadow.color = UIColor.black.withAlphaComponent(0.3)
shadow.offset = CGSize(width: 1, height: 1)
shadow.radius = 2
text.setAttribute(.textShadow, value: shadow, range: NSRange(location: 0, length: text.length))

// 设置文本边框
let border = TETextBorder()
border.color = UIColor.systemRed
border.width = 2
border.cornerRadius = 4
text.setAttribute(.textBorder, value: border, range: NSRange(location: 0, length: text.length))

label.attributedText = text
```

### 文本附件

```swift
// 添加图片附件
let attachment = TETextAttachment()
attachment.content = UIImage(systemName: "heart.fill")
attachment.size = CGSize(width: 20, height: 20)

let attachmentString = NSAttributedString(attachment: attachment)
text.append(attachmentString)
```

### 文本高亮

```swift
// 设置文本高亮
let highlight = TETextHighlight()
highlight.color = UIColor.systemYellow
highlight.backgroundColor = UIColor.systemBlue
highlight.tapAction = { containerView, text, range, rect in
    print("点击了高亮文本")
}

text.setTextHighlight(highlight, range: NSRange(location: 0, length: 12))
```

### 异步渲染

```swift
// 使用 TEAsyncLayer 进行高性能异步渲染
class CustomDrawingView: UIView {
    private let asyncLayer = TEAsyncLayer()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        layer.addSublayer(asyncLayer)
        asyncLayer.asyncDelegate = self
        asyncLayer.isAsyncEnabled = true // 启用异步渲染
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        layer.addSublayer(asyncLayer)
        asyncLayer.asyncDelegate = self
        asyncLayer.isAsyncEnabled = true
    }
}

extension CustomDrawingView: TEAsyncLayerDelegate {
    func draw(in context: CGContext, size: CGSize) {
        // 在后台线程执行复杂的绘制操作
        let path = UIBezierPath(ovalIn: CGRect(origin: .zero, size: size))
        context.setFillColor(UIColor.systemBlue.cgColor)
        context.addPath(path.cgPath)
        context.fillPath()
    }
}
```

### 文本引擎核心 API

```swift
// 使用文本引擎进行完整的文本处理流程
let engine = TETextEngine()

do {
    // 启动引擎
    try engine.start()
    
    // 配置处理选项
    let options = TEProcessingOptions(
        enableAsync: true,
        maxConcurrency: 4,
        cacheResult: true,
        timeout: 30.0
    )
    
    // 处理原始文本
    let processResult = engine.processText("# Hello World\n\nThis is **bold** text.", options: options)
    
    switch processResult {
    case .success(let attributedString):
        print("处理成功，结果长度: \(attributedString.length)")
        
        // 布局文本
        let containerSize = CGSize(width: 300, height: 200)
        let layoutResult = engine.layoutText(attributedString, containerSize: containerSize)
        
        switch layoutResult {
        case .success(let textLayout):
            print("布局成功，行数: \(textLayout.layoutManager.lineCount)")
            
            // 渲染到图形上下文
            UIGraphicsBeginImageContextWithOptions(containerSize, false, 0)
            if let context = UIGraphicsGetCurrentContext() {
                let renderResult = engine.renderText(textLayout, in: context)
                if case .success = renderResult {
                    print("渲染成功")
                }
            }
            UIGraphicsEndImageContext()
            
        case .failure(let error):
            print("布局失败: \(error)")
        }
        
    case .failure(let error):
        print("处理失败: \(error)")
    }
    
} catch {
    print("引擎启动失败: \(error)")
}

// 停止引擎
engine.stop()
```

### 文本选择管理

```swift
// 创建文本选择管理器
let selectionManager = TETextSelectionManager()
selectionManager.setupContainerView(myTextView)

// 启用文本选择
selectionManager.isSelectionEnabled = true
selectionManager.selectionColor = .systemBlue

// 监听选择变化
selectionManager.delegate = self

// 扩展 UIViewController 以支持 TETextSelectionManagerDelegate
extension ViewController: TETextSelectionManagerDelegate {
    func selectionManager(_ manager: TETextSelectionManager, didChangeSelection range: TETextSelectionRange?) {
        if let range = range {
            print("选择范围: \(range.location) - \(range.location + range.length)")
        } else {
            print("没有选择")
        }
    }
    
    func selectionManager(_ manager: TETextSelectionManager, shouldChangeSelection range: TETextSelectionRange?) -> Bool {
        // 可以在这里实现自定义的选择逻辑
        return true
    }
}
```

### 排除路径

```swift
// 创建排除路径
let exclusionPath = TEExclusionPath(rect: CGRect(x: 50, y: 50, width: 100, height: 100))

// 创建圆形排除路径
let circlePath = TEExclusionPath.circle(center: CGPoint(x: 150, y: 150), radius: 50)

// 创建椭圆排除路径
let ellipsePath = TEExclusionPath.ellipse(in: CGRect(x: 200, y: 200, width: 150, height: 80))

// 创建自定义路径
let customPath = UIBezierPath()
customPath.move(to: CGPoint(x: 0, y: 0))
customPath.addLine(to: CGPoint(x: 100, y: 0))
customPath.addLine(to: CGPoint(x: 50, y: 100))
customPath.closePath()
let customExclusionPath = TEExclusionPath(path: customPath, type: .inside)

// 应用排除路径到文本布局
let layout = TETextLayout()
layout.exclusionPaths = [exclusionPath, circlePath, ellipsePath]
```

### 调试可视化

```swift
// 启用调试模式
TETextDebugger.shared.enableDebugging()

// 配置调试选项
var debugOptions = TETextDebugOptions()
debugOptions.showBaselines = true
debugOptions.baselineColor = .red
debugOptions.showLineFragments = true
debugOptions.showExclusionPaths = true
debugOptions.exclusionPathColor = .purple
debugOptions.showSelection = true
debugOptions.selectionColor = .systemYellow

// 应用调试选项
TETextDebugger.shared.updateOptions(debugOptions)

// 调试特定视图
TETextDebugger.shared.debugLabel(myLabel)
TETextDebugger.shared.debugTextView(myTextView)

// 获取调试信息
let debugInfo = TETextDebugger.shared.getDebugInfo(for: myTextView)
print("布局信息: \(debugInfo.layoutInfo)")
print("性能信息: \(debugInfo.performanceInfo)")
print("排除路径信息: \(debugInfo.exclusionPathInfo)")
```

### 性能分析

```swift
// 启用性能分析
TEPerformanceProfiler.shared.startProfiling()

// 配置分析选项
var profilingOptions = TEProfilingOptions()
profilingOptions.enableLayoutProfiling = true
profilingOptions.enableRenderProfiling = true
profilingOptions.enableMemoryProfiling = true
profilingOptions.reportingInterval = 1.0 // 每秒报告一次

// 应用分析选项
TEPerformanceProfiler.shared.updateOptions(profilingOptions)

// 分析文本布局性能
let layoutMetrics = TEPerformanceProfiler.shared.profileLayout(attributedString, containerSize: CGSize(width: 300, height: 200))
print("布局时间: \(layoutMetrics.layoutTime) 秒")
print("行数: \(layoutMetrics.lineCount)")
print("字符数: \(layoutMetrics.characterCount)")
print("缓存命中: \(layoutMetrics.cacheHit)")

// 分析文本渲染性能
let renderMetrics = TEPerformanceProfiler.shared.profileRender(textLayout, in: graphicsContext)
print("渲染时间: \(renderMetrics.renderTime) 秒")
print("像素数: \(renderMetrics.pixelCount)")
print("绘制调用: \(renderMetrics.drawCallCount)")

// 获取整体性能报告
let performanceReport = TEPerformanceProfiler.shared.generateReport()
print("平均布局时间: \(performanceReport.averageLayoutTime)")
print("平均渲染时间: \(performanceReport.averageRenderTime)")
print("总内存使用: \(performanceReport.totalMemoryUsage)")
print("平均FPS: \(performanceReport.averageFPS)")
```

## 架构设计

TextEngineKit 采用模块化架构设计，包含以下核心模块：

### Core Module
- `TETextRenderer` - 核心文本渲染引擎
- `TELayoutManager` - 异步文本布局管理器
- `TEAttributeSystem` - 富文本属性系统
- `TEAttachmentManager` - 文本附件管理器

### UI Components
- `TELabel` - 高性能富文本标签
- `TETextView` - 功能丰富的富文本视图
- `TETextField` - 支持富文本的输入框

### Utilities
- `TEParser` - 文本解析器（支持 Markdown）
- `TEHighlightManager` - 文本高亮管理器
- `TEClipboardManager` - 剪贴板管理器
- `TEPerformanceMonitor` - 性能监控器
- `TETextSelectionManager` - 文本选择管理器
- `TEExclusionPath` - 排除路径系统
- `TETextDebugger` - 调试可视化工具
- `TEPerformanceProfiler` - 性能分析器

## 性能优化

TextEngineKit 在性能方面进行了多项优化：

1. **异步布局** - 使用后台线程进行文本布局计算
2. **缓存机制** - 智能缓存文本布局结果
3. **内存管理** - 优化的内存分配和释放策略
4. **渲染优化** - 使用 CoreText 和 CoreGraphics 进行高效渲染
5. **线程安全** - 完全线程安全的实现

## 日志系统

TextEngineKit 集成了 FMLogger 日志系统，提供完整的调试和监控支持：

```swift
import TextEngineKit

// 配置日志级别
TETextEngine.shared.configureLogging(.development)

// 查看渲染性能日志
TETextEngine.shared.enablePerformanceLogging = true
```

## API 参考

### 核心协议

#### TETextEngineProtocol
文本引擎核心协议，定义了文本处理、布局和渲染的完整生命周期管理。

```swift
public protocol TETextEngineProtocol {
    var configuration: TEConfiguration { get set }
    var isRunning: Bool { get }
    
    func start() throws
    func stop()
    func reset()
    func performHealthCheck() -> Result<Bool, TETextEngineError>
    
    func processText(_ text: String, options: TEProcessingOptions?) -> Result<NSAttributedString, TETextEngineError>
    func layoutText(_ attributedString: NSAttributedString, containerSize: CGSize) -> Result<TETextLayout, TETextEngineError>
    func renderText(_ layout: TETextLayout, in context: CGContext) -> Result<Void, TETextEngineError>
}
```

#### TEAsyncLayerDelegate
异步图层绘制委托协议。

```swift
public protocol TEAsyncLayerDelegate: AnyObject {
    func draw(in context: CGContext, size: CGSize)
}
```

### 核心类

#### TETextEngine
文本引擎主类，实现 `TETextEngineProtocol`。

```swift
let engine = TETextEngine()
try engine.start()
// 使用引擎...
engine.stop()
```

#### TELabel
高性能富文本标签。

```swift
let label = TELabel()
label.text = "Hello World"
label.font = .systemFont(ofSize: 16)
label.textColor = .label
```

#### TETextView
功能丰富的富文本视图。

```swift
let textView = TETextView()
textView.attributedText = NSAttributedString(string: "富文本内容")
```

#### TEAsyncLayer
高性能异步渲染图层。

```swift
let asyncLayer = TEAsyncLayer()
asyncLayer.asyncDelegate = self
asyncLayer.isAsyncEnabled = true
```

### 核心结构体

#### TEProcessingOptions
文本处理选项。

```swift
public struct TEProcessingOptions {
    public var enableAsync: Bool      // 是否启用异步处理
    public var maxConcurrency: Int    // 最大并发数
    public var cacheResult: Bool      // 是否缓存结果
    public var timeout: TimeInterval  // 超时时间（秒）
}
```

#### TETextLayout
文本布局信息。

```swift
public struct TETextLayout {
    public let attributedString: NSAttributedString
    public let containerSize: CGSize
    public let textContainer: TETextContainer
    public let layoutManager: TELayoutManager
    public let textStorage: Any?
}
```

#### TEPathBox
路径边界框，支持安全编码。

```swift
public final class TEPathBox: NSObject, NSSecureCoding {
    public let rect: CGRect
    public init(rect: CGRect)
}
```

### 扩展属性

TextEngineKit 扩展了 `NSAttributedString` 支持以下属性：

- `.textShadow` - 文本阴影
- `.textBorder` - 文本边框
- `.textBackground` - 文本背景
- `.textAttachment` - 文本附件
- `.textHighlight` - 文本高亮

### 新功能 API

#### TETextSelectionManager
文本选择管理器，提供完整的文本选择功能，支持范围选择、复制和编辑菜单。

```swift
public final class TETextSelectionManager {
    public weak var delegate: TETextSelectionManagerDelegate?
    public var selectedRange: TETextSelectionRange? { get }
    public var isSelectionEnabled: Bool
    public var selectionColor: UIColor
    
    public func setupContainerView(_ containerView: UIView)
    public func setSelection(range: TETextSelectionRange?)
    public func selectAll()
    public func clearSelection()
    public func copySelectedText() -> String?
    public func showEditMenu()
}

// 使用示例
let selectionManager = TETextSelectionManager()
selectionManager.delegate = self
selectionManager.isSelectionEnabled = true
selectionManager.selectionColor = .systemBlue

// 设置选择范围
let range = TETextSelectionRange(location: 10, length: 20)
selectionManager.setSelection(range: range)

// 全选
selectionManager.selectAll()

// 复制选中文本
if let selectedText = selectionManager.copySelectedText() {
    UIPasteboard.general.string = selectedText
}
```

#### TEExclusionPath
排除路径系统，支持复杂几何形状的文本布局避让，提供灵活的内外排除模式。

```swift
public struct TEExclusionPath {
    public enum ExclusionType {
        case inside  // 排除路径内部区域，文本围绕路径外部排列
        case outside // 排除路径外部区域，文本仅在路径内部排列
    }
    
    public let path: UIBezierPath
    public let padding: UIEdgeInsets
    public let type: ExclusionType
    
    public init(path: UIBezierPath, padding: UIEdgeInsets = .zero, type: ExclusionType = .inside)
    public static func rect(_ rect: CGRect, padding: UIEdgeInsets = .zero, type: ExclusionType = .inside) -> TEExclusionPath
    public static func circle(center: CGPoint, radius: CGFloat, padding: UIEdgeInsets = .zero, type: ExclusionType = .inside) -> TEExclusionPath
    public static func ellipse(in rect: CGRect, padding: UIEdgeInsets = .zero, type: ExclusionType = .inside) -> TEExclusionPath
    
    public func contains(_ point: CGPoint) -> Bool
    public var paddedBounds: CGRect { get }
}

// 使用示例
// 创建圆形排除路径（文本围绕圆形排列）
let circlePath = TEExclusionPath.circle(
    center: CGPoint(x: 150, y: 150), 
    radius: 50, 
    padding: UIEdgeInsets(top: 10, left: 10, bottom: 10, right: 10)
)

// 创建矩形排除路径
textContainer.exclusionPaths = [
    TEExclusionPath.rect(CGRect(x: 50, y: 50, width: 100, height: 100)),
    TEExclusionPath.ellipse(in: CGRect(x: 200, y: 100, width: 80, height: 60))
]

// 检查点是否在排除区域内
let point = CGPoint(x: 100, y: 100)
if circlePath.contains(point) {
    print("点在排除区域内")
}
```

#### TETextDebugger
调试可视化工具，提供文本布局的详细调试信息，支持实时显示基线、行片段、字形边界等。

```swift
public final class TETextDebugger {
    public static let shared: TETextDebugger
    public var options: TETextDebugOptions
    public weak var delegate: TETextDebuggerDelegate?
    
    public func enableDebugging()
    public func disableDebugging()
    public func updateOptions(_ options: TETextDebugOptions)
    public func debugLabel(_ label: TELabel)
    public func debugTextView(_ textView: TETextView)
    public func getDebugInfo(for view: UIView) -> TETextDebugInfo
    public func refreshDebugging()
}

public struct TETextDebugOptions {
    public var showBaselines: Bool              // 显示文本基线
    public var baselineColor: UIColor           // 基线颜色（默认红色半透明）
    public var showLineFragments: Bool          // 显示行片段边界
    public var lineFragmentBorderColor: UIColor // 行片段完整边界颜色
    public var lineFragmentUsedBorderColor: UIColor // 行片段使用区域颜色
    public var showGlyphs: Bool                 // 显示字形边界（性能开销较大）
    public var glyphBorderColor: UIColor        // 字形边界颜色
    public var showExclusionPaths: Bool         // 显示排除路径
    public var exclusionPathColor: UIColor      // 排除路径颜色
    public var showSelection: Bool              // 显示选择范围
    public var selectionColor: UIColor          // 选择范围颜色
    public var showAttachments: Bool            // 显示文本附件
    public var attachmentColor: UIColor         // 附件颜色
    public var showHighlights: Bool             // 显示文本高亮
    public var highlightColor: UIColor          // 高亮颜色
    public var lineWidth: CGFloat               // 调试线条宽度
    public var debugFontSize: CGFloat           // 调试文本字体大小
    public var debugTextColor: UIColor          // 调试文本颜色
}

// 使用示例
// 启用调试模式
TETextDebugger.shared.enableDebugging()

// 配置调试选项
var options = TETextDebugOptions()
options.showBaselines = true
options.showLineFragments = true
options.showExclusionPaths = true
options.baselineColor = .red.withAlphaComponent(0.5)
options.lineFragmentBorderColor = .blue.withAlphaComponent(0.3)
TETextDebugger.shared.updateOptions(options)

// 调试标签
let label = TELabel()
label.text = "调试文本示例"
TETextDebugger.shared.debugLabel(label)

// 获取调试信息
let debugInfo = TETextDebugger.shared.getDebugInfo(for: label)
print("布局信息: \(debugInfo.layoutInfo)")
print("性能信息: \(debugInfo.performanceInfo)")
print("排除路径信息: \(debugInfo.exclusionPathInfo)")

// 设置委托接收调试更新
class MyDebuggerDelegate: TETextDebuggerDelegate {
    func debugger(_ debugger: TETextDebugger, didUpdateDebugInfo info: TETextDebugInfo) {
        print("调试信息更新: 布局时间 \(info.performanceInfo.layoutTime)s")
    }
    
    func debugger(_ debugger: TETextDebugger, didChangeDebuggingState isDebugging: Bool) {
        print("调试状态变化: \(isDebugging ? "启用" : "禁用")")
    }
}
```

#### TEPerformanceProfiler
性能分析器，提供详细的性能监控和分析功能，支持布局、渲染和内存使用指标的实时监控。

```swift
public final class TEPerformanceProfiler {
    public static let shared: TEPerformanceProfiler
    public weak var delegate: TEPerformanceProfilerDelegate?
    public var isProfilingEnabled: Bool
    public var thresholds: PerformanceThresholds
    
    public func startProfiling()
    public func stopProfiling()
    public func profileLabel(_ label: TELabel) -> TEPerformanceMetrics
    public func profileTextView(_ textView: TETextView) -> TEPerformanceMetrics
    public func profileTextRendering(attributedText: NSAttributedString, containerSize: CGSize, exclusionPaths: [TEExclusionPath]) -> TEPerformanceMetrics
    public func getPerformanceHistory() -> [TEPerformanceMetrics]
    public func getPerformanceReport() -> String
    public func resetPerformanceData()
}

public struct TEPerformanceMetrics {
    public struct LayoutMetrics {
        public let layoutTime: TimeInterval      // 布局计算耗时（秒）
        public let lineCount: Int                // 文本行数
        public let glyphCount: Int               // 字形数量
        public let characterCount: Int           // 字符数量
        public let cacheHit: Bool                // 是否命中缓存
        public let memoryUsage: Int              // 内存使用量（字节）
    }
    
    public struct RenderMetrics {
        public let renderTime: TimeInterval      // 渲染绘制耗时（秒）
        public let pixelCount: Int               // 处理的像素数量
        public let drawCallCount: Int            // 绘制调用次数
        public let memoryUsage: Int              // 内存使用量（字节）
        public let gpuUsage: Float               // GPU使用率（0.0-1.0）
    }
    
    public struct OverallMetrics {
        public let totalTime: TimeInterval       // 总处理耗时（秒）
        public let fps: Float                    // 帧率（FPS）
        public let cpuUsage: Float               // CPU使用率（0.0-1.0）
        public let memoryUsage: Int              // 内存使用量（字节）
        public let energyUsage: Float            // 能耗使用情况（0.0-1.0）
    }
    
    public let layoutMetrics: LayoutMetrics
    public let renderMetrics: RenderMetrics
    public let overallMetrics: OverallMetrics
    public let timestamp: Date
}

public struct TEPerformanceBottleneck {
    public enum BottleneckType {
        case layoutSlow    // 布局计算缓慢
        case renderSlow    // 渲染绘制缓慢
        case memoryHigh    // 内存使用过高
        case cacheMiss     // 缓存未命中
        case gpuIntensive  // GPU使用密集
        case cpuIntensive  // CPU使用密集
    }
    
    public let type: BottleneckType
    public let severity: Float               // 严重程度（0.0-1.0）
    public let description: String          // 问题描述
    public let suggestion: String           // 优化建议
    public let metrics: TEPerformanceMetrics // 相关性能指标
}

// 使用示例
// 启用性能分析
TEPerformanceProfiler.shared.startProfiling()

// 配置性能阈值
TEPerformanceProfiler.shared.thresholds.maxLayoutTime = 0.010  // 10ms
TEPerformanceProfiler.shared.thresholds.maxMemoryUsage = 5 * 1024 * 1024  // 5MB
TEPerformanceProfiler.shared.thresholds.minFPS = 45.0  // 45 FPS

// 分析标签性能
let label = TELabel()
label.text = "Hello World"
let metrics = TEPerformanceProfiler.shared.profileLabel(label)
print("布局时间: \(metrics.layoutMetrics.layoutTime * 1000)ms")
print("渲染时间: \(metrics.renderMetrics.renderTime * 1000)ms")
print("总时间: \(metrics.overallMetrics.totalTime * 1000)ms")
print("FPS: \(metrics.overallMetrics.fps)")
print("内存使用: \(formatBytes(metrics.overallMetrics.memoryUsage))")

// 分析文本渲染性能
let text = NSAttributedString(string: "Sample text for performance testing")
let size = CGSize(width: 200, height: 100)
let renderMetrics = TEPerformanceProfiler.shared.profileTextRendering(
    attributedText: text,
    containerSize: size
)

// 获取性能报告
let report = TEPerformanceProfiler.shared.getPerformanceReport()
print(report)

// 设置委托接收性能分析结果
class MyPerformanceDelegate: TEPerformanceProfilerDelegate {
    func profiler(_ profiler: TEPerformanceProfiler, didCompleteAnalysis metrics: TEPerformanceMetrics) {
        print("性能分析完成")
        print("布局时间: \(metrics.layoutMetrics.layoutTime * 1000)ms")
        print("渲染时间: \(metrics.renderMetrics.renderTime * 1000)ms")
        print("FPS: \(metrics.overallMetrics.fps)")
    }
    
    func profiler(_ profiler: TEPerformanceProfiler, didDetectBottleneck bottleneck: TEPerformanceBottleneck) {
        print("发现性能瓶颈!")
        print("类型: \(bottleneck.type)")
        print("描述: \(bottleneck.description)")
        print("建议: \(bottleneck.suggestion)")
        print("严重程度: \(bottleneck.severity * 100)%")
    }
}

TEPerformanceProfiler.shared.delegate = MyPerformanceDelegate()

// 便捷扩展使用
let label = TELabel()
label.text = "Hello World"

// 启用性能分析
label.enablePerformanceProfiling()

// 分析当前标签性能
let performanceMetrics = label.profilePerformance()
print("布局时间: \(performanceMetrics.layoutMetrics.layoutTime * 1000)ms")

// 禁用性能分析
label.disablePerformanceProfiling()
```

## 新功能使用示例

### 文本选择管理器完整示例

```swift
import TextEngineKit

class TextSelectionViewController: UIViewController, TETextSelectionManagerDelegate {
    private let label = TELabel()
    private let selectionManager = TETextSelectionManager()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // 配置标签
        label.text = "这是一段可选择的文本内容，支持范围选择、复制和编辑菜单功能。"
        label.frame = CGRect(x: 20, y: 100, width: 300, height: 100)
        label.numberOfLines = 0
        view.addSubview(label)
        
        // 配置选择管理器
        selectionManager.delegate = self
        selectionManager.isSelectionEnabled = true
        selectionManager.selectionColor = .systemBlue.withAlphaComponent(0.3)
        selectionManager.setupContainerView(label)
        
        // 添加选择按钮
        let selectButton = UIButton(type: .system)
        selectButton.setTitle("选择全部", for: .normal)
        selectButton.addTarget(self, action: #selector(selectAllText), for: .touchUpInside)
        selectButton.frame = CGRect(x: 20, y: 220, width: 100, height: 44)
        view.addSubview(selectButton)
        
        let copyButton = UIButton(type: .system)
        copyButton.setTitle("复制选择", for: .normal)
        copyButton.addTarget(self, action: #selector(copySelectedText), for: .touchUpInside)
        copyButton.frame = CGRect(x: 140, y: 220, width: 100, height: 44)
        view.addSubview(copyButton)
    }
    
    @objc private func selectAllText() {
        selectionManager.selectAll()
    }
    
    @objc private func copySelectedText() {
        if let selectedText = selectionManager.copySelectedText() {
            UIPasteboard.general.string = selectedText
            print("已复制: \(selectedText)")
        }
    }
    
    // MARK: - TETextSelectionManagerDelegate
    
    func selectionManager(_ manager: TETextSelectionManager, didChangeSelection range: TETextSelectionRange?) {
        if let range = range {
            print("选择范围变化: \(range.location) - \(range.location + range.length)")
        } else {
            print("选择已清除")
        }
    }
    
    func selectionManager(_ manager: TETextSelectionManager, shouldChangeSelectionFrom oldRange: TETextSelectionRange?, to newRange: TETextSelectionRange?) -> Bool {
        print("允许选择范围从 \(oldRange?.location ?? -1) 变为 \(newRange?.location ?? -1)")
        return true
    }
}
```

### 排除路径高级示例

```swift
import TextEngineKit

class ExclusionPathViewController: UIViewController {
    private let textView = TETextView()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // 创建长文本内容
        let text = """
        这是一段很长的文本内容，用于演示排除路径功能。文本会围绕各种形状的元素进行排列，
        包括圆形、矩形、椭圆等几何形状。排除路径系统支持复杂的文本布局避让，让文本排版更加灵活和美观。
        
        通过设置不同的排除路径类型，可以实现文本围绕图像、自定义视图或其他UI元素的环绕效果。
        这在创建杂志风格的布局、图文混排内容或复杂的文本展示界面时非常有用。
        """
        
        textView.attributedText = NSAttributedString(string: text)
        textView.frame = CGRect(x: 20, y: 100, width: 350, height: 400)
        textView.isEditable = false
        textView.isScrollEnabled = false
        view.addSubview(textView)
        
        // 创建复杂的排除路径
        createComplexExclusionPaths()
        
        // 添加交互按钮
        addExclusionPathControls()
    }
    
    private func createComplexExclusionPaths() {
        // 圆形排除路径（图像占位）
        let circlePath = TEExclusionPath.circle(
            center: CGPoint(x: 100, y: 150),
            radius: 40,
            padding: UIEdgeInsets(top: 10, left: 10, bottom: 10, right: 10),
            type: .inside
        )
        
        // 矩形排除路径（自定义视图占位）
        let rectPath = TEExclusionPath.rect(
            CGRect(x: 250, y: 200, width: 80, height: 60),
            padding: UIEdgeInsets(top: 5, left: 5, bottom: 5, right: 5),
            type: .inside
        )
        
        // 椭圆排除路径
        let ellipsePath = TEExclusionPath.ellipse(
            in: CGRect(x: 50, y: 300, width: 120, height: 80),
            padding: UIEdgeInsets(top: 8, left: 8, bottom: 8, right: 8),
            type: .inside
        )
        
        // 应用排除路径到文本容器
        textView.textContainer.exclusionPaths = [circlePath, rectPath, ellipsePath]
        
        // 添加视觉占位符
        addPlaceholderViews()
    }
    
    private func addPlaceholderViews() {
        // 圆形占位符
        let circleView = UIView(frame: CGRect(x: 60, y: 110, width: 80, height: 80))
        circleView.backgroundColor = .systemBlue.withAlphaComponent(0.3)
        circleView.layer.cornerRadius = 40
        view.addSubview(circleView)
        
        // 矩形占位符
        let rectView = UIView(frame: CGRect(x: 245, y: 205, width: 90, height: 70))
        rectView.backgroundColor = .systemGreen.withAlphaComponent(0.3)
        rectView.layer.cornerRadius = 8
        view.addSubview(rectView)
        
        // 椭圆占位符
        let ellipseView = UIView(frame: CGRect(x: 45, y: 305, width: 130, height: 90))
        ellipseView.backgroundColor = .systemOrange.withAlphaComponent(0.3)
        ellipseView.layer.cornerRadius = 45
        view.addSubview(ellipseView)
    }
    
    private func addExclusionPathControls() {
        let addButton = UIButton(type: .system)
        addButton.setTitle("添加随机排除路径", for: .normal)
        addButton.addTarget(self, action: #selector(addRandomExclusionPath), for: .touchUpInside)
        addButton.frame = CGRect(x: 20, y: 520, width: 200, height: 44)
        view.addSubview(addButton)
        
        let clearButton = UIButton(type: .system)
        clearButton.setTitle("清除所有排除路径", for: .normal)
        clearButton.addTarget(self, action: #selector(clearExclusionPaths), for: .touchUpInside)
        clearButton.frame = CGRect(x: 240, y: 520, width: 150, height: 44)
        view.addSubview(clearButton)
    }
    
    @objc private func addRandomExclusionPath() {
        let randomX = CGFloat.random(in: 50...300)
        let randomY = CGFloat.random(in: 150...400)
        let randomWidth = CGFloat.random(in: 40...100)
        let randomHeight = CGFloat.random(in: 40...100)
        
        let randomPath = TEExclusionPath.rect(
            CGRect(x: randomX, y: randomY, width: randomWidth, height: randomHeight),
            padding: UIEdgeInsets(top: 5, left: 5, bottom: 5, right: 5)
        )
        
        var currentPaths = textView.textContainer.exclusionPaths
        currentPaths.append(randomPath)
        textView.textContainer.exclusionPaths = currentPaths
        
        // 添加视觉反馈
        let placeholder = UIView(frame: CGRect(x: randomX, y: randomY, width: randomWidth, height: randomHeight))
        placeholder.backgroundColor = .systemPurple.withAlphaComponent(0.3)
        placeholder.layer.cornerRadius = 8
        placeholder.tag = 999
        view.addSubview(placeholder)
    }
    
    @objc private func clearExclusionPaths() {
        textView.textContainer.exclusionPaths = []
        
        // 清除所有占位符视图
        view.subviews.filter { $0.tag == 999 }.forEach { $0.removeFromSuperview() }
    }
}
```

### 调试可视化完整示例

```swift
import TextEngineKit

class DebugVisualizationViewController: UIViewController, TETextDebuggerDelegate {
    private let label = TELabel()
    private let textView = TETextView()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        setupUI()
        setupDebugger()
        addDebugControls()
    }
    
    private func setupUI() {
        // 配置标签
        label.text = "调试可视化标签 - 可以显示基线、行片段、字形边界等调试信息"
        label.frame = CGRect(x: 20, y: 100, width: 350, height: 60)
        label.numberOfLines = 0
        label.font = .systemFont(ofSize: 16)
        view.addSubview(label)
        
        // 配置文本视图
        let textViewText = """
        调试可视化文本视图 - 支持更复杂的调试信息显示。
        
        可以显示：
        • 文本基线（红色线条）
        • 行片段边界（完整矩形和使用矩形）
        • 字形边界（橙色矩形，性能开销较大）
        • 排除路径（紫色形状）
        • 选择范围（黄色高亮）
        • 文本附件（绿色边界）
        • 文本高亮（粉色背景）
        
        调试信息有助于理解文本布局算法的工作原理。
        """
        
        textView.attributedText = NSAttributedString(string: textViewText)
        textView.frame = CGRect(x: 20, y: 180, width: 350, height: 250)
        textView.isEditable = false
        textView.isScrollEnabled = false
        textView.font = .systemFont(ofSize: 14)
        view.addSubview(textView)
        
        // 添加排除路径进行调试
        let exclusionPath = TEExclusionPath.circle(
            center: CGPoint(x: 175, y: 280),
            radius: 50,
            padding: UIEdgeInsets(top: 10, left: 10, bottom: 10, right: 10)
        )
        textView.textContainer.exclusionPaths = [exclusionPath]
    }
    
    private func setupDebugger() {
        // 设置调试器委托
        TETextDebugger.shared.delegate = self
        
        // 启用调试模式
        TETextDebugger.shared.enableDebugging()
        
        // 配置调试选项
        var options = TETextDebugOptions()
        options.showBaselines = true
        options.showLineFragments = true
        options.showExclusionPaths = true
        options.showSelection = true
        options.showAttachments = true
        options.showHighlights = true
        options.showGlyphs = false // 默认关闭，性能开销较大
        
        options.baselineColor = .red.withAlphaComponent(0.5)
        options.lineFragmentBorderColor = .blue.withAlphaComponent(0.3)
        options.lineFragmentUsedBorderColor = .cyan.withAlphaComponent(0.3)
        options.exclusionPathColor = .purple.withAlphaComponent(0.4)
        options.selectionColor = .systemYellow.withAlphaComponent(0.3)
        options.attachmentColor = .green.withAlphaComponent(0.5)
        options.highlightColor = .systemPink.withAlphaComponent(0.3)
        options.glyphBorderColor = .orange.withAlphaComponent(0.3)
        
        options.lineWidth = 1.0
        options.debugFontSize = 10.0
        options.debugTextColor = .black
        
        TETextDebugger.shared.updateOptions(options)
        
        // 应用调试到视图
        TETextDebugger.shared.debugLabel(label)
        TETextDebugger.shared.debugTextView(textView)
    }
    
    private func addDebugControls() {
        let stackView = UIStackView()
        stackView.axis = .horizontal
        stackView.spacing = 10
        stackView.distribution = .fillEqually
        stackView.frame = CGRect(x: 20, y: 450, width: 350, height: 44)
        view.addSubview(stackView)
        
        // 基线显示开关
        let baselineButton = UIButton(type: .system)
        baselineButton.setTitle("基线", for: .normal)
        baselineButton.addTarget(self, action: #selector(toggleBaselines), for: .touchUpInside)
        stackView.addArrangedSubview(baselineButton)
        
        // 行片段显示开关
        let fragmentsButton = UIButton(type: .system)
        fragmentsButton.setTitle("行片段", for: .normal)
        fragmentsButton.addTarget(self, action: #selector(toggleLineFragments), for: .touchUpInside)
        stackView.addArrangedSubview(fragmentsButton)
        
        // 排除路径显示开关
        let exclusionButton = UIButton(type: .system)
        exclusionButton.setTitle("排除路径", for: .normal)
        exclusionButton.addTarget(self, action: #selector(toggleExclusionPaths), for: .touchUpInside)
        stackView.addArrangedSubview(exclusionButton)
        
        // 字形显示开关
        let glyphsButton = UIButton(type: .system)
        glyphsButton.setTitle("字形", for: .normal)
        glyphsButton.addTarget(self, action: #selector(toggleGlyphs), for: .touchUpInside)
        stackView.addArrangedSubview(glyphsButton)
        
        // 刷新调试按钮
        let refreshButton = UIButton(type: .system)
        refreshButton.setTitle("刷新", for: .normal)
        refreshButton.addTarget(self, action: #selector(refreshDebugging), for: .touchUpInside)
        stackView.addArrangedSubview(refreshButton)
    }
    
    @objc private func toggleBaselines() {
        var options = TETextDebugger.shared.options
        options.showBaselines.toggle()
        TETextDebugger.shared.updateOptions(options)
    }
    
    @objc private func toggleLineFragments() {
        var options = TETextDebugger.shared.options
        options.showLineFragments.toggle()
        TETextDebugger.shared.updateOptions(options)
    }
    
    @objc private func toggleExclusionPaths() {
        var options = TETextDebugger.shared.options
        options.showExclusionPaths.toggle()
        TETextDebugger.shared.updateOptions(options)
    }
    
    @objc private func toggleGlyphs() {
        var options = TETextDebugger.shared.options
        options.showGlyphs.toggle()
        TETextDebugger.shared.updateOptions(options)
    }
    
    @objc private func refreshDebugging() {
        TETextDebugger.shared.refreshDebugging()
    }
    
    // MARK: - TETextDebuggerDelegate
    
    func debugger(_ debugger: TETextDebugger, didUpdateDebugInfo info: TETextDebugInfo) {
        print("调试信息更新:")
        print("- 布局时间: \(info.performanceInfo.layoutTime * 1000)ms")
        print("- 渲染时间: \(info.performanceInfo.renderTime * 1000)ms")
        print("- 总时间: \(info.performanceInfo.totalTime * 1000)ms")
        print("- 内存使用: \(formatBytes(info.performanceInfo.memoryUsage))")
        print("- 行片段数: \(info.layoutInfo.lineFragments.count)")
        print("- 排除路径数: \(info.exclusionPathInfo.paths.count)")
    }
    
    func debugger(_ debugger: TETextDebugger, didChangeDebuggingState isDebugging: Bool) {
        print("调试状态变化: \(isDebugging ? "启用" : "禁用")")
    }
    
    private func formatBytes(_ bytes: Int) -> String {
        let formatter = ByteCountFormatter()
        formatter.countStyle = .binary
        return formatter.string(fromByteCount: Int64(bytes))
    }
}
```

### 性能分析完整示例

```swift
import TextEngineKit

class PerformanceAnalysisViewController: UIViewController, TEPerformanceProfilerDelegate {
    private let label = TELabel()
    private let textView = TETextView()
    private let performanceLabel = UILabel()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        setupUI()
        setupPerformanceProfiler()
        addPerformanceControls()
        
        // 开始性能分析
        TEPerformanceProfiler.shared.startProfiling()
    }
    
    private func setupUI() {
        // 配置性能显示标签
        performanceLabel.text = "性能指标将在此显示"
        performanceLabel.frame = CGRect(x: 20, y: 50, width: 350, height: 40)
        performanceLabel.numberOfLines = 0
        performanceLabel.font = .monospacedSystemFont(ofSize: 12, weight: .regular)
        performanceLabel.textColor = .systemGreen
        view.addSubview(performanceLabel)
        
        // 配置测试标签
        label.text = "性能测试标签 - 用于分析布局性能"
        label.frame = CGRect(x: 20, y: 100, width: 350, height: 40)
        label.numberOfLines = 0
        label.font = .systemFont(ofSize: 16)
        view.addSubview(label)
        
        // 配置测试文本视图
        let textViewText = """
        性能测试文本视图 - 用于分析复杂文本的布局和渲染性能。
        
        这段文本包含多行内容，可以测试文本引擎在处理复杂布局时的性能表现。
        包括：
        • 多行文本布局计算
        • 行片段边界计算
        • 文本换行处理
        • 内存使用优化
        • 缓存机制效果
        
        通过性能分析器可以详细了解文本处理的各个环节耗时情况。
        """
        
        textView.attributedText = NSAttributedString(string: textViewText)
        textView.frame = CGRect(x: 20, y: 160, width: 350, height: 200)
        textView.isEditable = false
        textView.isScrollEnabled = false
        textView.font = .systemFont(ofSize: 14)
        view.addSubview(textView)
    }
    
    private func setupPerformanceProfiler() {
        // 设置性能分析器委托
        TEPerformanceProfiler.shared.delegate = self
        
        // 配置性能阈值
        TEPerformanceProfiler.shared.thresholds.maxLayoutTime = 0.016  // 16ms (60fps)
        TEPerformanceProfiler.shared.thresholds.maxRenderTime = 0.016  // 16ms (60fps)
        TEPerformanceProfiler.shared.thresholds.maxMemoryUsage = 5 * 1024 * 1024  // 5MB
        TEPerformanceProfiler.shared.thresholds.minFPS = 30.0  // 30 FPS
        TEPerformanceProfiler.shared.thresholds.maxCPUUsage = 0.8  // 80%
        TEPerformanceProfiler.shared.thresholds.maxGPUUsage = 0.8  // 80%
    }
    
    private func addPerformanceControls() {
        let stackView = UIStackView()
        stackView.axis = .horizontal
        stackView.spacing = 10
        stackView.distribution = .fillEqually
        stackView.frame = CGRect(x: 20, y: 380, width: 350, height: 44)
        view.addSubview(stackView)
        
        // 分析标签性能
        let analyzeLabelButton = UIButton(type: .system)
        analyzeLabelButton.setTitle("分析标签", for: .normal)
        analyzeLabelButton.addTarget(self, action: #selector(analyzeLabelPerformance), for: .touchUpInside)
        stackView.addArrangedSubview(analyzeLabelButton)
        
        // 分析文本视图性能
        let analyzeTextViewButton = UIButton(type: .system)
        analyzeTextViewButton.setTitle("分析文本视图", for: .normal)
        analyzeTextViewButton.addTarget(self, action: #selector(analyzeTextViewPerformance), for: .touchUpInside)
        stackView.addArrangedSubview(analyzeTextViewButton)
        
        // 生成性能报告
        let reportButton = UIButton(type: .system)
        reportButton.setTitle("生成报告", for: .normal)
        reportButton.addTarget(self, action: #selector(generatePerformanceReport), for: .touchUpInside)
        stackView.addArrangedSubview(reportButton)
        
        // 重置性能数据
        let resetButton = UIButton(type: .system)
        resetButton.setTitle("重置数据", for: .normal)
        resetButton.addTarget(self, action: #selector(resetPerformanceData), for: .touchUpInside)
        stackView.addArrangedSubview(resetButton)
    }
    
    @objc private func analyzeLabelPerformance() {
        // 修改标签内容以测试不同场景
        label.text = "性能测试 - 时间戳: \(Date().timeIntervalSince1970)"
        
        // 分析标签性能
        let metrics = TEPerformanceProfiler.shared.profileLabel(label)
        updatePerformanceDisplay(metrics: metrics, source: "标签")
    }
    
    @objc private func analyzeTextViewPerformance() {
        // 修改文本视图内容以测试不同场景
        let newText = """
        性能测试文本 - 时间戳: \(Date().timeIntervalSince1970)
        
        这是一段用于性能测试的多行文本内容。
        包含多个段落和不同的文本格式。
        
        第二段文本内容，用于测试文本引擎的
        布局和渲染性能表现。
        
        第三段文本，包含更多的内容以测试
        复杂的文本处理性能。
        """
        
        textView.attributedText = NSAttributedString(string: newText)
        
        // 分析文本视图性能
        let metrics = TEPerformanceProfiler.shared.profileTextView(textView)
        updatePerformanceDisplay(metrics: metrics, source: "文本视图")
    }
    
    @objc private func generatePerformanceReport() {
        let report = TEPerformanceProfiler.shared.getPerformanceReport()
        print("性能报告:\n\(report)")
        
        // 显示报告摘要
        let history = TEPerformanceProfiler.shared.getPerformanceHistory()
        let summary = "历史记录数: \(history.count)\n报告已生成，请查看控制台输出"
        performanceLabel.text = summary
    }
    
    @objc private func resetPerformanceData() {
        TEPerformanceProfiler.shared.resetPerformanceData()
        performanceLabel.text = "性能数据已重置"
    }
    
    private func updatePerformanceDisplay(metrics: TEPerformanceMetrics, source: String) {
        let layoutTime = String(format: "%.2f", metrics.layoutMetrics.layoutTime * 1000)
        let renderTime = String(format: "%.2f", metrics.renderMetrics.renderTime * 1000)
        let totalTime = String(format: "%.2f", metrics.overallMetrics.totalTime * 1000)
        let fps = String(format: "%.1f", metrics.overallMetrics.fps)
        let memory = formatBytes(metrics.overallMetrics.memoryUsage)
        let cacheHit = metrics.layoutMetrics.cacheHit ? "✓" : "✗"
        
        performanceLabel.text = """
        \(source)性能分析:
        布局: \(layoutTime)ms | 渲染: \(renderTime)ms | 总计: \(totalTime)ms
        FPS: \(fps) | 内存: \(memory) | 缓存: \(cacheHit)
        """
    }
    
    // MARK: - TEPerformanceProfilerDelegate
    
    func profiler(_ profiler: TEPerformanceProfiler, didCompleteAnalysis metrics: TEPerformanceMetrics) {
        print("性能分析完成:")
        print("- 布局时间: \(metrics.layoutMetrics.layoutTime * 1000)ms")
        print("- 渲染时间: \(metrics.renderMetrics.renderTime * 1000)ms")
        print("- 总时间: \(metrics.overallMetrics.totalTime * 1000)ms")
        print("- FPS: \(metrics.overallMetrics.fps)")
        print("- 内存使用: \(formatBytes(metrics.overallMetrics.memoryUsage))")
        print("- 缓存命中: \(metrics.layoutMetrics.cacheHit)")
    }
    
    func profiler(_ profiler: TEPerformanceProfiler, didDetectBottleneck bottleneck: TEPerformanceBottleneck) {
        print("发现性能瓶颈!")
        print("- 类型: \(bottleneck.type)")
        print("- 描述: \(bottleneck.description)")
        print("- 建议: \(bottleneck.suggestion)")
        print("- 严重程度: \(bottleneck.severity * 100)%")
        
        // 显示警告
        performanceLabel.textColor = .systemRed
        performanceLabel.text = "⚠️ 性能警告: \(bottleneck.description)"
        
        // 3秒后恢复颜色
        DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
            self.performanceLabel.textColor = .systemGreen
        }
    }
    
    func profiler(_ profiler: TEPerformanceProfiler, didTriggerWarning warning: String, severity: Float) {
        print("性能警告: \(warning) (严重程度: \(severity))")
        
        if severity > 0.8 {
            performanceLabel.textColor = .systemOrange
            performanceLabel.text = "⚠️ \(warning)"
            
            // 2秒后恢复颜色
            DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                self.performanceLabel.textColor = .systemGreen
            }
        }
    }
    
    private func formatBytes(_ bytes: Int) -> String {
        let formatter = ByteCountFormatter()
        formatter.countStyle = .binary
        return formatter.string(fromByteCount: Int64(bytes))
    }
    
    deinit {
        // 停止性能分析
        TEPerformanceProfiler.shared.stopProfiling()
    }
}
```

## 性能优化建议

### 1. 合理使用缓存
```swift
let options = TEProcessingOptions(cacheResult: true)  // 启用结果缓存
```

### 2. 异步处理大文本
```swift
let options = TEProcessingOptions(enableAsync: true, maxConcurrency: 4)
```

### 3. 使用合适的超时时间
```swift
let options = TEProcessingOptions(timeout: 30.0)  // 30秒超时
```

### 4. 批量处理文本
```swift
// 批量处理多个文本
let texts = ["文本1", "文本2", "文本3"]
let results = texts.map { engine.processText($0, options: options) }
```

### 5. 性能分析优化建议

#### 布局性能优化
- **减少复杂文本属性**：过多的富文本属性会增加布局计算复杂度
- **使用布局缓存**：启用 `cacheResult` 选项缓存布局结果
- **避免频繁布局更新**：批量更新文本内容，减少布局触发次数

#### 渲染性能优化
- **异步渲染**：使用 `TEAsyncLayer` 进行复杂的绘制操作
- **减少过度绘制**：优化视图层次结构，避免不必要的重绘
- **使用合适的图像格式**：选择适当的图像压缩格式和尺寸

#### 内存使用优化
- **及时释放资源**：使用完大文本后及时清理相关对象
- **合理设置缓存大小**：根据应用需求调整缓存策略
- **监控内存使用**：使用性能分析器监控内存使用情况

#### 排除路径性能优化
- **简化几何形状**：使用简单的几何形状作为排除路径
- **减少排除路径数量**：避免过多的排除路径影响布局性能
- **合理使用内边距**：适当的内边距可以提高文本可读性

### 6. 调试可视化性能建议
- **选择性启用调试元素**：只开启需要的调试可视化选项
- **避免在生产环境使用**：调试功能主要用于开发和测试阶段
- **注意字形显示性能**：字形边界显示会有较大性能开销

## 安全注意事项

### 1. 输入验证
TextEngineKit 内置了输入验证机制：
- URL 长度限制（最大 2048 字符）
- 只允许 HTTP/HTTPS 协议
- 过滤控制字符防止注入攻击

### 2. 内存管理
- 自动缓存管理
- 内存警告处理
- 合理的缓存大小限制

### 3. 线程安全
- 所有公共 API 都是线程安全的
- 异步操作有适当的同步机制
- 支持取消长时间运行的任务

## 贡献

欢迎提交 Issue 和 Pull Request 来改进 TextEngineKit。

### 开发规范
- 遵循 Swift API 设计规范
- 所有公共接口必须有文档注释
- 提供使用示例
- 保持代码简洁，函数长度不超过 50 行

## 许可证

TextEngineKit 基于 MIT 许可证开源，详见 [LICENSE](LICENSE) 文件。

## 作者

TextEngineKit 由 TextEngineKit 团队开发和维护。