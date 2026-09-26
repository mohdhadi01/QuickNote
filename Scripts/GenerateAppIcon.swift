import AppKit
import CoreGraphics
import Foundation
import ImageIO
import UniformTypeIdentifiers

/// Generates the QuickNote app icon in all required macOS sizes.
///
/// Usage: swift Scripts/GenerateAppIcon.swift <AppIcon.appiconset-dir>
///
/// Design: a quick-capture note card on an indigo-blue gradient with a
/// pencil — minimal, original, strong at small sizes (spec §54).

let sizes = [16, 32, 128, 256, 512, 1024] // rendered sizes (some drawn at 2x variants)

struct IconRenderer {
    let size: CGFloat

    var s: CGFloat { size / 1024 }

    func render() -> CGImage? {
        guard let context = CGContext(
            data: nil,
            width: Int(size),
            height: Int(size),
            bitsPerComponent: 8,
            bytesPerRow: 0,
            space: CGColorSpace(name: CGColorSpace.sRGB)!,
            bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
        ) else { return nil }

        drawBackground(in: context)
        drawCard(in: context)
        drawTextLines(in: context)
        drawPencil(in: context)

        return context.makeImage()
    }

    private func color(_ r: CGFloat, _ g: CGFloat, _ b: CGFloat, _ a: CGFloat = 1) -> CGColor {
        CGColor(srgbRed: r / 255, green: g / 255, blue: b / 255, alpha: a)
    }

    // MARK: Background

    private func drawBackground(in ctx: CGContext) {
        let rect = CGRect(x: 0, y: 0, width: size, height: size)
        let radius = 185 * s
        let path = CGPath(roundedRect: rect, cornerWidth: radius, cornerHeight: radius, transform: nil)

        ctx.addPath(path)
        ctx.clip()

        let gradient = CGGradient(
            colorsSpace: CGColorSpace(name: CGColorSpace.sRGB)!,
            colors: [
                color(96, 144, 246),
                color(59, 92, 226),
                color(44, 62, 178),
            ] as CFArray,
            locations: [0.0, 0.55, 1.0]
        )!
        ctx.drawLinearGradient(
            gradient,
            start: CGPoint(x: size * 0.15, y: size),
            end: CGPoint(x: size * 0.85, y: 0),
            options: []
        )
    }

    // MARK: Note card

    private var cardRect: CGRect {
        CGRect(x: 240 * s, y: 196 * s, width: 544 * s, height: 660 * s)
    }

    private func drawCard(in ctx: CGContext) {
        let rect = cardRect
        let radius = 72 * s

        // Shadow.
        ctx.saveGState()
        ctx.setShadow(offset: CGSize(width: 0, height: -14 * s), blur: 44 * s,
                      color: color(20, 26, 60, 0.38))
        ctx.setFillColor(color(252, 252, 253))
        let path = CGPath(roundedRect: rect, cornerWidth: radius, cornerHeight: radius, transform: nil)
        ctx.addPath(path)
        ctx.fillPath()
        ctx.restoreGState()

        // Subtle inner top highlight for depth.
        ctx.saveGState()
        ctx.addPath(CGPath(roundedRect: rect, cornerWidth: radius, cornerHeight: radius, transform: nil))
        ctx.clip()
        let highlight = CGGradient(
            colorsSpace: CGColorSpace(name: CGColorSpace.sRGB)!,
            colors: [color(255, 255, 255, 0.5), color(255, 255, 255, 0.0)] as CFArray,
            locations: [0, 1]
        )!
        ctx.drawLinearGradient(
            highlight,
            start: CGPoint(x: rect.midX, y: rect.maxY),
            end: CGPoint(x: rect.midX, y: rect.maxY - rect.height * 0.35),
            options: []
        )
        ctx.restoreGState()
    }

    private func drawTextLines(in ctx: CGContext) {
        let card = cardRect
        let lineColor = color(214, 221, 234)
        let titleColor = color(148, 158, 178)
        let lineHeight: CGFloat = 30 * s
        let gap: CGFloat = 62 * s
        let x = card.minX + 68 * s
        var y = card.maxY - 150 * s

        // Title line (darker, shorter).
        roundedLine(ctx: ctx, x: x, y: y, width: 260 * s, height: lineHeight + 4 * s, color: titleColor)
        y -= gap

        let widths: [CGFloat] = [400, 408, 352, 396, 300]
        for width in widths {
            roundedLine(ctx: ctx, x: x, y: y, width: width * s, height: lineHeight, color: lineColor)
            y -= gap
        }
    }

    private func roundedLine(ctx: CGContext, x: CGFloat, y: CGFloat, width: CGFloat, height: CGFloat, color: CGColor) {
        ctx.setFillColor(color)
        let rect = CGRect(x: x, y: y - height / 2, width: width, height: height)
        ctx.addPath(CGPath(roundedRect: rect, cornerWidth: height / 2, cornerHeight: height / 2, transform: nil))
        ctx.fillPath()
    }

    // MARK: Pencil

