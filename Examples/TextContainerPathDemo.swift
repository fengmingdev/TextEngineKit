import UIKit
import TextEngineKit

/// 文本容器路径功能演示
class TextContainerPathDemoViewController: UIViewController {
    
    // MARK: - UI 组件
    
    /// 标准矩形文本视图
    private let standardTextView: TETextView = {
        let textView = TETextView()
        textView.backgroundColor = .systemBackground
        textView.layer.borderColor = UIColor.systemGray3.cgColor
        textView.layer.borderWidth = 1
        textView.layer.cornerRadius = 8
        return textView
    }()
    
    /// 圆形文本视图
    private let circularTextView: TETextView = {
        let textView = TETextView()
        textView.backgroundColor = .systemBackground
        textView.layer.borderColor = UIColor.systemBlue.cgColor
        textView.layer.borderWidth = 2
        textView.layer.cornerRadius = 75 // 150/2
        return textView
    }()
    
    /// 星形文本视图
    private let starTextView: TETextView = {
        let textView = TETextView()
        textView.backgroundColor = .systemBackground
        textView.layer.borderColor = UIColor.systemPurple.cgColor
        textView.layer.borderWidth = 2
        return textView
    }()
    
    /// 波浪形文本视图
    private let waveTextView: TETextView = {
        let textView = TETextView()
        textView.backgroundColor = .systemBackground
        textView.layer.borderColor = UIColor.systemGreen.cgColor
        textView.layer.borderWidth = 2
        return textView
    }()
    
    /// 排除路径文本视图
    private let exclusionTextView: TETextView = {
        let textView = TETextView()
        textView.backgroundColor = .systemBackground
        textView.layer.borderColor = UIColor.systemOrange.cgColor
        textView.layer.borderWidth = 2
        return textView
    }()
    
    /// 标题标签
    private let titleLabel: UILabel = {
        let label = UILabel()
        label.text = "文本容器路径演示"
        label.font = .systemFont(ofSize: 24, weight: .bold)
        label.textAlignment = .center
        return label
    }()
    
    /// 滚动视图
    private let scrollView: UIScrollView = {
        let scrollView = UIScrollView()
        scrollView.showsVerticalScrollIndicator = true
        scrollView.showsHorizontalScrollIndicator = false
        return scrollView
    }()
    
    /// 内容视图
    private let contentView = UIView()
    
