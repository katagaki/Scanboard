// BarcodeScannerView.swift  (Keyboard Extension target)
// The keyboard's visual UI — camera preview, scan reticle, result button.

import UIKit
import AVFoundation

class BarcodeScannerView: UIView {

    // MARK: - Callbacks
    var onInsertTapped: ((String) -> Void)?
    var onRescanTapped: (() -> Void)?

    // MARK: - Subviews

    let previewContainer: UIView = {
        let v = UIView()
        v.backgroundColor = .black
        v.clipsToBounds = true
        return v
    }()

    private let reticleView = ScanReticleView()

    private let statusLabel: UILabel = {
        let l = UILabel()
        l.text = "Point at a barcode"
        l.textColor = .white
        l.font = .monospacedSystemFont(ofSize: 13, weight: .medium)
        l.textAlignment = .center
        l.backgroundColor = UIColor.black.withAlphaComponent(0.55)
        l.layer.cornerRadius = 8
        l.clipsToBounds = true
        return l
    }()

    private let resultButton: UIButton = {
        var config = UIButton.Configuration.filled()
        config.cornerStyle = .medium
        config.baseBackgroundColor = UIColor(red: 0.18, green: 0.75, blue: 0.36, alpha: 1)
        config.baseForegroundColor = .white
        config.contentInsets = NSDirectionalEdgeInsets(top: 10, leading: 16, bottom: 10, trailing: 16)
        let b = UIButton(configuration: config)
        b.isHidden = true
        return b
    }()

    private let typeLabel: UILabel = {
        let l = UILabel()
        l.font = .monospacedSystemFont(ofSize: 11, weight: .regular)
        l.textColor = UIColor.white.withAlphaComponent(0.65)
        l.textAlignment = .center
        l.isHidden = true
        return l
    }()

    private let rescanButton: UIButton = {
        var config = UIButton.Configuration.gray()
        config.title = "Scan Again"
        config.cornerStyle = .medium
        config.baseForegroundColor = .white
        config.baseBackgroundColor = UIColor.white.withAlphaComponent(0.18)
        config.contentInsets = NSDirectionalEdgeInsets(top: 8, leading: 14, bottom: 8, trailing: 14)
        let b = UIButton(configuration: config)
        b.isHidden = true
        return b
    }()

    private var detectedValue: String?

    // MARK: - Init

    override init(frame: CGRect) { super.init(frame: frame); setup() }
    required init?(coder: NSCoder) { super.init(coder: coder); setup() }

    private func setup() {
        backgroundColor = .black
        [previewContainer, reticleView, statusLabel,
         resultButton, typeLabel, rescanButton].forEach {
            $0.translatesAutoresizingMaskIntoConstraints = false
            addSubview($0)
        }

        NSLayoutConstraint.activate([
            previewContainer.topAnchor.constraint(equalTo: topAnchor),
            previewContainer.leadingAnchor.constraint(equalTo: leadingAnchor),
            previewContainer.trailingAnchor.constraint(equalTo: trailingAnchor),
            previewContainer.bottomAnchor.constraint(equalTo: bottomAnchor),

            reticleView.centerXAnchor.constraint(equalTo: centerXAnchor),
            reticleView.centerYAnchor.constraint(equalTo: centerYAnchor, constant: -10),
            reticleView.widthAnchor.constraint(equalTo: widthAnchor, multiplier: 0.75),
            reticleView.heightAnchor.constraint(equalToConstant: 60),

            statusLabel.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -10),
            statusLabel.centerXAnchor.constraint(equalTo: centerXAnchor),
            statusLabel.widthAnchor.constraint(lessThanOrEqualTo: widthAnchor, multiplier: 0.9),
            statusLabel.heightAnchor.constraint(equalToConstant: 28),

            resultButton.centerXAnchor.constraint(equalTo: centerXAnchor),
            resultButton.centerYAnchor.constraint(equalTo: centerYAnchor, constant: -8),

            typeLabel.bottomAnchor.constraint(equalTo: resultButton.topAnchor, constant: -6),
            typeLabel.centerXAnchor.constraint(equalTo: centerXAnchor),

            rescanButton.topAnchor.constraint(equalTo: resultButton.bottomAnchor, constant: 8),
            rescanButton.centerXAnchor.constraint(equalTo: centerXAnchor)
        ])

        resultButton.addTarget(self, action: #selector(insertTapped), for: .touchUpInside)
        rescanButton.addTarget(self, action: #selector(rescanTapped), for: .touchUpInside)
    }

    // MARK: - State Transitions

    func showScanning() {
        reticleView.isHidden = false
        reticleView.startAnimating()
        statusLabel.isHidden = false
        statusLabel.text = "Point at a barcode"
        resultButton.isHidden = true
        typeLabel.isHidden = true
        rescanButton.isHidden = true
    }

    func showResult(_ value: String, type: AVMetadataObject.ObjectType) {
        detectedValue = value
        reticleView.stopAnimating()
        reticleView.isHidden = true
        statusLabel.isHidden = true

        let display = value.count > 30 ? String(value.prefix(27)) + "…" : value
        var config = resultButton.configuration
        config?.title = "Insert  \"\(display)\""
        config?.image = UIImage(systemName: "keyboard")
        config?.imagePadding = 6
        resultButton.configuration = config
        resultButton.isHidden = false

        typeLabel.text = Self.friendlyName(type)
        typeLabel.isHidden = false
        rescanButton.isHidden = false
    }

    func showPermissionDenied() {
        statusLabel.text = "⚠️ Camera denied — open the main app to grant access"
        statusLabel.isHidden = false
        reticleView.isHidden = true
    }

    func showError(_ message: String) {
        statusLabel.text = "⚠️ \(message)"
        statusLabel.isHidden = false
        reticleView.isHidden = true
    }

    // MARK: - Actions

    @objc private func insertTapped() {
        guard let v = detectedValue else { return }
        onInsertTapped?(v)
    }

    @objc private func rescanTapped() {
        detectedValue = nil
        onRescanTapped?()
    }

    private static func friendlyName(_ type: AVMetadataObject.ObjectType) -> String {
        switch type {
        case .code128: return "Code 128"
        case .code39:  return "Code 39"
        case .code93:  return "Code 93"
        case .itf14:   return "ITF-14"
        case .ean13:   return "EAN-13"
        case .ean8:    return "EAN-8"
        case .upce:    return "UPC-E"
        case .pdf417:  return "PDF417"
        case .qr:      return "QR Code"
        case .dataMatrix: return "Data Matrix"
        default:       return "Barcode"
        }
    }
}