    private func drawPencil(in ctx: CGContext) {
        // Draw the pencil axis-aligned in a rotated space for easy geometry.
        ctx.saveGState()
        ctx.translateBy(x: size * 0.60, y: size * 0.36)
        ctx.rotate(by: .pi / 4)

        let bodyWidth: CGFloat = 96 * s
        let bodyLength: CGFloat = 420 * s
        let eraserLength: CGFloat = 78 * s
        let ferruleLength: CGFloat = 44 * s
        let tipLength: CGFloat = 92 * s

        // Body (amber gradient).
        let bodyRect = CGRect(x: -bodyWidth / 2, y: -bodyLength / 2 - ferruleLength - eraserLength + tipLength * 0, width: bodyWidth, height: bodyLength)
        let amber = CGGradient(
            colorsSpace: CGColorSpace(name: CGColorSpace.sRGB)!,
            colors: [color(255, 190, 84), color(250, 150, 60)] as CFArray,
            locations: [0, 1]
        )!
        ctx.saveGState()
        roundedShadowRect(ctx: ctx, rect: bodyRect, radius: 10 * s)
        ctx.clip()
        ctx.drawLinearGradient(
            amber,
            start: CGPoint(x: bodyRect.minX, y: 0),
            end: CGPoint(x: bodyRect.maxX, y: 0),
            options: []
        )
        ctx.restoreGState()

        // Ferrule (light metal band).
        let ferruleRect = CGRect(x: -bodyWidth / 2, y: bodyRect.maxY, width: bodyWidth, height: ferruleLength)
        ctx.setFillColor(color(214, 221, 234))
        roundedShadowRect(ctx: ctx, rect: ferruleRect, radius: 6 * s)
        ctx.fillPath()

        // Eraser (rose).
        let eraserRect = CGRect(x: -bodyWidth / 2, y: ferruleRect.maxY, width: bodyWidth, height: eraserLength)
        ctx.setFillColor(color(236, 112, 122))
        roundedShadowRect(ctx: ctx, rect: eraserRect, radius: 34 * s)
        ctx.fillPath()

        // Tip (wood) — triangle pointing down.
        let tipPath = CGMutablePath()
        tipPath.move(to: CGPoint(x: -bodyWidth / 2, y: bodyRect.minY))
        tipPath.addLine(to: CGPoint(x: bodyWidth / 2, y: bodyRect.minY))
        tipPath.addLine(to: CGPoint(x: 0, y: bodyRect.minY - tipLength))
        tipPath.closeSubpath()
        ctx.addPath(tipPath)
        ctx.setFillColor(color(240, 220, 190))
        ctx.fillPath()

        // Graphite.
        let graphite = CGMutablePath()
        graphite.move(to: CGPoint(x: -bodyWidth * 0.17, y: bodyRect.minY - tipLength * 0.62))
        graphite.addLine(to: CGPoint(x: bodyWidth * 0.17, y: bodyRect.minY - tipLength * 0.62))
        graphite.addLine(to: CGPoint(x: 0, y: bodyRect.minY - tipLength))
        graphite.closeSubpath()
        ctx.addPath(graphite)
        ctx.setFillColor(color(74, 78, 92))
        ctx.fillPath()

        ctx.restoreGState()
    }

    private func roundedShadowRect(ctx: CGContext, rect: CGRect, radius: CGFloat) {
        ctx.setShadow(offset: CGSize(width: 0, height: -8 * s), blur: 26 * s, color: color(20, 26, 60, 0.30))
        ctx.addPath(CGPath(roundedRect: rect, cornerWidth: radius, cornerHeight: radius, transform: nil))
        ctx.fillPath()
        ctx.setShadow(offset: .zero, blur: 0, color: nil)
        ctx.addPath(CGPath(roundedRect: rect, cornerWidth: radius, cornerHeight: radius, transform: nil))
    }
}

func writePNG(_ image: CGImage, to url: URL) throws {
    guard let destination = CGImageDestinationCreateWithURL(
        url as CFURL,
        UTType.png.identifier as CFString,
        1,
        nil
    ) else {
        throw NSError(domain: "IconGeneration", code: 1,
                      userInfo: [NSLocalizedDescriptionKey: "Failed to create destination \(url.lastPathComponent)"])
    }
    CGImageDestinationAddImage(destination, image, nil as CFDictionary?)
    guard CGImageDestinationFinalize(destination) else {
        throw NSError(domain: "IconGeneration", code: 1,
                      userInfo: [NSLocalizedDescriptionKey: "Failed to write \(url.lastPathComponent)"])
    }
}

// MARK: Main

let arguments = CommandLine.arguments
let outputDir: String
if arguments.count > 1 {
    outputDir = arguments[1]
} else {
    outputDir = "QuickNote/Assets.xcassets/AppIcon.appiconset"
}

let directory = URL(fileURLWithPath: outputDir, isDirectory: true)
try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)

// (pixel size, filename)
let variants: [(Int, String)] = [
    (16, "icon_16x16.png"),
    (32, "icon_16x16@2x.png"),
    (32, "icon_32x32.png"),
    (64, "icon_32x32@2x.png"),
    (128, "icon_128x128.png"),
    (256, "icon_128x128@2x.png"),
    (256, "icon_256x256.png"),
    (512, "icon_256x256@2x.png"),
    (512, "icon_512x512.png"),
    (1024, "icon_512x512@2x.png"),
]

for (pixel, filename) in variants {
    let renderer = IconRenderer(size: CGFloat(pixel))
    guard let image = renderer.render() else {
        FileHandle.standardError.write("Failed to render \(filename)\n".data(using: .utf8)!)
        exit(1)
    }
    try writePNG(image, to: directory.appendingPathComponent(filename))
    print("Wrote \(filename) (\(pixel)×\(pixel))")
}

print("App icon generated at \(directory.path)")