    // MARK: - 生命周期
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        configureTextViews()
        addSampleData()
    }
    
    // MARK: - UI 设置
    
    private func setupUI() {
        view.backgroundColor = .systemBackground
        
        // 添加滚动视图
        view.addSubview(scrollView)
        scrollView.addSubview(contentView)
        
        // 添加标题
        contentView.addSubview(titleLabel)
        
        // 添加文本视图
        contentView.addSubview(standardTextView)
        contentView.addSubview(circularTextView)
        contentView.addSubview(starTextView)
        contentView.addSubview(waveTextView)
        contentView.addSubview(exclusionTextView)
        
        // 设置约束
        setupConstraints()
    }
    
    private func setupConstraints() {
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        contentView.translatesAutoresizingMaskIntoConstraints = false
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        standardTextView.translatesAutoresizingMaskIntoConstraints = false
        circularTextView.translatesAutoresizingMaskIntoConstraints = false
        starTextView.translatesAutoresizingMaskIntoConstraints = false
        waveTextView.translatesAutoresizingMaskIntoConstraints = false
        exclusionTextView.translatesAutoresizingMaskIntoConstraints = false
        
        NSLayoutConstraint.activate([
            // 滚动视图约束
            scrollView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            scrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            scrollView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            
            // 内容视图约束
            contentView.topAnchor.constraint(equalTo: scrollView.topAnchor),
            contentView.leadingAnchor.constraint(equalTo: scrollView.leadingAnchor),
            contentView.trailingAnchor.constraint(equalTo: scrollView.trailingAnchor),
            contentView.bottomAnchor.constraint(equalTo: scrollView.bottomAnchor),
            contentView.widthAnchor.constraint(equalTo: scrollView.widthAnchor),
            
            // 标题约束
            titleLabel.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 20),
            titleLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 20),
            titleLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -20),
            
            // 标准文本视图约束
            standardTextView.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 20),
            standardTextView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 20),
            standardTextView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -20),
            standardTextView.heightAnchor.constraint(equalToConstant: 100),
            
            // 圆形文本视图约束
            circularTextView.topAnchor.constraint(equalTo: standardTextView.bottomAnchor, constant: 20),
            circularTextView.centerXAnchor.constraint(equalTo: contentView.centerXAnchor),
            circularTextView.widthAnchor.constraint(equalToConstant: 150),
            circularTextView.heightAnchor.constraint(equalToConstant: 150),
            
            // 星形文本视图约束
            starTextView.topAnchor.constraint(equalTo: circularTextView.bottomAnchor, constant: 20),
            starTextView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 20),
            starTextView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -20),
            starTextView.heightAnchor.constraint(equalToConstant: 120),
            
            // 波浪形文本视图约束
            waveTextView.topAnchor.constraint(equalTo: starTextView.bottomAnchor, constant: 20),
            waveTextView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 20),
            waveTextView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -20),
            waveTextView.heightAnchor.constraint(equalToConstant: 100),
            
            // 排除路径文本视图约束
            exclusionTextView.topAnchor.constraint(equalTo: waveTextView.bottomAnchor, constant: 20),
            exclusionTextView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 20),
            exclusionTextView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -20),
            exclusionTextView.heightAnchor.constraint(equalToConstant: 150),
            exclusionTextView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -20)
        ])
    }
    
    // MARK: - 文本视图配置
    
    private func configureTextViews() {
        // 配置标准矩形文本视图
        configureStandardTextView()
        
        // 配置圆形文本视图
        configureCircularTextView()
        
        // 配置星形文本视图
        configureStarTextView()
        
        // 配置波浪形文本视图
        configureWaveTextView()
        
        // 配置排除路径文本视图
        configureExclusionTextView()
    }
    
    private func configureStandardTextView() {
        // 标准矩形，使用默认配置
        standardTextView.text = "这是一个标准的矩形文本容器。文本会在矩形区域内正常布局。"
        standardTextView.font = .systemFont(ofSize: 16)
        standardTextView.textColor = .label
    }
    
    private func configureCircularTextView() {
        // 创建圆形路径
        let center = CGPoint(x: 75, y: 75) // 相对于150x150的视图
        let radius: CGFloat = 60
        circularTextView.setCircularTextContainer(center: center, radius: radius)
        
        circularTextView.text = "这是在一个圆形路径中的文本内容。文本会沿着圆形的边界进行布局，创造出独特的视觉效果。"
        circularTextView.font = .systemFont(ofSize: 14)
        circularTextView.textColor = .systemBlue
        circularTextView.textAlignment = .center
    }
    
    private func configureStarTextView() {
        // 创建星形路径
        let center = CGPoint(x: 160, y: 60) // 相对于320x120的视图
        let starPath = TEPathUtilities.createStarPath(center: center, points: 5, outerRadius: 50, innerRadius: 25)
        
        let container = TETextContainer()
        container.size = CGSize(width: 320, height: 120)
        container.path = starPath
        starTextView.textContainer = container
        
        starTextView.text = "这是一个星形路径中的文本。文本会在星形的内部区域进行布局，创造出有趣的视觉效果。"
        starTextView.font = .systemFont(ofSize: 14)
        starTextView.textColor = .systemPurple
        starTextView.textAlignment = .center
    }
    
    private func configureWaveTextView() {
        // 创建波浪形路径
        let waveRect = CGRect(x: 0, y: 0, width: 320, height: 100)
        let wavePath = TEPathUtilities.createWavePath(rect: waveRect, amplitude: 20, frequency: 0.05)
        
        let container = TETextContainer()
        container.size = CGSize(width: 320, height: 100)
        container.path = wavePath
        waveTextView.textContainer = container
        
        waveTextView.text = "这是波浪形路径中的文本内容。文本会沿着波浪的曲线进行布局，创造出流动的视觉效果。"
        waveTextView.font = .systemFont(ofSize: 14)
        waveTextView.textColor = .systemGreen
        waveTextView.textAlignment = .center
    }
    
    private func configureExclusionTextView() {
        // 创建主要容器路径
        let container = TETextContainer()
        container.size = CGSize(width: 320, height: 150)
        
        // 创建排除路径（模拟图片区域）
        let imageRect = CGRect(x: 120, y: 25, width: 80, height: 100)
        let exclusionPath = TEPathUtilities.createExclusionPath(rect: imageRect, cornerRadius: 10)
        container.addExclusionPath(exclusionPath)
        
        exclusionTextView.textContainer = container
        
        exclusionTextView.text = "这是一个包含排除路径的文本容器示例。文本会绕过中间的排除区域进行布局，常用于图文混排的场景。文本会在排除区域的周围流动，创造出专业的排版效果。"
        exclusionTextView.font = .systemFont(ofSize: 14)
        exclusionTextView.textColor = .systemOrange
        exclusionTextView.textAlignment = .natural
    }
    
    // MARK: - 示例数据
    
    private func addSampleData() {
        // 可以在这里添加更多的示例文本内容
        let sampleTexts = [
            "TextEngineKit 提供了强大的文本容器路径功能，支持各种复杂的路径形状。",
            "通过使用 TETextContainer，您可以创建圆形、星形、波浪形等各种文本布局效果。",
            "排除路径功能让文本能够智能地绕过图片、按钮等元素进行布局。",
            "这些功能为 iOS 应用带来了专业级的文本排版能力。"
        ]
        
        // 可以随机选择文本或添加更多内容
        TETextEngine.shared.logInfo("添加了示例数据到文本视图", category: "demo")
    }
    
    // MARK: - 交互功能
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let touch = touches.first else { return }
        let location = touch.location(in: view)
        
        // 检查点击了哪个文本视图
        if circularTextView.frame.contains(location) {
            handleCircularTextViewTap()
        } else if starTextView.frame.contains(location) {
            handleStarTextViewTap()
        } else if waveTextView.frame.contains(location) {
            handleWaveTextViewTap()
        } else if exclusionTextView.frame.contains(location) {
            handleExclusionTextViewTap()
        }
    }
    
    private func handleCircularTextViewTap() {
        // 切换圆形文本视图的颜色
        let colors: [UIColor] = [.systemBlue, .systemRed, .systemGreen, .systemPurple]
        let currentColor = circularTextView.textColor ?? .systemBlue
        let currentIndex = colors.firstIndex(of: currentColor) ?? 0
        let nextIndex = (currentIndex + 1) % colors.count
        
        circularTextView.textColor = colors[nextIndex]
        
        // 记录统计信息
        if let statistics = circularTextView.getTextContainerStatistics() {
            TETextEngine.shared.logDebug("圆形文本容器统计: \(statistics.description)", category: "demo")
        }
    }
    
    private func handleStarTextViewTap() {
        // 切换星形点数
        let center = CGPoint(x: 160, y: 60)
        let points = [5, 6, 8, 10]
        let randomPoints = points.randomElement() ?? 5
        
        let starPath = TEPathUtilities.createStarPath(center: center, points: randomPoints, outerRadius: 50, innerRadius: 25)
        starTextView.textContainer?.path = starPath
        starTextView.setNeedsLayout()
        
        TETextEngine.shared.logDebug("星形文本容器切换到 \(randomPoints) 个点", category: "demo")
    }
    
    private func handleWaveTextViewTap() {
        // 切换波浪参数
        let amplitudes: [CGFloat] = [10, 20, 30, 40]
        let frequencies: [CGFloat] = [0.02, 0.05, 0.08, 0.1]
        
        let amplitude = amplitudes.randomElement() ?? 20
        let frequency = frequencies.randomElement() ?? 0.05
        
        let waveRect = CGRect(x: 0, y: 0, width: 320, height: 100)
        let wavePath = TEPathUtilities.createWavePath(rect: waveRect, amplitude: amplitude, frequency: frequency)
        
        waveTextView.textContainer?.path = wavePath
        waveTextView.setNeedsLayout()
        
        TETextEngine.shared.logDebug("波浪文本容器切换到振幅 \(amplitude), 频率 \(frequency)", category: "demo")
    }
    
    private func handleExclusionTextViewTap() {
        // 移动排除路径位置
        let randomX = CGFloat.random(in: 50...170)
        let randomY = CGFloat.random(in: 10...40)
        
        let imageRect = CGRect(x: randomX, y: randomY, width: 80, height: 100)
        let exclusionPath = TEPathUtilities.createExclusionPath(rect: imageRect, cornerRadius: 10)
        
        exclusionTextView.clearExclusionPaths()
        exclusionTextView.addExclusionPath(exclusionPath)
        
        TETextEngine.shared.logDebug("排除路径移动到位置: \(NSStringFromCGRect(imageRect))", category: "demo")
    }
}

