import Cocoa
import CoreImage

let payload = "TS-DQW4W9WGXCQ"
let outPath = CommandLine.arguments[1]

// MARK: - Barcode

let filter = CIFilter(name: "CICode128BarcodeGenerator")!
filter.setValue(payload.data(using: .ascii)!, forKey: "inputMessage")
filter.setValue(2.0, forKey: "inputQuietSpace")
let barcodeCI = filter.outputImage!.transformed(by: CGAffineTransform(scaleX: 6, y: 6))
let barcodeRep = NSCIImageRep(ciImage: barcodeCI)
let barcodeImage = NSImage(size: barcodeRep.size)
barcodeImage.addRepresentation(barcodeRep)

func drawCentered(_ text: String, in width: CGFloat, font: NSFont, color: NSColor, y: CGFloat) {
    let attrs: [NSAttributedString.Key: Any] = [.font: font, .foregroundColor: color]
    let s = NSAttributedString(string: text, attributes: attrs)
    s.draw(at: NSPoint(x: (width - s.size().width) / 2, y: y))
}

// MARK: - Sticker (label drawn in its own image, applied skewed later)

// Bars stay ~720pt wide so the viewfinder's aspect-fill crop leaves margins.
let stickerW: CGFloat = 880, stickerH: CGFloat = 700
let sticker = NSImage(size: NSSize(width: stickerW, height: stickerH))
sticker.lockFocus()
NSColor.white.setFill()
NSBezierPath(roundedRect: NSRect(x: 0, y: 0, width: stickerW, height: stickerH), xRadius: 14, yRadius: 14).fill()

let bw: CGFloat = 720, bh: CGFloat = 360
let bx = (stickerW - bw) / 2, by: CGFloat = 190
NSGraphicsContext.current?.imageInterpolation = .none
barcodeImage.draw(in: NSRect(x: bx, y: by, width: bw, height: bh),
                  from: .zero, operation: .sourceOver, fraction: 1.0)
NSGraphicsContext.current?.imageInterpolation = .high

drawCentered("ITEM TAG", in: stickerW,
             font: .systemFont(ofSize: 40, weight: .bold),
             color: NSColor(white: 0.45, alpha: 1.0), y: by + bh + 40)
drawCentered(payload, in: stickerW,
             font: .monospacedSystemFont(ofSize: 60, weight: .semibold),
             color: .black, y: by - 110)
sticker.unlockFocus()

// MARK: - Cardboard box face

let W: CGFloat = 1500, H: CGFloat = 2000
let canvas = NSImage(size: NSSize(width: W, height: H))
canvas.lockFocus()
NSGraphicsContext.current?.imageInterpolation = .high

// Kraft base with a soft vertical gradient
let kraftLight = NSColor(red: 0.78, green: 0.63, blue: 0.44, alpha: 1)
let kraftDark = NSColor(red: 0.68, green: 0.53, blue: 0.35, alpha: 1)
NSGradient(starting: kraftLight, ending: kraftDark)!
    .draw(in: NSRect(x: 0, y: 0, width: W, height: H), angle: -85)

// Corrugation: faint vertical striations
srand48(7)
for _ in 0..<140 {
    let x = CGFloat(drand48()) * W
    let alpha = 0.02 + CGFloat(drand48()) * 0.04
    let light = drand48() > 0.5
    NSColor(white: light ? 1 : 0, alpha: alpha).setFill()
    NSRect(x: x, y: 0, width: 2 + CGFloat(drand48()) * 4, height: H).fill()
}

// Darker edges so the face reads as one side of a box
let edgeShade = NSGradient(colors: [NSColor(white: 0, alpha: 0.28), NSColor(white: 0, alpha: 0.0)])!
edgeShade.draw(in: NSRect(x: 0, y: 0, width: 90, height: H), angle: 0)
edgeShade.draw(in: NSRect(x: W - 90, y: 0, width: 90, height: H), angle: 180)
edgeShade.draw(in: NSRect(x: 0, y: H - 110, width: W, height: 110), angle: -90)
edgeShade.draw(in: NSRect(x: 0, y: 0, width: W, height: 110), angle: 90)

// Top flap seam with packing tape running down from it
NSColor(white: 0, alpha: 0.18).setFill()
NSRect(x: 0, y: H - 340, width: W, height: 7).fill()
let tape = NSColor(red: 0.85, green: 0.76, blue: 0.60, alpha: 0.55)
tape.setFill()
NSRect(x: W / 2 - 110, y: H - 340, width: 220, height: 340).fill()
NSColor(white: 1, alpha: 0.12).setFill()
NSRect(x: W / 2 - 110, y: H - 340, width: 10, height: 340).fill()
NSRect(x: W / 2 + 100, y: H - 340, width: 10, height: 340).fill()

// Stamped shipping marks in dark ink
let ink = NSColor(red: 0.32, green: 0.23, blue: 0.14, alpha: 0.55)
let stampFont = NSFont.systemFont(ofSize: 54, weight: .heavy)
let stamp = NSAttributedString(string: "FRAGILE  ▲▲  THIS SIDE UP",
                               attributes: [.font: stampFont, .foregroundColor: ink])
stamp.draw(at: NSPoint(x: (W - stamp.size().width) / 2, y: 190))
let idStamp = NSAttributedString(string: "P/N 88-2261 · QTY 24",
                                 attributes: [.font: NSFont.monospacedSystemFont(ofSize: 40, weight: .bold),
                                              .foregroundColor: ink.withAlphaComponent(0.45)])
idStamp.draw(at: NSPoint(x: (W - idStamp.size().width) / 2, y: 110))

// MARK: - Sticker applied with a slight skew + shadow

if let ctx = NSGraphicsContext.current?.cgContext {
    ctx.saveGState()
    ctx.setShadow(offset: CGSize(width: 6, height: -14), blur: 26,
                  color: NSColor(white: 0, alpha: 0.35).cgColor)
    ctx.translateBy(x: W / 2, y: H / 2 + 130)
    ctx.rotate(by: -2.6 * .pi / 180)
    ctx.concatenate(CGAffineTransform(a: 1, b: 0, c: 0.045, d: 1, tx: 0, ty: 0))
    sticker.draw(in: NSRect(x: -stickerW / 2, y: -stickerH / 2, width: stickerW, height: stickerH),
                 from: .zero, operation: .sourceOver, fraction: 1.0)
    ctx.restoreGState()
}

canvas.unlockFocus()

// MARK: - Save

let tiff = canvas.tiffRepresentation!
let rep = NSBitmapImageRep(data: tiff)!
let png = rep.representation(using: .png, properties: [:])!
try! png.write(to: URL(fileURLWithPath: outPath))
print("wrote \(outPath)")
