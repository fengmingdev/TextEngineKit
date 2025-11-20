import Foundation
#if canImport(UIKit)
import UIKit

public final class ShowcaseDemoViewController: UIViewController {
    private let demoLabel = TELabel()
    private let demoTextView = TETextView()
    private let verticalView = TEVerticalTextView()
    public override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .systemBackground
        setupLabel()
        setupTextView()
        setupVertical()
        layoutUI()
    }
    private func setupLabel() {
        demoLabel.preferAsyncRendering = true
        demoLabel.enableAsyncRendering = true
        let parser = TECompositeParser.defaultParser()
        let text = parser.parse("异步渲染与高亮 [示例](https://example.com) :smile:")
        demoLabel.attributedText = text
        let hl = TETextHighlight(color: .systemBlue, backgroundColor: .systemGray5)
        demoLabel.setTextHighlight(hl, range: NSRange(location: 6, length: 4))
    }
    private func setupTextView() {
        demoTextView.enableAsyncRendering = true
        demoTextView.autoDisableAsyncWhenEditing = true
        demoTextView.isParsingEnabled = true
        demoTextView.parser = TECompositeParser.defaultParser()
        demoTextView.text = "电话: 123-4567, 链接: https://apple.com, 列表:\n- 项目A\n- 项目B"
        let ex = TEPathUtilities.createExclusionPath(rect: CGRect(x: 20, y: 10, width: 80, height: 40), cornerRadius: 8)
        demoTextView.addExclusionPath(ex)
        demoTextView.placeholder = "请输入..."
    }
    private func setupVertical() {
        verticalView.layoutOptions = [.rotateCharacters, .rightToLeft]
        verticalView.enableAsyncLayout = true
        verticalView.enableAsyncRendering = true
        let attr = NSAttributedString(string: "垂直文本ABC，测试旋转与列布局。")
        verticalView.attributedText = attr
    }
    private func layoutUI() {
        [demoLabel, demoTextView, verticalView].forEach { v in
            v.translatesAutoresizingMaskIntoConstraints = false
            view.addSubview(v)
        }
        NSLayoutConstraint.activate([
            demoLabel.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 16),
            demoLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            demoLabel.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),
            demoLabel.heightAnchor.constraint(equalToConstant: 60),
            demoTextView.topAnchor.constraint(equalTo: demoLabel.bottomAnchor, constant: 16),
            demoTextView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            demoTextView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),
            demoTextView.heightAnchor.constraint(equalToConstant: 160),
            verticalView.topAnchor.constraint(equalTo: demoTextView.bottomAnchor, constant: 16),
            verticalView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            verticalView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),
            verticalView.bottomAnchor.constraint(lessThanOrEqualTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -16),
            verticalView.heightAnchor.constraint(equalToConstant: 200)
        ])
    }
}
#endif