/// 演示应用委托
class TextContainerPathDemoAppDelegate: NSObject, UIApplicationDelegate {
    
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        // 启用性能日志
        TETextEngine.shared.enablePerformanceLogging = true
        
        // 创建窗口和根视图控制器
        let window = UIWindow(frame: UIScreen.main.bounds)
        let demoViewController = TextContainerPathDemoViewController()
        let navigationController = UINavigationController(rootViewController: demoViewController)
        
        window.rootViewController = navigationController
        window.makeKeyAndVisible()
        
        return true
    }
}

/// 使用说明
/*
 文本容器路径演示应用使用说明：
 
 1. 标准矩形文本容器
    - 展示基本的矩形文本布局
    - 这是默认的文本容器类型
 
 2. 圆形文本容器
    - 文本沿着圆形路径布局
    - 点击可以切换文本颜色
    - 查看控制台可以获取统计信息
 
 3. 星形文本容器
    - 文本在星形内部布局
    - 点击可以切换星形的点数
    - 展示复杂路径的文本布局效果
 
 4. 波浪形文本容器
    - 文本沿着波浪曲线布局
    - 点击可以随机改变波浪的振幅和频率
    - 展示动态路径变化效果
 
 5. 排除路径文本容器
    - 文本会绕过中间的排除区域
    - 点击可以移动排除区域的位置
    - 模拟图文混排的真实场景
 
 技术特点：
 - 支持异步布局和渲染
 - 提供详细的性能统计
 - 集成 FMLogger 日志系统
 - 线程安全的实现
 - 支持 CoreText 框架
 
 性能优化：
 - 使用 NSCache 进行布局缓存
 - 支持并发布局计算
 - 智能的缓存键生成
 - 内存友好的实现
 
 扩展性：
 - 易于添加新的路径类型
 - 支持自定义路径操作
 - 提供丰富的路径工具类
 - 模块化的架构设计
 */