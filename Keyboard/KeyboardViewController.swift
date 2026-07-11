import SwiftUI
import UIKit

class KeyboardViewController: UIInputViewController {

    private let scanner = KeyboardScanner()
    private var heightConstraint: NSLayoutConstraint?

    override func viewDidLoad() {
        super.viewDidLoad()

        scanner.onScan = { [weak self] value in
            self?.textDocumentProxy.insertText(value)
            UIImpactFeedbackGenerator(style: .medium).impactOccurred()
        }

        let rootView = ScannerKeyboardView(
            scanner: scanner,
            insertText: { [weak self] text in
                self?.textDocumentProxy.insertText(text)
            },
            deleteBackward: { [weak self] in
                self?.textDocumentProxy.deleteBackward()
            },
            configureInputModeSwitchButton: { [weak self] button in
                guard let self else { return }
                button.addTarget(
                    self,
                    action: #selector(self.handleInputModeList(from:with:)),
                    for: .allTouchEvents
                )
            }
        )

        let host = UIHostingController(rootView: rootView)
        host.view.backgroundColor = .clear
        addChild(host)
        view.addSubview(host.view)
        host.view.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            host.view.topAnchor.constraint(equalTo: view.topAnchor),
            host.view.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            host.view.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            host.view.trailingAnchor.constraint(equalTo: view.trailingAnchor),
        ])
        host.didMove(toParent: self)
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        scanner.hasFullAccess = hasFullAccess
        if scanner.needsInputModeSwitchKey != needsInputModeSwitchKey {
            scanner.needsInputModeSwitchKey = needsInputModeSwitchKey
        }
        scanner.start()
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        scanner.stop()
    }

    override func viewWillLayoutSubviews() {
        super.viewWillLayoutSubviews()

        if scanner.needsInputModeSwitchKey != needsInputModeSwitchKey {
            scanner.needsInputModeSwitchKey = needsInputModeSwitchKey
        }

        if heightConstraint == nil {
            let constraint = view.heightAnchor.constraint(equalToConstant: 300)
            constraint.priority = UILayoutPriority(999)
            constraint.isActive = true
            heightConstraint = constraint
        }
        let targetHeight: CGFloat = traitCollection.verticalSizeClass == .compact ? 210 : 300
        if heightConstraint?.constant != targetHeight {
            heightConstraint?.constant = targetHeight
        }
    }
}
