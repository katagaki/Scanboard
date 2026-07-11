import SwiftUI
import UIKit

class KeyboardViewController: UIInputViewController {

    private let model = KeyboardModel()
    private var heightConstraint: NSLayoutConstraint?

    override func viewDidLoad() {
        super.viewDidLoad()

        let rootView = ScannerKeyboardView(
            model: model,
            insertText: { [weak self] text in
                self?.textDocumentProxy.insertText(text)
            },
            deleteBackward: { [weak self] in
                self?.textDocumentProxy.deleteBackward()
            },
            openScanner: { [weak self] in
                self?.openScannerApp()
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

        model.hasFullAccess = hasFullAccess
        if model.needsInputModeSwitchKey != needsInputModeSwitchKey {
            model.needsInputModeSwitchKey = needsInputModeSwitchKey
        }

        model.refresh()
        if let value = model.consumePendingScan() {
            textDocumentProxy.insertText(value)
            UIImpactFeedbackGenerator(style: .medium).impactOccurred()
        }
    }

    override func viewWillLayoutSubviews() {
        super.viewWillLayoutSubviews()

        if model.needsInputModeSwitchKey != needsInputModeSwitchKey {
            model.needsInputModeSwitchKey = needsInputModeSwitchKey
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

    // MARK: - Opening the Scanner App

    private func openScannerApp() {
        guard let url = URL(string: "scanboard://scan") else { return }
        model.markScanRequested()
        if let extensionContext {
            extensionContext.open(url) { [weak self] success in
                if !success {
                    Task { @MainActor [weak self] in
                        self?.openURLViaResponderChain(url)
                    }
                }
            }
        } else {
            openURLViaResponderChain(url)
        }
    }

    /// Keyboard extensions have no sanctioned way to open URLs, and
    /// `extensionContext.open` is not supported for the keyboard extension
    /// point. The deprecated `openURL:` selector is force-blocked by UIKit,
    /// so call the non-deprecated `open(_:options:completionHandler:)` —
    /// which is only compile-time unavailable in extensions — through its
    /// implementation pointer on the responder chain's UIApplication.
    private func openURLViaResponderChain(_ url: URL) {
        var responder: UIResponder? = self
        while let current = responder {
            if let application = current as? UIApplication {
                let selector = NSSelectorFromString("openURL:options:completionHandler:")
                guard application.responds(to: selector) else { return }
                typealias OpenURLFunction = @convention(c) (
                    AnyObject, Selector, NSURL, NSDictionary, AnyObject?
                ) -> Void
                let open = unsafeBitCast(application.method(for: selector), to: OpenURLFunction.self)
                open(application, selector, url as NSURL, [:] as NSDictionary, nil)
                return
            }
            responder = current.next
        }
    }
}
