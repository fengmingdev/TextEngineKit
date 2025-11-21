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
🎯 **文本选择** - 完整的文本选择管理器，支持范围选择、复制和编辑菜单
🔄 **排除路径** - 灵活的文本排除路径系统，支持复杂几何形状和内外排除模式
🔍 **调试可视化** - 强大的调试工具，可视化显示基线、行片段、字形边界等
📈 **性能分析** - 详细的性能分析器，监控布局、渲染和内存使用指标

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
文本选择管理器，提供完整的文本选择功能。

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
}
```

#### TEExclusionPath
排除路径系统，支持复杂几何形状的文本布局避让。

```swift
public struct TEExclusionPath {
    public enum ExclusionType {
        case inside  // 排除路径内部区域
        case outside // 排除路径外部区域
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
```

#### TETextDebugger
调试可视化工具，提供文本布局的详细调试信息。

```swift
public final class TETextDebugger {
    public static let shared: TETextDebugger
    public var options: TETextDebugOptions
    
    public func enableDebugging()
    public func disableDebugging()
    public func updateOptions(_ options: TETextDebugOptions)
    public func debugLabel(_ label: TELabel)
    public func debugTextView(_ textView: TETextView)
    public func getDebugInfo(for view: UIView) -> TETextDebugInfo
}

public struct TETextDebugOptions {
    public var showBaselines: Bool
    public var baselineColor: UIColor
    public var showLineFragments: Bool
    public var lineFragmentBorderColor: UIColor
    public var showGlyphs: Bool
    public var glyphBorderColor: UIColor
    public var showExclusionPaths: Bool
    public var exclusionPathColor: UIColor
    public var showSelection: Bool
    public var selectionColor: UIColor
    public var showAttachments: Bool
    public var attachmentColor: UIColor
    public var showHighlights: Bool
    public var highlightColor: UIColor
    public var lineWidth: CGFloat
    public var debugFontSize: CGFloat
    public var debugTextColor: UIColor
}
```

#### TEPerformanceProfiler
性能分析器，提供详细的性能监控和分析功能。

```swift
public final class TEPerformanceProfiler {
    public static let shared: TEPerformanceProfiler
    public weak var delegate: TEPerformanceProfilerDelegate?
    public var options: TEProfilingOptions
    
    public func startProfiling()
    public func stopProfiling()
    public func updateOptions(_ options: TEProfilingOptions)
    public func profileLayout(_ attributedString: NSAttributedString, containerSize: CGSize) -> TEPerformanceMetrics.LayoutMetrics
    public func profileRender(_ layout: TETextLayout, in context: CGContext) -> TEPerformanceMetrics.RenderMetrics
    public func generateReport() -> TEPerformanceReport
}

public struct TEProfilingOptions {
    public var enableLayoutProfiling: Bool
    public var enableRenderProfiling: Bool
    public var enableMemoryProfiling: Bool
    public var reportingInterval: TimeInterval
}

public struct TEPerformanceMetrics {
    public struct LayoutMetrics {
        public let layoutTime: TimeInterval
        public let lineCount: Int
        public let glyphCount: Int
        public let characterCount: Int
        public let cacheHit: Bool
        public let memoryUsage: Int
    }
    
    public struct RenderMetrics {
        public let renderTime: TimeInterval
        public let pixelCount: Int
        public let drawCallCount: Int
        public let memoryUsage: Int
        public let gpuUsage: Double
    }
    
    public struct OverallMetrics {
        public let totalTime: TimeInterval
        public let fps: Double
        public let cpuUsage: Double
        public let memoryUsage: Int
        public let energyUsage: Double
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