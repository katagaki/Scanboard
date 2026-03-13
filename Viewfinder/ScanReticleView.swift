// ScanReticleView.swift  (Keyboard Extension target)

import UIKit

class ScanReticleView: UIView {

    private let cornerLength: CGFloat = 16
    private let cornerWidth:  CGFloat = 3
    private let scanLine = UIView()

    override init(frame: CGRect) { super.init(frame: frame); setup() }
    required init?(coder: NSCoder) { super.init(coder: coder); setup() }

    private func setup() {
        backgroundColor = .clear
        scanLine.backgroundColor = UIColor(red: 0.18, green: 0.75, blue: 0.36, alpha: 0.85)
        scanLine.translatesAutoresizingMaskIntoConstraints = false
        addSubview(scanLine)
        NSLayoutConstraint.activate([
            scanLine.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 4),
            scanLine.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -4),
            scanLine.heightAnchor.constraint(equalToConstant: 2),
            scanLine.centerYAnchor.constraint(equalTo: centerYAnchor)
        ])
    }

    override func draw(_ rect: CGRect) {
        guard let ctx = UIGraphicsGetCurrentContext() else { return }
        UIColor(red: 0.18, green: 0.75, blue: 0.36, alpha: 1).setStroke()
        ctx.setLineWidth(cornerWidth)
        ctx.setLineCap(.round)
        let (minX, minY, maxX, maxY, l) = (rect.minX, rect.minY, rect.maxX, rect.maxY, cornerLength)
        ctx.move(to: CGPoint(x: minX, y: minY + l)); ctx.addLine(to: CGPoint(x: minX, y: minY)); ctx.addLine(to: CGPoint(x: minX + l, y: minY))
        ctx.move(to: CGPoint(x: maxX - l, y: minY)); ctx.addLine(to: CGPoint(x: maxX, y: minY)); ctx.addLine(to: CGPoint(x: maxX, y: minY + l))
        ctx.move(to: CGPoint(x: minX, y: maxY - l)); ctx.addLine(to: CGPoint(x: minX, y: maxY)); ctx.addLine(to: CGPoint(x: minX + l, y: maxY))
        ctx.move(to: CGPoint(x: maxX - l, y: maxY)); ctx.addLine(to: CGPoint(x: maxX, y: maxY)); ctx.addLine(to: CGPoint(x: maxX, y: maxY - l))
        ctx.strokePath()
    }

    func startAnimating() {
        scanLine.isHidden = false
        let anim = CABasicAnimation(keyPath: "position.y")
        anim.fromValue = cornerLength
        anim.toValue = (bounds.height > 0 ? bounds.height : 60) - cornerLength
        anim.duration = 1.4
        anim.autoreverses = true
        anim.repeatCount = .infinity
        anim.timingFunction = CAMediaTimingFunction(name: .easeInEaseOut)
        scanLine.layer.add(anim, forKey: "scan")
    }

    func stopAnimating() {
        scanLine.layer.removeAllAnimations()
        scanLine.isHidden = true
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        setNeedsDisplay()
    }
}
