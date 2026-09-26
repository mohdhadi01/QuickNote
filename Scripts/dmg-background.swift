// Generates the DMG installer background: soft light gradient with a
// quiet indigo wash — matches the website's classic-glass look.
// Usage: swift Scripts/dmg-background.swift <output.png>
import Foundation
import CoreGraphics
import ImageIO
import UniformTypeIdentifiers

let W = 660, H = 400
let out = CommandLine.arguments.count > 1 ? CommandLine.arguments[1] : "background.png"

let cs = CGColorSpace(name: CGColorSpace.sRGB)!
let ctx = CGContext(data: nil, width: W, height: H, bitsPerComponent: 8, bytesPerRow: 0,
                    space: cs, bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue)!

// Base: near-white vertical wash
ctx.setFillColor(CGColor(srgbRed: 0.968, green: 0.973, blue: 0.984, alpha: 1))
ctx.fill(CGRect(x: 0, y: 0, width: W, height: H))

func wash(_ cx: CGFloat, _ cy: CGFloat, _ r: CGFloat, _ c: CGColor) {
    let g = CGGradient(colorsSpace: cs, colors: [c, CGColor(srgbRed: 0, green: 0, blue: 0, alpha: 0)] as CFArray,
                       locations: [0, 1])!
    ctx.saveGState()
    ctx.clip(to: CGRect(x: 0, y: 0, width: W, height: H))
    ctx.drawRadialGradient(g, startCenter: CGPoint(x: cx, y: cy), startRadius: 0,
                           endCenter: CGPoint(x: cx, y: cy), endRadius: r, options: [])
    ctx.restoreGState()
}

wash(90, 400, 340, CGColor(srgbRed: 0.36, green: 0.42, blue: 0.95, alpha: 0.14))   // indigo, top-left
wash(600, 380, 320, CGColor(srgbRed: 0.55, green: 0.4, blue: 0.96, alpha: 0.10))   // violet, top-right
wash(330, 0, 300, CGColor(srgbRed: 0.3, green: 0.55, blue: 0.85, alpha: 0.08))     // soft blue, bottom

let img = ctx.makeImage()!
let dest = CGImageDestinationCreateWithURL(URL(fileURLWithPath: out) as CFURL,
                                           UTType.png.identifier as CFString, 1, nil)!
CGImageDestinationAddImage(dest, img, nil)
CGImageDestinationFinalize(dest)
print("background written: \(out)")
