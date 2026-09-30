// Builds AppIcon.icns from AppIcon-source.png.
// Usage (from app/):  swift icon/make-icon.swift
// The source is a square picture of the tile on a light background. The tile is
// found by scanning for its dark pixels, cut out with the macOS rounded-tile shape
// (824 of 1024 units, with the standard drop shadow) and rendered at every size.
import AppKit

let canvas: CGFloat = 1024
let colorSpace = CGColorSpace(name: CGColorSpace.sRGB)!
let here = URL(fileURLWithPath: #filePath).deletingLastPathComponent().path

func loadSource() -> CGImage {
    guard let image = NSImage(contentsOfFile: here + "/AppIcon-source.png")?
        .cgImage(forProposedRect: nil, context: nil, hints: nil)
    else { fatalError("AppIcon-source.png not found next to this script") }
    return image
}

/// Bounds of the tile, in image pixels (origin top-left), found along the centre
/// row and column: the background is light, the tile edge is dark.
func tileBounds(of image: CGImage) -> CGRect {
    let w = image.width, h = image.height
    let ctx = CGContext(data: nil, width: w, height: h, bitsPerComponent: 8, bytesPerRow: w * 4,
                        space: colorSpace, bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue)!
    ctx.draw(image, in: CGRect(x: 0, y: 0, width: w, height: h))
    let px = ctx.data!.bindMemory(to: UInt8.self, capacity: w * h * 4)  // row 0 = top
    func isTile(_ x: Int, _ y: Int) -> Bool {
        let i = (y * w + x) * 4
        return (0.2126 * Double(px[i]) + 0.7152 * Double(px[i + 1]) + 0.0722 * Double(px[i + 2])) / 255 < 0.55
    }
    let left = (0..<w).first { isTile($0, h / 2) }!, right = (0..<w).last { isTile($0, h / 2) }!
    let top = (0..<h).first { isTile(w / 2, $0) }!, bottom = (0..<h).last { isTile(w / 2, $0) }!
    // a few pixels in, to drop the anti-aliased fringe against the background
    let inset = 3
    return CGRect(x: left + inset, y: top + inset, width: right - left - 2 * inset, height: bottom - top - 2 * inset)
}

func renderIcon(_ tile: CGImage, pixels: Int) -> CGImage {
    let ctx = CGContext(data: nil, width: pixels, height: pixels, bitsPerComponent: 8, bytesPerRow: 0,
                        space: colorSpace, bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue)!
    let scale = CGFloat(pixels) / canvas
    ctx.scaleBy(x: scale, y: scale)
    ctx.interpolationQuality = .high
    // the macOS corner is rounder than the source's, so this also trims its corners
    let tileRect = CGRect(x: 100, y: 100, width: 824, height: 824)
    let shape = CGPath(roundedRect: tileRect, cornerWidth: 185, cornerHeight: 185, transform: nil)

    ctx.saveGState()
    ctx.setShadow(offset: CGSize(width: 0, height: -10 * scale), blur: 24 * scale,  // shadows are in device pixels
                  color: CGColor(gray: 0, alpha: 0.35))
    ctx.addPath(shape)
    ctx.setFillColor(CGColor(gray: 0, alpha: 1))
    ctx.fillPath()
    ctx.restoreGState()

    ctx.addPath(shape)
    ctx.clip()
    ctx.draw(tile, in: tileRect)
    return ctx.makeImage()!
}

func writePNG(_ image: CGImage, to path: String) {
    let data = NSBitmapImageRep(cgImage: image).representation(using: .png, properties: [:])!
    FileManager.default.createFile(atPath: path, contents: data)
}

let source = loadSource()
let bounds = tileBounds(of: source)
let tile = source.cropping(to: bounds)!
print("tile found at \(bounds) in a \(source.width)x\(source.height) source")

let iconset = NSTemporaryDirectory() + "AppIcon.iconset"
try? FileManager.default.removeItem(atPath: iconset)
try! FileManager.default.createDirectory(atPath: iconset, withIntermediateDirectories: true)
for points in [16, 32, 128, 256, 512] {
    writePNG(renderIcon(tile, pixels: points), to: "\(iconset)/icon_\(points)x\(points).png")
    writePNG(renderIcon(tile, pixels: points * 2), to: "\(iconset)/icon_\(points)x\(points)@2x.png")
}
writePNG(renderIcon(tile, pixels: 1024), to: here + "/AppIcon-preview.png")

let iconutil = Process()
iconutil.executableURL = URL(fileURLWithPath: "/usr/bin/iconutil")
iconutil.arguments = ["-c", "icns", iconset, "-o", here + "/AppIcon.icns"]
try! iconutil.run()
iconutil.waitUntilExit()
guard iconutil.terminationStatus == 0 else { fatalError("iconutil failed") }
print("wrote \(here)/AppIcon.icns")
