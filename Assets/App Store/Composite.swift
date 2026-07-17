import Cocoa

// Usage: composite <screenshot> <out> <headline> <subline> <topHex> <bottomHex>
let args = CommandLine.arguments
let shotPath = args[1], outPath = args[2]
let headline = args[3], subline = args[4]

func color(_ hex: String) -> NSColor {
    var v: UInt64 = 0
    Scanner(string: String(hex.dropFirst())).scanHexInt64(&v)
    return NSColor(red: CGFloat((v >> 16) & 0xFF) / 255,
                   green: CGFloat((v >> 8) & 0xFF) / 255,
                   blue: CGFloat(v & 0xFF) / 255, alpha: 1)
}
let topColor = color(args[5]), bottomColor = color(args[6])

guard let shot = NSImage(contentsOfFile: shotPath) else { fatalError("no screenshot") }
let shotRep = shot.representations[0]
let shotPx = NSSize(width: shotRep.pixelsWide, height: shotRep.pixelsHigh) // 1206x2622

// App Store 6.9-inch portrait canvas
let W: CGFloat = 1320, H: CGFloat = 2868

let canvas = NSImage(size: NSSize(width: W, height: H))
canvas.lockFocus()
NSGraphicsContext.current?.imageInterpolation = .high

// 1. Gradient background (diagonal, light at top-left)
NSGradient(starting: topColor, ending: bottomColor)!
    .draw(in: NSRect(x: 0, y: 0, width: W, height: H), angle: -70)

// 2. Device frame geometry
let screenW: CGFloat = 1000
let screenH = screenW * shotPx.height / shotPx.width       // ~2174
let bezel: CGFloat = 22
let bodyW = screenW + bezel * 2, bodyH = screenH + bezel * 2
let bodyX = (W - bodyW) / 2
let bodyY: CGFloat = 120                                    // bottom margin
let bodyRadius: CGFloat = 172
let screenRadius: CGFloat = 150

// Soft drop shadow behind the device
let shadow = NSShadow()
shadow.shadowColor = NSColor.black.withAlphaComponent(0.38)
shadow.shadowBlurRadius = 70
shadow.shadowOffset = NSSize(width: 0, height: -34)
NSGraphicsContext.saveGraphicsState()
shadow.set()
let bodyRect = NSRect(x: bodyX, y: bodyY, width: bodyW, height: bodyH)
let bodyPath = NSBezierPath(roundedRect: bodyRect, xRadius: bodyRadius, yRadius: bodyRadius)
NSColor.black.setFill()
bodyPath.fill()
NSGraphicsContext.restoreGraphicsState()

// Polished frame edge highlight
let edgePath = NSBezierPath(roundedRect: bodyRect.insetBy(dx: 2, dy: 2), xRadius: bodyRadius - 2, yRadius: bodyRadius - 2)
edgePath.lineWidth = 3
NSColor(white: 1.0, alpha: 0.28).setStroke()
edgePath.stroke()

// 3. Screenshot clipped to the screen area
let screenRect = NSRect(x: bodyX + bezel, y: bodyY + bezel, width: screenW, height: screenH)
NSGraphicsContext.saveGraphicsState()
NSBezierPath(roundedRect: screenRect, xRadius: screenRadius, yRadius: screenRadius).addClip()
shot.draw(in: screenRect, from: .zero, operation: .sourceOver, fraction: 1.0)
NSGraphicsContext.restoreGraphicsState()

// 4. Dynamic Island pill (proportions measured from the 1206x2622 capture)
let islandW = screenW * 0.3117
let islandH = screenH * 0.0332
let islandTopOffset = screenH * 0.0198
let islandRect = NSRect(x: screenRect.midX - islandW / 2,
                        y: screenRect.maxY - islandTopOffset - islandH,
                        width: islandW, height: islandH)
NSColor.black.setFill()
NSBezierPath(roundedRect: islandRect, xRadius: islandH / 2, yRadius: islandH / 2).fill()

// 5. Captions above the device
func drawCentered(_ text: String, font: NSFont, color: NSColor, y: CGFloat) {
    let style = NSMutableParagraphStyle()
    style.alignment = .center
    let s = NSAttributedString(string: text, attributes: [
        .font: font, .foregroundColor: color, .paragraphStyle: style,
    ])
    let size = s.size()
    s.draw(at: NSPoint(x: (W - size.width) / 2, y: y))
}

func displayFont(_ postScriptName: String, _ size: CGFloat, fallbackWeight: NSFont.Weight) -> NSFont {
    NSFont(name: postScriptName, size: size) ?? .systemFont(ofSize: size, weight: fallbackWeight)
}

let deviceTop = bodyY + bodyH
let capZone = H - deviceTop                                  // ~530
let headlineY = deviceTop + capZone * 0.47
drawCentered(headline,
             font: displayFont("SFProDisplay-Bold", 96, fallbackWeight: .bold),
             color: color("#1D1D1F"),
             y: headlineY)
drawCentered(subline,
             font: displayFont("SFProDisplay-Medium", 46, fallbackWeight: .medium),
             color: NSColor(red: 60 / 255, green: 60 / 255, blue: 67 / 255, alpha: 0.80),
             y: headlineY - 85)

canvas.unlockFocus()

// Save at exact pixel size
let rep = NSBitmapImageRep(bitmapDataPlanes: nil, pixelsWide: Int(W), pixelsHigh: Int(H),
                           bitsPerSample: 8, samplesPerPixel: 4, hasAlpha: true, isPlanar: false,
                           colorSpaceName: .deviceRGB, bytesPerRow: 0, bitsPerPixel: 0)!
rep.size = NSSize(width: W, height: H)
NSGraphicsContext.saveGraphicsState()
NSGraphicsContext.current = NSGraphicsContext(bitmapImageRep: rep)
canvas.draw(in: NSRect(x: 0, y: 0, width: W, height: H), from: .zero, operation: .copy, fraction: 1.0)
NSGraphicsContext.restoreGraphicsState()
try! rep.representation(using: .png, properties: [:])!.write(to: URL(fileURLWithPath: outPath))
print("wrote \(outPath)")
