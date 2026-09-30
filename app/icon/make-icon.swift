// Draws the MacPlay app icon and packs it into AppIcon.icns.
// Usage (from app/):  swift icon/make-icon.swift
// Everything is drawn on a 1024-unit canvas and rendered at each size, so small
// sizes stay sharp. Shapes are drawn by hand: SF Symbols may not be used in icons.
import AppKit

let canvas: CGFloat = 1024
let colorSpace = CGColorSpace(name: CGColorSpace.sRGB)!

func color(_ hex: UInt32, _ alpha: CGFloat = 1) -> CGColor {
    CGColor(colorSpace: colorSpace, components: [
        CGFloat((hex >> 16) & 0xFF) / 255, CGFloat((hex >> 8) & 0xFF) / 255, CGFloat(hex & 0xFF) / 255, alpha,
    ])!
}

func makeContext(_ pixels: Int) -> CGContext {
    let ctx = CGContext(data: nil, width: pixels, height: pixels, bitsPerComponent: 8, bytesPerRow: 0,
                        space: colorSpace, bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue)!
    ctx.scaleBy(x: CGFloat(pixels) / canvas, y: CGFloat(pixels) / canvas)
    return ctx
}

/// White controller with the D-pad, buttons and play mark cut out, on a clear layer.
func controllerLayer(_ pixels: Int) -> CGImage {
    let ctx = makeContext(pixels)
    // each part is filled on its own: in one path, parts wound in opposite
    // directions would cancel out where they overlap
    ctx.setFillColor(color(0xFFFFFF))
    ctx.addPath(CGPath(roundedRect: CGRect(x: 222, y: 410, width: 580, height: 250),
                       cornerWidth: 125, cornerHeight: 125, transform: nil))
    ctx.fillPath()
    ctx.fillEllipse(in: CGRect(x: 212, y: 262, width: 250, height: 250))  // left grip
    ctx.fillEllipse(in: CGRect(x: 562, y: 262, width: 250, height: 250))  // right grip
    // fill the notch where each grip meets the body, so the flanks run straight
    for flank in [[CGPoint(x: 212, y: 387), CGPoint(x: 222, y: 535), CGPoint(x: 347, y: 535), CGPoint(x: 337, y: 387)],
                  [CGPoint(x: 812, y: 387), CGPoint(x: 802, y: 535), CGPoint(x: 677, y: 535), CGPoint(x: 687, y: 387)]] {
        ctx.addLines(between: flank)
        ctx.fillPath()
    }

    ctx.setBlendMode(.clear)
    // D-pad
    ctx.addPath(CGPath(roundedRect: CGRect(x: 272, y: 512, width: 150, height: 48),
                       cornerWidth: 14, cornerHeight: 14, transform: nil))
    ctx.addPath(CGPath(roundedRect: CGRect(x: 323, y: 461, width: 48, height: 150),
                       cornerWidth: 14, cornerHeight: 14, transform: nil))
    ctx.fillPath()
    // four face buttons
    let face = CGPoint(x: 677, y: 536)
    for (dx, dy) in [(0, 52), (0, -52), (52, 0), (-52, 0)] as [(CGFloat, CGFloat)] {
        ctx.addEllipse(in: CGRect(x: face.x + dx - 24, y: face.y + dy - 24, width: 48, height: 48))
    }
    ctx.fillPath()
    // play mark in the middle
    ctx.move(to: CGPoint(x: 494, y: 592))
    ctx.addLine(to: CGPoint(x: 494, y: 518))
    ctx.addLine(to: CGPoint(x: 552, y: 555))
    ctx.closePath()
    ctx.fillPath()
    return ctx.makeImage()!
}

func renderIcon(_ pixels: Int) -> CGImage {
    let ctx = makeContext(pixels)
    let scale = CGFloat(pixels) / canvas  // shadows are specified in device pixels
    let tile = CGPath(roundedRect: CGRect(x: 100, y: 100, width: 824, height: 824),
                      cornerWidth: 185, cornerHeight: 185, transform: nil)

    // tile + soft drop shadow (the standard macOS icon grid: 824 of 1024)
    ctx.saveGState()
    ctx.setShadow(offset: CGSize(width: 0, height: -10 * scale), blur: 24 * scale, color: color(0x000000, 0.35))
    ctx.addPath(tile)
    ctx.setFillColor(color(0x5B3DF5))
    ctx.fillPath()
    ctx.restoreGState()

    ctx.saveGState()
    ctx.addPath(tile)
    ctx.clip()
    let background = CGGradient(colorsSpace: colorSpace,
                                colors: [color(0x8B5CF6), color(0x4F46E5), color(0x0EA5E9)] as CFArray,
                                locations: [0, 0.5, 1])!
    ctx.drawLinearGradient(background, start: CGPoint(x: 180, y: 924), end: CGPoint(x: 844, y: 100), options: [])
    let sheen = CGGradient(colorsSpace: colorSpace,
                           colors: [color(0xFFFFFF, 0.22), color(0xFFFFFF, 0)] as CFArray, locations: [0, 1])!
    ctx.drawRadialGradient(sheen, startCenter: CGPoint(x: 400, y: 900), startRadius: 0,
                           endCenter: CGPoint(x: 400, y: 900), endRadius: 620, options: [])
    ctx.restoreGState()

    ctx.saveGState()
    ctx.setShadow(offset: CGSize(width: 0, height: -14 * scale), blur: 30 * scale, color: color(0x1E1B4B, 0.45))
    ctx.draw(controllerLayer(pixels), in: CGRect(x: 0, y: 0, width: canvas, height: canvas))
    ctx.restoreGState()
    return ctx.makeImage()!
}

func writePNG(_ image: CGImage, to path: String) {
    let data = NSBitmapImageRep(cgImage: image).representation(using: .png, properties: [:])!
    FileManager.default.createFile(atPath: path, contents: data)
}

let here = URL(fileURLWithPath: #filePath).deletingLastPathComponent().path
let iconset = NSTemporaryDirectory() + "AppIcon.iconset"
try? FileManager.default.removeItem(atPath: iconset)
try! FileManager.default.createDirectory(atPath: iconset, withIntermediateDirectories: true)
for points in [16, 32, 128, 256, 512] {
    writePNG(renderIcon(points), to: "\(iconset)/icon_\(points)x\(points).png")
    writePNG(renderIcon(points * 2), to: "\(iconset)/icon_\(points)x\(points)@2x.png")
}
writePNG(renderIcon(1024), to: here + "/AppIcon-preview.png")

let iconutil = Process()
iconutil.executableURL = URL(fileURLWithPath: "/usr/bin/iconutil")
iconutil.arguments = ["-c", "icns", iconset, "-o", here + "/AppIcon.icns"]
try! iconutil.run()
iconutil.waitUntilExit()
guard iconutil.terminationStatus == 0 else { fatalError("iconutil failed") }
print("wrote \(here)/AppIcon.icns")
