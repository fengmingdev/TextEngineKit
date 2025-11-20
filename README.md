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

## 贡献

欢迎提交 Issue 和 Pull Request 来改进 TextEngineKit。

## 许可证

TextEngineKit 基于 MIT 许可证开源，详见 [LICENSE](LICENSE) 文件。

## 作者

TextEngineKit 由 TextEngineKit 团队开发和维护。