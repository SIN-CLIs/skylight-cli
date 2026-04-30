import Foundation
#if canImport(ApplicationServices)
import ApplicationServices
import CoreGraphics

struct AXElement {
    let frame: CGRect      // global screen coordinates (top-left origin)
    let label: String
    let role: String
    let path: String       // AX parent chain, e.g. "AXWindow/AXWebArea/AXGroup/AXButton"
    let axElement: AXUIElement  // reference for AXPress actions
}

enum AXElementFinder {

    static let interactingRoles: Set<String> = [
        kAXButtonRole as String,
        "AXLink",
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

    // MARK: - Private SPI: Hält den AX-Tree aktiv, selbst wenn Fenster verdeckt ist

    private static var didEnrollTreeWakeup = false

    private static func enrollAXTreeWakeup(pid: pid_t) {
        guard !didEnrollTreeWakeup else { return }
        didEnrollTreeWakeup = true

        // Private SPI: _AXObserverAddNotificationAndCheckRemote
        // Verhindert, dass Blink den Accessibility-Tree pausiert,
        // wenn das Fenster von einem anderen überlappt wird.
        // Wird von Apple's VoiceOver + Diktat genutzt.
        typealias AXObserverAddNotificationFn = @convention(c) (
            AXObserver, AXUIElement, CFString, UnsafeMutableRawPointer?
        ) -> AXError

        guard let handle = dlopen(
            "/System/Library/PrivateFrameworks/HIServices.framework/HIServices",
            RTLD_LAZY | RTLD_LOCAL
        ) else { return }

        guard let sym = dlsym(handle, "_AXObserverAddNotificationAndCheckRemote") else {
            dlclose(handle)
            return
        }
        let fn = unsafeBitCast(sym, to: AXObserverAddNotificationFn.self)

        let app = AXUIElementCreateApplication(pid)
        var observer: AXObserver?
        guard AXObserverCreate(pid, { _, _, _, _ in }, &observer) == .success,
              let obs = observer else {
            dlclose(handle)
            return
        }

        // Registriere für FocusedWindowChanged — das hält Blink's AX-Tree wach
        let focusedNotification = kAXFocusedWindowChangedNotification as CFString
        _ = fn(obs, app, focusedNotification, nil)
        CFRunLoopAddSource(
            CFRunLoopGetCurrent(),
            AXObserverGetRunLoopSource(obs),
            .defaultMode
        )

        // dlclose lassen wir absichtlich offen — der Observer muss leben
    }

    /// Liefert alle interaktiven Elemente eines Prozesses, sortiert nach
    /// Bildschirmposition (oben → unten, dann links → rechts).
    /// `windowFrame` wird genutzt, um Elemente außerhalb des Fensters
    /// zu verwerfen (z.B. versteckte Menüs).
    static func interactiveElements(pid: pid_t, windowFrame: CGRect? = nil) -> [AXElement] {
        guard isAXTrusted() else { return [] }

        enrollAXTreeWakeup(pid: pid)

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

    private static func collect(from element: AXUIElement, depth: Int, into results: inout [AXElement], parentPath: String = "") {
        guard depth < maxDepth else { return }

        let currentRole = stringAttr(element, kAXRoleAttribute as CFString) ?? ""
        let currentPath = parentPath.isEmpty ? currentRole : "\(parentPath)/\(currentRole)"

        if interactingRoles.contains(currentRole),
           let frame = frame(of: element),
           frame.size.width > 1, frame.size.height > 1
        {
            let label = bestLabel(of: element)
            if currentRole != "AXStaticText" || !label.trimmingCharacters(in: .whitespaces).isEmpty {
                results.append(AXElement(frame: frame, label: label, role: currentRole, path: currentPath, axElement: element))
            }
        }

        var childrenRef: CFTypeRef?
        if AXUIElementCopyAttributeValue(element, kAXChildrenAttribute as CFString, &childrenRef) == .success,
           let children = childrenRef as? [AXUIElement]
        {
            for child in children {
                collect(from: child, depth: depth + 1, into: &results, parentPath: currentPath)
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
        guard let posVal = posRef, CFGetTypeID(posVal) == AXValueGetTypeID(),
              let sizeVal = sizeRef, CFGetTypeID(sizeVal) == AXValueGetTypeID()
        else { return nil }

        AXValueGetValue(posVal as! AXValue, .cgPoint, &point)
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
