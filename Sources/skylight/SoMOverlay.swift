import Foundation
#if canImport(AppKit)
import AppKit
import CoreGraphics

enum SoMOverlay {

    /// Zeichnet nummerierte Marker (Set-of-Marks) für jedes interaktive Element
    /// auf ein Bild. Element-Frames sind in globalen Bildschirm-Koordinaten,
    /// daher wird `windowOrigin` subtrahiert.
    static func applySoM(to base: CGImage, elements: [AXElement], windowOrigin: CGPoint) -> CGImage {
        let width = base.width
        let height = base.height
        let cs = CGColorSpace(name: CGColorSpace.sRGB)!
        guard let ctx = CGContext(
            data: nil,
            width: width,
            height: height,
            bitsPerComponent: 8,
            bytesPerRow: 0,
            space: cs,
            bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
        ) else { return base }

        // Bild zeichnen (CoreGraphics ist Y-flipped: Origin unten links)
        ctx.draw(base, in: CGRect(x: 0, y: 0, width: width, height: height))

        let nsCtx = NSGraphicsContext(cgContext: ctx, flipped: false)
        NSGraphicsContext.saveGraphicsState()
        NSGraphicsContext.current = nsCtx

        for (idx, el) in elements.enumerated() {
            // Lokale Koordinaten: Element-Position relativ zum Fenster
            let localX = el.frame.origin.x - windowOrigin.x
            let localY = el.frame.origin.y - windowOrigin.y

            // CG nutzt unten-links, AX nutzt oben-links → Y flippen
            let flippedY = CGFloat(height) - localY - el.frame.size.height

            // Bounding Box
            let box = CGRect(x: localX, y: flippedY, width: el.frame.size.width, height: el.frame.size.height)
            ctx.setStrokeColor(NSColor.systemRed.cgColor)
            ctx.setLineWidth(2)
            ctx.stroke(box)

            // Label-Kreis oben links
            let badge = CGRect(x: localX - 2, y: flippedY + el.frame.size.height - 22, width: 26, height: 22)
            ctx.setFillColor(NSColor.systemRed.cgColor)
            ctx.fillEllipse(in: badge)

            let text = "\(idx)" as NSString
            let attrs: [NSAttributedString.Key: Any] = [
                .font: NSFont.boldSystemFont(ofSize: 13),
                .foregroundColor: NSColor.white
            ]
            let textSize = text.size(withAttributes: attrs)
            let textPoint = CGPoint(
                x: badge.midX - textSize.width / 2,
                y: badge.midY - textSize.height / 2
            )
            text.draw(at: textPoint, withAttributes: attrs)
        }

        NSGraphicsContext.restoreGraphicsState()
        return ctx.makeImage() ?? base
    }

    /// Zeichnet ein gleichmäßiges Pixel-Grid als Fallback, wenn der AX-Tree
    /// leer ist (z.B. bei Canvas-Umfragen).
    static func applyGrid(to base: CGImage, step: CGFloat) -> CGImage {
        let width = base.width
        let height = base.height
        let cs = CGColorSpace(name: CGColorSpace.sRGB)!
        guard let ctx = CGContext(
            data: nil,
            width: width,
            height: height,
            bitsPerComponent: 8,
            bytesPerRow: 0,
            space: cs,
            bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
        ) else { return base }

        ctx.draw(base, in: CGRect(x: 0, y: 0, width: width, height: height))
        ctx.setStrokeColor(NSColor.systemYellow.withAlphaComponent(0.6).cgColor)
        ctx.setLineWidth(1)

        var x: CGFloat = 0
        while x < CGFloat(width) {
            ctx.move(to: CGPoint(x: x, y: 0))
            ctx.addLine(to: CGPoint(x: x, y: CGFloat(height)))
            x += step
        }
        var y: CGFloat = 0
        while y < CGFloat(height) {
            ctx.move(to: CGPoint(x: 0, y: y))
            ctx.addLine(to: CGPoint(x: CGFloat(width), y: y))
            y += step
        }
        ctx.strokePath()
        return ctx.makeImage() ?? base
    }
}
#endif
