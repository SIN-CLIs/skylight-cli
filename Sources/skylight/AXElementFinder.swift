import Foundation
#if canImport(ApplicationServices)
import ApplicationServices
import CoreGraphics

struct AXElement {
    let frame: CGRect      // global screen coordinates (top-left origin)
    let label: String
    let role: String
}

enum AXElementFinder {

    static let interactingRoles: Set<String> = [
        kAXButtonRole as String,
        kAXLinkRole as String,
        kAXCheckBoxRole as String,
        kAXRadioButtonRole as String,
        kAXTextFieldRole as String,
        kAXTextAreaRole as String,
        kAXPopUpButtonRole as String,
        kAXMenuButtonRole as String,
        kAXSliderRole as String,
        kAXTabGroupRole as String,
        kAXComboBoxRole as String,
        // Web-spezifische Rollen, die Chromium über AX exponiert
        "AXWebArea",
        "AXStaticText"
    ]

    /// Liefert alle interaktiven Elemente eines Prozesses, sortiert nach
    /// Bildschirmposition (oben → unten, dann links → rechts).
    /// `windowFrame` wird genutzt, um Elemente außerhalb des Fensters
    /// zu verwerfen (z.B. versteckte Menüs).
    static func interactiveElements(pid: pid_t, windowFrame: CGRect? = nil) -> [AXElement] {
        guard isAXTrusted() else { return [] }

        let app = AXUIElementCreateApplication(pid)
        var windowsRef: CFTypeRef?
        let err = AXUIElementCopyAttributeValue(app, kAXWindowsAttribute as CFString, &windowsRef)
        guard err == .success, let windows = windowsRef as? [AXUIElement] else { return [] }

        var results: [AXElement] = []
        for window in windows {
            collect(from: window, depth: 0, into: &results)
        }

        // Filtern auf Fenstergeometrie, falls bekannt
        if let bounds = windowFrame {
            results = results.filter { bounds.intersects($0.frame) }
        }

        // Reading-Order Sortierung: nach Y-Bändern (alle 20px) gruppieren, dann X
        results.sort { a, b in
            let bandA = Int(a.frame.origin.y / 20)
            let bandB = Int(b.frame.origin.y / 20)
            if bandA != bandB { return bandA < bandB }
            return a.frame.origin.x < b.frame.origin.x
        }
        return results
    }

    private static let maxDepth = 60

    private static func collect(from element: AXUIElement, depth: Int, into results: inout [AXElement]) {
        guard depth < maxDepth else { return }

        if let role = stringAttr(element, kAXRoleAttribute as CFString),
           interactingRoles.contains(role),
           let frame = frame(of: element),
           frame.size.width > 1, frame.size.height > 1
        {
            let label = bestLabel(of: element)
            // Static text nur dann mitnehmen, wenn er einen sinnvollen Label hat
            if role == "AXStaticText" && label.trimmingCharacters(in: .whitespaces).isEmpty {
                // skip
            } else {
                results.append(AXElement(frame: frame, label: label, role: role))
            }
        }

        var childrenRef: CFTypeRef?
        if AXUIElementCopyAttributeValue(element, kAXChildrenAttribute as CFString, &childrenRef) == .success,
           let children = childrenRef as? [AXUIElement]
        {
            for child in children {
                collect(from: child, depth: depth + 1, into: &results)
            }
        }
    }

    private static func bestLabel(of element: AXUIElement) -> String {
        // Priorität: title > description > value > role description
        for attr in [kAXTitleAttribute, kAXDescriptionAttribute, kAXValueAttribute, kAXRoleDescriptionAttribute] {
            if let s = stringAttr(element, attr as CFString), !s.isEmpty {
                return s
            }
        }
        return ""
    }

    private static func stringAttr(_ element: AXUIElement, _ attr: CFString) -> String? {
        var ref: CFTypeRef?
        guard AXUIElementCopyAttributeValue(element, attr, &ref) == .success else { return nil }
        return ref as? String
    }

    private static func frame(of element: AXUIElement) -> CGRect? {
        var posRef: CFTypeRef?
        var sizeRef: CFTypeRef?
        guard AXUIElementCopyAttributeValue(element, kAXPositionAttribute as CFString, &posRef) == .success,
              AXUIElementCopyAttributeValue(element, kAXSizeAttribute as CFString, &sizeRef) == .success
        else { return nil }

        var point = CGPoint.zero
        var size = CGSize.zero
        guard let posVal = posRef, CFGetTypeID(posVal) == AXValueGetTypeID() else { return nil }
        guard let sizeVal = sizeRef, CFGetTypeID(sizeVal) == AXValueGetTypeID() else { return nil }

        // swiftlint:disable:next force_cast
        AXValueGetValue(posVal as! AXValue, .cgPoint, &point)
        // swiftlint:disable:next force_cast
        AXValueGetValue(sizeVal as! AXValue, .cgSize, &size)
        return CGRect(origin: point, size: size)
    }

    private static func isAXTrusted() -> Bool {
        // Wir prompten NICHT (kAXTrustedCheckOptionPrompt = false), das CLI
        // soll non-interactive bleiben.
        let opts: CFDictionary = [
            kAXTrustedCheckOptionPrompt.takeUnretainedValue() as String: false
        ] as CFDictionary
        return AXIsProcessTrustedWithOptions(opts)
    }
}
#endif
