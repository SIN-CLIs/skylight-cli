import Foundation
#if canImport(AppKit)
import AppKit
import CoreGraphics
import Vision

struct OCRRegion {
    let frame: CGRect
    let text: String
}

enum OCRGrounding {

    /// Führt VNRecognizeTextRequest auf dem Bild aus und liefert
    /// erkannte Textregionen. Dies ist die dritte Fallback-Ebene
    /// wenn SoM (AX) und Grid (Pixel) beide versagen.
    static func detectTextRegions(in image: CGImage) -> [OCRRegion] {
        var regions: [OCRRegion] = []
        let request = VNRecognizeTextRequest { (req, _) in
            guard let observations = req.results as? [VNRecognizedTextObservation] else { return }
            for obs in observations {
                guard let candidate = obs.topCandidates(1).first else { continue }
                let text = candidate.string.trimmingCharacters(in: .whitespacesAndNewlines)
                guard !text.isEmpty else { continue }
                let width = CGFloat(image.width)
                let height = CGFloat(image.height)

                // VN boundingBox ist normalisiert (0..1), Ursprung unten-links
                let normalizedBox = obs.boundingBox
                let x = normalizedBox.origin.x * width
                let y = (1.0 - normalizedBox.origin.y - normalizedBox.size.height) * height
                let w = normalizedBox.size.width * width
                let h = normalizedBox.size.height * height
                regions.append(OCRRegion(frame: CGRect(x: x, y: y, width: w, height: h), text: text))
            }
        }
        request.recognitionLevel = .accurate
        request.usesLanguageCorrection = false
        request.revision = VNRecognizeTextRequestRevision3

        let handler = VNImageRequestHandler(cgImage: image, options: [:])
        try? handler.perform([request])
        return regions
    }

    /// Zeichnet OCR-Bounding-Boxen auf das Bild – ID-Badges wie SoM,
    /// aber basierend auf Textregionen statt AX-Elementen.
    static func applyOCR(to base: CGImage) -> CGImage {
        let regions = detectTextRegions(in: base)
        let width = base.width
        let height = base.height
        let cs = CGColorSpace(name: CGColorSpace.sRGB)!
        guard let ctx = CGContext(
            data: nil, width: width, height: height,
            bitsPerComponent: 8, bytesPerRow: 0,
            space: cs, bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
        ) else { return base }

        ctx.draw(base, in: CGRect(x: 0, y: 0, width: width, height: height))

        let nsCtx = NSGraphicsContext(cgContext: ctx, flipped: false)
        NSGraphicsContext.saveGraphicsState()
        NSGraphicsContext.current = nsCtx

        for (idx, region) in regions.enumerated() {
            let box = CGRect(
                x: region.frame.origin.x,
                y: CGFloat(height) - region.frame.origin.y - region.frame.size.height,
                width: region.frame.size.width,
                height: region.frame.size.height
            )
            ctx.setStrokeColor(NSColor.systemBlue.cgColor)
            ctx.setLineWidth(2)
            ctx.stroke(box)

            let label = "OCR\(idx)" as NSString
            let attrs: [NSAttributedString.Key: Any] = [
                .font: NSFont.boldSystemFont(ofSize: 10),
                .foregroundColor: NSColor.white
            ]
            let textSize = label.size(withAttributes: attrs)
            let badgeW = max(textSize.width + 8, 40)
            let badgeH = textSize.height + 4
            let badge = CGRect(x: box.origin.x, y: box.origin.y - badgeH, width: badgeW, height: badgeH)
            ctx.setFillColor(NSColor.systemBlue.cgColor)
            ctx.fill(badge)
            let textPoint = CGPoint(x: badge.midX - textSize.width / 2, y: badge.midY - textSize.height / 2)
            label.draw(at: textPoint, withAttributes: attrs)
        }

        NSGraphicsContext.restoreGraphicsState()
        return ctx.makeImage() ?? base
    }
}
#endif
