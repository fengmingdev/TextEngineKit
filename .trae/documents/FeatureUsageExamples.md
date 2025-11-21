# TextEngineKit 功能使用示例

本文档提供了 TextEngineKit 新功能的详细使用示例，包括文本选择管理、排除路径、调试可视化和性能分析。

## 目录

1. [文本选择管理](#文本选择管理)
2. [排除路径系统](#排除路径系统)
3. [调试可视化](#调试可视化)
4. [性能分析](#性能分析)
5. [综合示例](#综合示例)

## 文本选择管理

### 基础文本选择

```swift
import UIKit
import TextEngineKit

class TextSelectionViewController: UIViewController {
    private let textView = TETextView()
    private let selectionManager = TETextSelectionManager()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        setupTextView()
        setupSelectionManager()
    }
    
    private func setupTextView() {
        textView.frame = CGRect(x: 20, y: 100, width: 350, height: 400)
        textView.backgroundColor = .systemBackground
        textView.layer.borderColor = UIColor.systemGray3.cgColor
        textView.layer.borderWidth = 1.0
        
        // 设置富文本内容
        let attributedText = NSMutableAttributedString(string: """)
        attributedText.append(NSAttributedString(string: "TextEngineKit 文本选择功能\n\n", attributes: [
            .font: UIFont.boldSystemFont(ofSize: 20),
            .foregroundColor: UIColor.systemBlue
        ]))
        
        attributedText.append(NSAttributedString(string: "这是演示文本选择功能的示例内容。您可以：\n\n", attributes: [
            .font: UIFont.systemFont(ofSize: 16)
        ]))
        
        attributedText.append(NSAttributedString(string: "• 选择任意文本范围\n", attributes: [
            .font: UIFont.systemFont(ofSize: 14)
        ]))
        
        attributedText.append(NSAttributedString(string: "• 复制选中的文本\n", attributes: [
            .font: UIFont.systemFont(ofSize: 14)
        ]))
        
        attributedText.append(NSAttributedString(string: "• 使用编辑菜单\n\n", attributes: [
            .font: UIFont.systemFont(ofSize: 14)
        ]))
        
        attributedText.append(NSAttributedString(string: "长按文本或双击来开始选择！", attributes: [
            .font: UIFont.italicSystemFont(ofSize: 16),
            .foregroundColor: UIColor.systemGray
        ]))
        
        textView.attributedText = attributedText
        view.addSubview(textView)
    }
    
    private func setupSelectionManager() {
        // 设置选择管理器
        selectionManager.setupContainerView(textView)
        selectionManager.isSelectionEnabled = true
        selectionManager.selectionColor = UIColor.systemBlue.withAlphaComponent(0.3)
        selectionManager.delegate = self
    }
    
    @IBAction func selectAllTapped() {
        selectionManager.selectAll()
    }
    
    @IBAction func clearSelectionTapped() {
        selectionManager.clearSelection()
    }
    
    @IBAction func copySelectionTapped() {
        if let selectedText = selectionManager.copySelectedText() {
            UIPasteboard.general.string = selectedText
            showAlert(message: "已复制: \\(selectedText)\"")
        } else {
            showAlert(message: "没有选择文本\")")
        }
    }
    
    private func showAlert(message: String) {
        let alert = UIAlertController(title: "提示", message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "确定", style: .default))
        present(alert, animated: true)
    }
}

extension TextSelectionViewController: TETextSelectionManagerDelegate {
    func selectionManager(_ manager: TETextSelectionManager, didChangeSelection range: TETextSelectionRange?) {
        if let range = range {
            print("选择范围变化: \(range.location) - \(range.location + range.length)")
            
            // 更新UI状态
            updateSelectionUI(range: range)
        } else {
            print("清除选择\")
            updateSelectionUI(range: nil)
        }
    }
    
    func selectionManager(_ manager: TETextSelectionManager, shouldChangeSelection range: TETextSelectionRange?) -> Bool {
        // 可以在这里实现自定义的选择逻辑
        // 例如：限制最小选择长度
        if let range = range, range.length < 3 {
            print("选择长度太短，不允许选择\")
            return false
        }
        return true
    }
    
    private func updateSelectionUI(range: TETextSelectionRange?) {
        // 更新按钮状态等UI元素
        if let range = range {
            print("当前选择长度: \(range.length)")
        }
    }
}
```

### 高级文本选择功能

```swift
// 程序化文本选择
func programmaticSelectionExample() {
    let text = "TextEngineKit 提供了强大的文本选择功能"
    
    // 选择特定范围
    let range = TETextSelectionRange(location: 0, length: 12)
    selectionManager.setSelection(range: range)
    
    // 延迟后清除选择
    DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
        self.selectionManager.clearSelection()
    }
    
    // 延迟后选择全部
    DispatchQueue.main.asyncAfter(deadline: .now() + 4.0) {
        self.selectionManager.selectAll()
    }
}

// 自定义选择颜色
func customizeSelectionAppearance() {
    selectionManager.selectionColor = UIColor.systemPurple.withAlphaComponent(0.4)
    
    // 根据选择状态改变颜色
    if let range = selectionManager.selectedRange {
        if range.length > 50 {
            selectionManager.selectionColor = UIColor.systemRed.withAlphaComponent(0.4)
        } else {
            selectionManager.selectionColor = UIColor.systemBlue.withAlphaComponent(0.3)
        }
    }
}
```

## 排除路径系统

### 基础排除路径

```swift
import UIKit
import TextEngineKit

class ExclusionPathViewController: UIViewController {
    private let textView = TETextView()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupTextView()
        setupExclusionPaths()
    }
    
    private func setupTextView() {
        textView.frame = CGRect(x: 20, y: 100, width: 350, height: 500)
        textView.backgroundColor = .systemBackground
        textView.isEditable = false
        textView.isScrollEnabled = false
        
        // 创建长文本内容
        let longText = String(repeating: "TextEngineKit 排除路径功能允许文本环绕复杂形状。\n", count: 20)
        let attributedText = NSMutableAttributedString(string: longText)
        
        // 设置基本样式
        attributedText.addAttribute(.font, value: UIFont.systemFont(ofSize: 16), range: NSRange(location: 0, length: attributedText.length))
        attributedText.addAttribute(.foregroundColor, value: UIColor.label, range: NSRange(location: 0, length: attributedText.length))
        
        textView.attributedText = attributedText
        view.addSubview(textView)
    }
    
    private func setupExclusionPaths() {
        // 创建矩形排除路径
        let rectPath = TEExclusionPath.rect(
            CGRect(x: 50, y: 100, width: 100, height: 100),
            padding: UIEdgeInsets(top: 10, left: 10, bottom: 10, right: 10)
        )
        
        // 创建圆形排除路径
        let circlePath = TEExclusionPath.circle(
            center: CGPoint(x: 250, y: 200),
            radius: 60,
            padding: UIEdgeInsets(top: 15, left: 15, bottom: 15, right: 15)
        )
        
        // 创建椭圆排除路径
        let ellipsePath = TEExclusionPath.ellipse(
            in: CGRect(x: 100, y: 350, width: 150, height: 80),
            padding: UIEdgeInsets(top: 5, left: 5, bottom: 5, right: 5)
        )
        
        // 应用排除路径
        textView.exclusionPaths = [rectPath, circlePath, ellipsePath]
    }
}
```

### 高级排除路径功能

```swift
// 自定义路径排除
func customPathExclusionExample() {
    // 创建星形路径
    let starPath = UIBezierPath()
    let center = CGPoint(x: 175, y: 250)
    let points = 5
    let outerRadius: CGFloat = 80
    let innerRadius: CGFloat = 40
    
    for i in 0..<points * 2 {
        let angle = CGFloat(i) * CGFloat.pi / CGFloat(points)
        let radius = i % 2 == 0 ? outerRadius : innerRadius
        let point = CGPoint(
            x: center.x + radius * cos(angle - CGFloat.pi / 2),
            y: center.y + radius * sin(angle - CGFloat.pi / 2)
        )
        
        if i == 0 {
            starPath.move(to: point)
        } else {
            starPath.addLine(to: point)
        }
    }
    starPath.close()
    
    // 创建排除路径
    let starExclusionPath = TEExclusionPath(
        path: starPath,
        padding: UIEdgeInsets(top: 20, left: 20, bottom: 20, right: 20),
        type: .inside
    )
    
    textView.exclusionPaths = [starExclusionPath]
}

// 动态排除路径
func dynamicExclusionPathExample() {
    // 创建可移动的圆形排除路径
    var movingCircle = TEExclusionPath.circle(
        center: CGPoint(x: 100, y: 200),
        radius: 50
    )
    
    // 使用定时器移动排除路径
    var offset: CGFloat = 0
    Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { timer in
        offset += 5
        
        // 更新圆形位置
        let newCenter = CGPoint(
            x: 100 + 75 * cos(offset * 0.05),
            y: 200 + 50 * sin(offset * 0.05)
        )
        
        movingCircle = TEExclusionPath.circle(
            center: newCenter,
            radius: 50
        )
        
        self.textView.exclusionPaths = [movingCircle]
        
        if offset > 1000 {
            timer.invalidate()
        }
    }
}

// 内外排除模式对比
func exclusionTypeComparison() {
    // 创建相同的路径，但使用不同的排除类型
    let rect = CGRect(x: 100, y: 200, width: 150, height: 100)
    
    // 内部排除（默认）
    let insideExclusion = TEExclusionPath.rect(rect, type: .inside)
    
    // 外部排除
    let outsideExclusion = TEExclusionPath.rect(rect, type: .outside)
    
    // 切换排除类型
    func switchExclusionType() {
        if textView.exclusionPaths.first?.type == .inside {
            textView.exclusionPaths = [outsideExclusion]
        } else {
            textView.exclusionPaths = [insideExclusion]
        }
    }
}
```

## 调试可视化

### 基础调试功能

```swift
import UIKit
import TextEngineKit

class DebugVisualizationViewController: UIViewController {
    private let label = TELabel()
    private let textView = TETextView()
    private let debugButton = UIButton(type: .system)
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        setupDebugButton()
    }
    
    private func setupUI() {
        // 设置标签
        label.frame = CGRect(x: 20, y: 100, width: 350, height: 100)
        label.backgroundColor = .systemBackground
        label.layer.borderColor = UIColor.systemGray3.cgColor
        label.layer.borderWidth = 1.0
        
        let labelText = NSMutableAttributedString(string: "TextEngineKit 调试可视化\n")
        labelText.addAttribute(.font, value: UIFont.boldSystemFont(ofSize: 18), range: NSRange(location: 0, length: labelText.length))
        labelText.addAttribute(.foregroundColor, value: UIColor.systemBlue, range: NSRange(location: 0, length: labelText.length))
        
        label.attributedText = labelText
        view.addSubview(label)
        
        // 设置文本视图
        textView.frame = CGRect(x: 20, y: 220, width: 350, height: 300)
        textView.backgroundColor = .systemBackground
        textView.layer.borderColor = UIColor.systemGray3.cgColor
        textView.layer.borderWidth = 1.0
        textView.isEditable = false
        
        let textViewContent = String(repeating: "调试可视化功能可以帮助您理解文本布局。\n", count: 10)
        let attributedContent = NSMutableAttributedString(string: textViewContent)
        attributedContent.addAttribute(.font, value: UIFont.systemFont(ofSize: 14), range: NSRange(location: 0, length: attributedContent.length))
        
        textView.attributedText = attributedContent
        view.addSubview(textView)
    }
    
    private func setupDebugButton() {
        debugButton.frame = CGRect(x: 20, y: 540, width: 350, height: 44)
        debugButton.setTitle("启用调试可视化", for: .normal)
        debugButton.backgroundColor = .systemBlue
        debugButton.setTitleColor(.white, for: .normal)
        debugButton.layer.cornerRadius = 8
        debugButton.addTarget(self, action: #selector(toggleDebug), for: .touchUpInside)
        view.addSubview(debugButton)
    }
    
    @objc private func toggleDebug() {
        if debugButton.titleLabel?.text == "启用调试可视化" {
            enableDebugging()
            debugButton.setTitle("禁用调试可视化", for: .normal)
            debugButton.backgroundColor = .systemRed
        } else {
            disableDebugging()
            debugButton.setTitle("启用调试可视化", for: .normal)
            debugButton.backgroundColor = .systemBlue
        }
    }
    
    private func enableDebugging() {
        // 启用调试模式
        TETextDebugger.shared.enableDebugging()
        
        // 配置调试选项
        var debugOptions = TETextDebugOptions()
        debugOptions.showBaselines = true
        debugOptions.baselineColor = UIColor.red.withAlphaComponent(0.7)
        debugOptions.showLineFragments = true
        debugOptions.lineFragmentBorderColor = UIColor.blue.withAlphaComponent(0.5)
        debugOptions.lineFragmentUsedBorderColor = UIColor.green.withAlphaComponent(0.5)
        debugOptions.showGlyphs = false // 禁用，因为可能影响性能
        debugOptions.showExclusionPaths = true
        debugOptions.exclusionPathColor = UIColor.purple.withAlphaComponent(0.3)
        debugOptions.showSelection = true
        debugOptions.selectionColor = UIColor.systemYellow.withAlphaComponent(0.4)
        debugOptions.showAttachments = true
        debugOptions.attachmentColor = UIColor.orange.withAlphaComponent(0.5)
        debugOptions.showHighlights = true
        debugOptions.highlightColor = UIColor.systemPink.withAlphaComponent(0.3)
        debugOptions.lineWidth = 1.0
        debugOptions.debugFontSize = 10.0
        debugOptions.debugTextColor = .black
        
        // 应用调试选项
        TETextDebugger.shared.updateOptions(debugOptions)
        
        // 调试视图
        TETextDebugger.shared.debugLabel(label)
        TETextDebugger.shared.debugTextView(textView)
    }
    
    private func disableDebugging() {
        TETextDebugger.shared.disableDebugging()
    }
}
```

### 高级调试功能

```swift
// 获取详细调试信息
func getDetailedDebugInfo() {
    let debugInfo = TETextDebugger.shared.getDebugInfo(for: textView)
    
    // 布局信息
    print("布局信息:")
    print("- 行数: \(debugInfo.layoutInfo.lineFragments.count)")
    print("- 基线数: \(debugInfo.layoutInfo.baselines.count)")
    
    // 性能信息
    print("性能信息:")
    print("- 布局时间: \(debugInfo.performanceInfo.layoutTime) 秒")
    print("- 渲染时间: \(debugInfo.performanceInfo.renderTime) 秒")
    print("- 总时间: \(debugInfo.performanceInfo.totalTime) 秒")
    print("- 内存使用: \(debugInfo.performanceInfo.memoryUsage) 字节")
    print("- 缓存命中: \(debugInfo.performanceInfo.cacheHit)")
    
    // 排除路径信息
    print("排除路径信息:")
    print("- 排除路径数: \(debugInfo.exclusionPathInfo.paths.count)")
    print("- 有效矩形数: \(debugInfo.exclusionPathInfo.validRects.count)")
    print("- 被排除面积: \(debugInfo.exclusionPathInfo.excludedArea)")
    print("- 总面积: \(debugInfo.exclusionPathInfo.totalArea)")
    
    // 选择信息
    print("选择信息:")
    if let selectionRange = debugInfo.selectionInfo.selectedRange {
        print("- 选择范围: \(selectionRange.location) - \(selectionRange.location + selectionRange.length)")
        print("- 选择矩形数: \(debugInfo.selectionInfo.selectionRects.count)")
    } else {
        print("- 没有选择\")
    }
}

// 自定义调试颜色方案
func customDebugColorScheme() {
    var debugOptions = TETextDebugOptions()
    
    // 深色主题调试颜色
    debugOptions.baselineColor = UIColor.cyan.withAlphaComponent(0.8)
    debugOptions.lineFragmentBorderColor = UIColor.green.withAlphaComponent(0.6)
    debugOptions.lineFragmentUsedBorderColor = UIColor.yellow.withAlphaComponent(0.6)
    debugOptions.exclusionPathColor = UIColor.magenta.withAlphaComponent(0.4)
    debugOptions.selectionColor = UIColor.orange.withAlphaComponent(0.5)
    debugOptions.attachmentColor = UIColor.red.withAlphaComponent(0.6)
    debugOptions.highlightColor = UIColor.systemTeal.withAlphaComponent(0.4)
    debugOptions.debugTextColor = UIColor.white
    
    TETextDebugger.shared.updateOptions(debugOptions)
}

// 条件调试显示
func conditionalDebugDisplay() {
    var debugOptions = TETextDebugOptions()
    
    // 只在调试模式下显示某些信息
    #if DEBUG
    debugOptions.showBaselines = true
    debugOptions.showLineFragments = true
    debugOptions.showGlyphs = true // 只在调试模式下显示字形
    #else
    debugOptions.showBaselines = false
    debugOptions.showLineFragments = false
    debugOptions.showGlyphs = false
    #endif
    
    debugOptions.showExclusionPaths = true
    debugOptions.showSelection = true
    
    TETextDebugger.shared.updateOptions(debugOptions)
}
```

## 性能分析

### 基础性能分析

```swift
import UIKit
import TextEngineKit

class PerformanceAnalysisViewController: UIViewController {
    private let textView = TETextView()
    private let performanceLabel = UILabel()
    private let analyzeButton = UIButton(type: .system)
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        setupPerformanceProfiler()
    }
    
    private func setupUI() {
        // 设置文本视图
        textView.frame = CGRect(x: 20, y: 100, width: 350, height: 400)
        textView.backgroundColor = .systemBackground
        textView.layer.borderColor = UIColor.systemGray3.cgColor
        textView.layer.borderWidth = 1.0
        textView.isEditable = false
        
        // 创建性能测试文本
        let performanceText = generatePerformanceTestText()
        textView.attributedText = performanceText
        view.addSubview(textView)
        
        // 设置性能标签
        performanceLabel.frame = CGRect(x: 20, y: 520, width: 350, height: 60)
        performanceLabel.backgroundColor = .systemGray6
        performanceLabel.layer.cornerRadius = 8
        performanceLabel.layer.masksToBounds = true
        performanceLabel.numberOfLines = 0
        performanceLabel.font = UIFont.monospacedSystemFont(ofSize: 12, weight: .regular)
        performanceLabel.textAlignment = .left
        view.addSubview(performanceLabel)
        
        // 设置分析按钮
        analyzeButton.frame = CGRect(x: 20, y: 600, width: 350, height: 44)
        analyzeButton.setTitle("开始性能分析", for: .normal)
        analyzeButton.backgroundColor = .systemGreen
        analyzeButton.setTitleColor(.white, for: .normal)
        analyzeButton.layer.cornerRadius = 8
        analyzeButton.addTarget(self, action: #selector(startPerformanceAnalysis), for: .touchUpInside)
        view.addSubview(analyzeButton)
    }
    
    private func generatePerformanceTestText() -> NSAttributedString {
        let text = NSMutableAttributedString()
        
        // 添加标题
        let title = NSAttributedString(string: "性能分析测试\n\n", attributes: [
            .font: UIFont.boldSystemFont(ofSize: 24),
            .foregroundColor: UIColor.systemBlue
        ])
        text.append(title)
        
        // 添加混合样式的长文本
        for i in 0..<50 {
            let paragraph = NSMutableAttributedString(string: "第\(i + 1)段：这是性能测试文本，包含多种样式和属性。\n")
            
            // 随机应用不同样式
            if i % 3 == 0 {
                paragraph.addAttribute(.font, value: UIFont.boldSystemFont(ofSize: 16), range: NSRange(location: 0, length: 4))
            }
            
            if i % 5 == 0 {
                paragraph.addAttribute(.foregroundColor, value: UIColor.systemRed, range: NSRange(location: 0, length: min(10, paragraph.length)))
            }
            
            if i % 7 == 0 {
                let shadow = NSShadow()
                shadow.shadowOffset = CGSize(width: 1, height: 1)
                shadow.shadowBlurRadius = 2
                shadow.shadowColor = UIColor.black.withAlphaComponent(0.3)
                paragraph.addAttribute(.shadow, value: shadow, range: NSRange(location: 0, length: paragraph.length))
            }
            
            text.append(paragraph)
        }
        
        return text
    }
    
    private func setupPerformanceProfiler() {
        // 启用性能分析
        TEPerformanceProfiler.shared.startProfiling()
        
        // 配置分析选项
        var profilingOptions = TEProfilingOptions()
        profilingOptions.enableLayoutProfiling = true
        profilingOptions.enableRenderProfiling = true
        profilingOptions.enableMemoryProfiling = true
        profilingOptions.reportingInterval = 0.5 // 每0.5秒报告一次
        
        TEPerformanceProfiler.shared.updateOptions(profilingOptions)
        TEPerformanceProfiler.shared.delegate = self
    }
    
    @objc private func startPerformanceAnalysis() {
        analyzeButton.isEnabled = false
        analyzeButton.setTitle("分析中...", for: .normal)
        analyzeButton.backgroundColor = .systemGray
        
        // 模拟多次布局操作
        DispatchQueue.global(qos: .userInitiated).async {
            var totalLayoutTime: TimeInterval = 0
            var totalRenderTime: TimeInterval = 0
            var layoutCount = 0
            var renderCount = 0
            
            for i in 0..<10 {
                // 分析布局性能
                let layoutStartTime = CACurrentMediaTime()
                let layoutMetrics = TEPerformanceProfiler.shared.profileLayout(
                    self.textView.attributedText,
                    containerSize: CGSize(width: 350, height: 400)
                )
                let layoutEndTime = CACurrentMediaTime()
                
                totalLayoutTime += layoutEndTime - layoutStartTime
                layoutCount += 1
                
                // 分析渲染性能
                UIGraphicsBeginImageContextWithOptions(CGSize(width: 350, height: 400), false, 0)
                if let context = UIGraphicsGetCurrentContext() {
                    let renderStartTime = CACurrentMediaTime()
                    
                    // 创建文本布局
                    let layout = TETextLayout()
                    layout.attributedString = self.textView.attributedText
                    layout.containerSize = CGSize(width: 350, height: 400)
                    
                    let renderMetrics = TEPerformanceProfiler.shared.profileRender(layout, in: context)
                    let renderEndTime = CACurrentMediaTime()
                    
                    totalRenderTime += renderEndTime - renderStartTime
                    renderCount += 1
                    
                    DispatchQueue.main.async {
                        self.updatePerformanceDisplay(
                            layoutMetrics: layoutMetrics,
                            renderMetrics: renderMetrics,
                            iteration: i + 1
                        )
                    }
                }
                UIGraphicsEndImageContext()
                
                // 短暂延迟以模拟真实使用场景
                Thread.sleep(forTimeInterval: 0.1)
            }
            
            // 生成最终报告
            let report = TEPerformanceProfiler.shared.generateReport()
            
            DispatchQueue.main.async {
                self.showFinalReport(report)
                self.analyzeButton.isEnabled = true
                self.analyzeButton.setTitle("重新分析", for: .normal)
                self.analyzeButton.backgroundColor = .systemGreen
            }
        }
    }
    
    private func updatePerformanceDisplay(
        layoutMetrics: TEPerformanceMetrics.LayoutMetrics,
        renderMetrics: TEPerformanceMetrics.RenderMetrics,
        iteration: Int
    ) {
        let displayText = """
        第\(iteration)次分析结果：
        布局: \(String(format: "%.3f", layoutMetrics.layoutTime))s, 行数: \(layoutMetrics.lineCount), 缓存: \(layoutMetrics.cacheHit ? "命中" : "未命中")
        渲染: \(String(format: "%.3f", renderMetrics.renderTime))s, 像素: \(renderMetrics.pixelCount), GPU: \(String(format: "%.1f", renderMetrics.gpuUsage * 100))%
        内存: \(layoutMetrics.memoryUsage + renderMetrics.memoryUsage) bytes
        """
        
        performanceLabel.text = displayText
    }
    
    private func showFinalReport(_ report: TEPerformanceReport) {
        let finalReport = """
        📊 性能分析完成！
        
        平均布局时间: \(String(format: "%.4f", report.averageLayoutTime))s
        平均渲染时间: \(String(format: "%.4f", report.averageRenderTime))s
        总内存使用: \(report.totalMemoryUsage) bytes
        平均FPS: \(String(format: "%.1f", report.averageFPS))
        
        性能评级: \(getPerformanceRating(report))
        """
        
        performanceLabel.text = finalReport
    }
    
    private func getPerformanceRating(_ report: TEPerformanceReport) -> String {
        if report.averageLayoutTime < 0.001 && report.averageRenderTime < 0.001 {
            return "🌟 优秀"
        } else if report.averageLayoutTime < 0.005 && report.averageRenderTime < 0.005 {
            return "✅ 良好"
        } else if report.averageLayoutTime < 0.010 && report.averageRenderTime < 0.010 {
            return "⚠️ 一般"
        } else {
            return "❌ 需要优化"
        }
    }
}

extension PerformanceAnalysisViewController: TEPerformanceProfilerDelegate {
    func performanceProfiler(_ profiler: TEPerformanceProfiler, didGenerateReport report: TEPerformanceReport) {
        print("收到性能报告: \(report)")
    }
    
    func performanceProfiler(_ profiler: TEPerformanceProfiler, didDetectPerformanceIssue issue: TEPerformanceIssue) {
        print("检测到性能问题: \(issue)")
        
        DispatchQueue.main.async {
            self.showPerformanceWarning(issue)
        }
    }
    
    private func showPerformanceWarning(_ issue: TEPerformanceIssue) {
        let alert = UIAlertController(
            title: "性能警告",
            message: "检测到性能问题: \(issue.description)",
            preferredStyle: .alert
        )
        alert.addAction(UIAlertAction(title: "确定", style: .default))
        present(alert, animated: true)
    }
}
```

### 高级性能分析功能

```swift
// 内存分析
func memoryProfilingExample() {
    // 启用内存分析
    var profilingOptions = TEProfilingOptions()
    profilingOptions.enableMemoryProfiling = true
    TEPerformanceProfiler.shared.updateOptions(profilingOptions)
    
    // 监控内存使用
    let initialMemory = getCurrentMemoryUsage()
    
    // 执行文本操作
    let largeText = generateLargeText()
    let layout = performTextLayout(largeText)
    let renderedImage = renderText(layout)
    
    let finalMemory = getCurrentMemoryUsage()
    let memoryIncrease = finalMemory - initialMemory
    
    print("内存增加: \(memoryIncrease) bytes")
    
    if memoryIncrease > 1024 * 1024 { // 超过1MB
        print("警告：内存使用增加过多")
    }
}

// 实时性能监控
func realTimePerformanceMonitoring() {
    // 设置实时监控
    Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { timer in
        let report = TEPerformanceProfiler.shared.generateReport()
        
        // 检查性能指标
        if report.averageLayoutTime > 0.016 { // 超过16ms (60fps)
            print("布局性能警告: \(report.averageLayoutTime)s")
        }
        
        if report.averageRenderTime > 0.016 {
            print("渲染性能警告: \(report.averageRenderTime)s")
        }
        
        if report.averageFPS < 30 {
            print("FPS过低: \(report.averageFPS)")
        }
        
        // 更新UI
        DispatchQueue.main.async {
            self.updatePerformanceDisplay(report)
        }
    }
}

// 性能基准测试
func performanceBenchmark() {
    let benchmarkResults: [TEPerformanceMetrics] = []
    
    // 测试不同文本大小
    let textSizes = [100, 500, 1000, 5000, 10000]
    
    for size in textSizes {
        let testText = generateText(ofLength: size)
        
        // 测量布局性能
        let layoutStart = CACurrentMediaTime()
        let layoutMetrics = TEPerformanceProfiler.shared.profileLayout(
            testText,
            containerSize: CGSize(width: 300, height: 400)
        )
        let layoutEnd = CACurrentMediaTime()
        
        // 测量渲染性能
        UIGraphicsBeginImageContextWithOptions(CGSize(width: 300, height: 400), false, 0)
        if let context = UIGraphicsGetCurrentContext() {
            let renderStart = CACurrentMediaTime()
            
            let layout = TETextLayout()
            layout.attributedString = testText
            layout.containerSize = CGSize(width: 300, height: 400)
            
            let renderMetrics = TEPerformanceProfiler.shared.profileRender(layout, in: context)
            let renderEnd = CACurrentMediaTime()
            
            print("文本大小: \(size)")
            print("布局时间: \(layoutEnd - layoutStart)s, 行数: \(layoutMetrics.lineCount)")
            print("渲染时间: \(renderEnd - renderStart)s, 像素: \(renderMetrics.pixelCount)")
            print("---")
        }
        UIGraphicsEndImageContext()
    }
}
```

## 综合示例

### 完整功能演示

```swift
import UIKit
import TextEngineKit

class ComprehensiveDemoViewController: UIViewController {
    private let textView = TETextView()
    private let selectionManager = TETextSelectionManager()
    private let statusLabel = UILabel()
    private let controlPanel = UIStackView()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        setupTextSelection()
        setupExclusionPaths()
        setupPerformanceMonitoring()
    }
    
    private func setupUI() {
        view.backgroundColor = .systemBackground
        title = "TextEngineKit 综合演示"
        
        // 设置文本视图
        textView.frame = CGRect(x: 20, y: 150, width: 350, height: 400)
        textView.backgroundColor = .systemBackground
        textView.layer.borderColor = UIColor.systemGray3.cgColor
        textView.layer.borderWidth = 1.0
        textView.isEditable = false
        textView.isScrollEnabled = false
        
        let demoText = generateDemoText()
        textView.attributedText = demoText
        view.addSubview(textView)
        
        // 设置状态标签
        statusLabel.frame = CGRect(x: 20, y: 570, width: 350, height: 80)
        statusLabel.backgroundColor = .systemGray6
        statusLabel.layer.cornerRadius = 8
        statusLabel.layer.masksToBounds = true
        statusLabel.numberOfLines = 0
        statusLabel.font = UIFont.monospacedSystemFont(ofSize: 11, weight: .regular)
        statusLabel.textAlignment = .left
        view.addSubview(statusLabel)
        
        // 设置控制面板
        setupControlPanel()
    }
    
    private func generateDemoText() -> NSAttributedString {
        let text = NSMutableAttributedString()
        
        // 标题
        let title = NSAttributedString(string: "🚀 TextEngineKit 综合功能演示\n\n", attributes: [
            .font: UIFont.boldSystemFont(ofSize: 20),
            .foregroundColor: UIColor.systemBlue
        ])
        text.append(title)
        
        // 功能介绍
        let features = [
            "🎯 文本选择：支持范围选择、复制、编辑菜单",
            "🔄 排除路径：文本可环绕复杂形状",
            "🔍 调试可视化：实时显示布局信息",
            "📈 性能分析：监控布局渲染性能",
            "⚡ 异步渲染：高性能文本渲染"
        ]
        
        for feature in features {
            let featureText = NSAttributedString(string: "\(feature)\n", attributes: [
                .font: UIFont.systemFont(ofSize: 14),
                .foregroundColor: UIColor.label
            ])
            text.append(featureText)
        }
        
        // 长文本内容
        let content = String(repeating: "\n这是一段用于演示的长文本内容，用于展示 TextEngineKit 的各种功能特性。", count: 8)
        let contentText = NSAttributedString(string: content, attributes: [
            .font: UIFont.systemFont(ofSize: 12),
            .foregroundColor: UIColor.secondaryLabel
        ])
        text.append(contentText)
        
        return text
    }
    
    private func setupControlPanel() {
        controlPanel.axis = .horizontal
        controlPanel.distribution = .fillEqually
        controlPanel.spacing = 10
        controlPanel.frame = CGRect(x: 20, y: 50, width: 350, height: 80)
        
        let buttons = [
            ("选择", #selector(toggleSelection)),
            ("排除", #selector(toggleExclusion)),
            ("调试", #selector(toggleDebug)),
            ("分析", #selector(analyzePerformance))
        ]
        
        for (title, action) in buttons {
            let button = UIButton(type: .system)
            button.setTitle(title, for: .normal)
            button.backgroundColor = .systemBlue
            button.setTitleColor(.white, for: .normal)
            button.layer.cornerRadius = 8
            button.addTarget(self, action: action, for: .touchUpInside)
            controlPanel.addArrangedSubview(button)
        }
        
        view.addSubview(controlPanel)
    }
    
    private func setupTextSelection() {
        selectionManager.setupContainerView(textView)
        selectionManager.isSelectionEnabled = true
        selectionManager.selectionColor = UIColor.systemBlue.withAlphaComponent(0.3)
        selectionManager.delegate = self
    }
    
    private func setupExclusionPaths() {
        // 创建一些排除路径
        let rectPath = TEExclusionPath.rect(CGRect(x: 50, y: 150, width: 80, height: 80))
        let circlePath = TEExclusionPath.circle(center: CGPoint(x: 250, y: 250), radius: 50)
        textView.exclusionPaths = [rectPath, circlePath]
    }
    
    private func setupPerformanceMonitoring() {
        TEPerformanceProfiler.shared.startProfiling()
        
        var profilingOptions = TEProfilingOptions()
        profilingOptions.enableLayoutProfiling = true
        profilingOptions.enableRenderProfiling = true
        profilingOptions.enableMemoryProfiling = true
        profilingOptions.reportingInterval = 1.0
        
        TEPerformanceProfiler.shared.updateOptions(profilingOptions)
        TEPerformanceProfiler.shared.delegate = self
        
        // 定期更新状态
        Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { _ in
            self.updateStatus()
        }
    }
    
    @objc private func toggleSelection() {
        if selectionManager.isSelectionEnabled {
            selectionManager.isSelectionEnabled = false
            selectionManager.clearSelection()
            updateButtonTitle(at: 0, title: "启用选择")
        } else {
            selectionManager.isSelectionEnabled = true
            updateButtonTitle(at: 0, title: "禁用选择")
        }
    }
    
    @objc private func toggleExclusion() {
        if textView.exclusionPaths.isEmpty {
            setupExclusionPaths()
            updateButtonTitle(at: 1, title: "移除排除")
        } else {
            textView.exclusionPaths = []
            updateButtonTitle(at: 1, title: "添加排除")
        }
    }
    
    @objc private func toggleDebug() {
        // 简单的调试切换
        let button = controlPanel.arrangedSubviews[2] as! UIButton
        if button.backgroundColor == .systemBlue {
            enableDebugMode()
            updateButtonTitle(at: 2, title: "关闭调试")
        } else {
            disableDebugMode()
            updateButtonTitle(at: 2, title: "开启调试")
        }
    }
    
    @objc private func analyzePerformance() {
        // 执行性能分析
        DispatchQueue.global(qos: .userInitiated).async {
            let startTime = CACurrentMediaTime()
            
            // 分析布局性能
            let layoutMetrics = TEPerformanceProfiler.shared.profileLayout(
                self.textView.attributedText,
                containerSize: self.textView.bounds.size
            )
            
            // 分析渲染性能
            UIGraphicsBeginImageContextWithOptions(self.textView.bounds.size, false, 0)
            if let context = UIGraphicsGetCurrentContext() {
                let layout = TETextLayout()
                layout.attributedString = self.textView.attributedText
                layout.containerSize = self.textView.bounds.size
                
                let renderMetrics = TEPerformanceProfiler.shared.profileRender(layout, in: context)
                
                DispatchQueue.main.async {
                    self.showPerformanceResults(layoutMetrics: layoutMetrics, renderMetrics: renderMetrics)
                }
            }
            UIGraphicsEndImageContext()
            
            let endTime = CACurrentMediaTime()
            print("总分析时间: \(endTime - startTime)s")
        }
    }
    
    private func enableDebugMode() {
        // 这里可以添加实际的调试功能
        print("调试模式已启用")
    }
    
    private func disableDebugMode() {
        print("调试模式已禁用")
    }
    
    private func updateButtonTitle(at index: Int, title: String) {
        let button = controlPanel.arrangedSubviews[index] as! UIButton
        button.setTitle(title, for: .normal)
    }
    
    private func updateStatus() {
        let debugInfo = TETextDebugger.shared.getDebugInfo(for: textView)
        let report = TEPerformanceProfiler.shared.generateReport()
        
        let statusText = """
        📊 状态监控
        选择: \(selectionManager.isSelectionEnabled ? "启用" : "禁用")
        排除路径: \(textView.exclusionPaths.count) 个
        行数: \(debugInfo.layoutInfo.lineFragments.count)
        FPS: \(String(format: "%.1f", report.averageFPS))
        内存: \(formatBytes(report.totalMemoryUsage))
        """
        
        statusLabel.text = statusText
    }
    
    private func showPerformanceResults(
        layoutMetrics: TEPerformanceMetrics.LayoutMetrics,
        renderMetrics: TEPerformanceMetrics.RenderMetrics
    ) {
        let results = """
        📈 性能分析结果
        布局: \(String(format: "%.3f", layoutMetrics.layoutTime))s
        渲染: \(String(format: "%.3f", renderMetrics.renderTime))s
        行数: \(layoutMetrics.lineCount)
        缓存: \(layoutMetrics.cacheHit ? "命中" : "未命中")
        """
        
        statusLabel.text = results
        
        // 显示警告如果性能不佳
        if layoutMetrics.layoutTime > 0.016 || renderMetrics.renderTime > 0.016 {
            showPerformanceWarning()
        }
    }
    
    private func showPerformanceWarning() {
        let alert = UIAlertController(
            title: "性能警告",
            message: "检测到性能问题，建议优化文本内容或布局参数",
            preferredStyle: .alert
        )
        alert.addAction(UIAlertAction(title: "确定", style: .default))
        present(alert, animated: true)
    }
    
    private func formatBytes(_ bytes: Int) -> String {
        if bytes < 1024 {
            return "\(bytes)B"
        } else if bytes < 1024 * 1024 {
            return "\(bytes / 1024)KB"
        } else {
            return "\(bytes / (1024 * 1024))MB"
        }
    }
}

extension ComprehensiveDemoViewController: TETextSelectionManagerDelegate {
    func selectionManager(_ manager: TETextSelectionManager, didChangeSelection range: TETextSelectionRange?) {
        updateStatus()
    }
    
    func selectionManager(_ manager: TETextSelectionManager, shouldChangeSelection range: TETextSelectionRange?) -> Bool {
        return true
    }
}

extension ComprehensiveDemoViewController: TEPerformanceProfilerDelegate {
    func performanceProfiler(_ profiler: TEPerformanceProfiler, didGenerateReport report: TEPerformanceReport) {
        updateStatus()
    }
    
    func performanceProfiler(_ profiler: TEPerformanceProfiler, didDetectPerformanceIssue issue: TEPerformanceIssue) {
        print("检测到性能问题: \(issue)")
    }
}
```

这个综合示例展示了如何同时使用 TextEngineKit 的所有新功能，包括文本选择、排除路径、调试可视化和性能分析。您可以根据需要调整和扩展这些示例。