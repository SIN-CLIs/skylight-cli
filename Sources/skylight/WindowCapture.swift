import Foundation
#if canImport(AppKit)
import AppKit
import CoreGraphics

struct WindowCaptureResult {
    let image: CGImage
    let frame: CGRect
    let windowID: CGWindowID
    let title: String
    let onScreen: Bool
}

enum WindowCapture {

    /// Findet das Hauptfenster eines Prozesses und nimmt einen Screenshot davon auf.
    /// Bei Browsern bevorzugen wir das Fenster mit dem größten Layer 0 / kCGNormalWindowLevel.
    static func capture(pid: pid_t) throws -> WindowCaptureResult {
        guard let info = mainWindow(for: pid) else {
            throw CLIError(code: "window_not_found",
                           message: "No on-screen window for PID \(pid)",
                           exitCode: 3)
        }
        let bounds = info.frame
        let cgImage = CGWindowListCreateImage(
            CGRect.null,
            [.optionIncludingWindow],
            info.windowID,
            [.boundsIgnoreFraming, .nominalResolution]
        )
        guard let image = cgImage else {
            throw CLIError(code: "screenshot_failed",
                           message: "CGWindowListCreateImage returned nil for window \(info.windowID)",
                           exitCode: 4)
        }
        return WindowCaptureResult(
            image: image,
            frame: bounds,
            windowID: info.windowID,
            title: info.title,
            onScreen: true
        )
    }

    struct WindowInfo {
        let windowID: CGWindowID
        let frame: CGRect
        let title: String
    }

    static func mainWindow(for pid: pid_t) -> WindowInfo? {
        let opts: CGWindowListOption = [.optionOnScreenOnly, .excludeDesktopElements]
        guard let raw = CGWindowListCopyWindowInfo(opts, kCGNullWindowID) as? [[String: Any]] else {
            return nil
        }
        let candidates = raw.compactMap { dict -> WindowInfo? in
            guard let ownerPID = dict[kCGWindowOwnerPID as String] as? pid_t,
                  ownerPID == pid,
                  let wid = dict[kCGWindowNumber as String] as? CGWindowID,
                  let boundsDict = dict[kCGWindowBounds as String] as? [String: CGFloat],
                  let layer = dict[kCGWindowLayer as String] as? Int,
                  layer == 0 // normale App-Fenster, keine Status-Bars
            else { return nil }
            let frame = CGRect(
                x: boundsDict["X"] ?? 0,
                y: boundsDict["Y"] ?? 0,
                width: boundsDict["Width"] ?? 0,
                height: boundsDict["Height"] ?? 0
            )
            // Mini-Fenster (z.B. Tooltips) ausfiltern
            guard frame.width >= 200 && frame.height >= 200 else { return nil }
            let title = dict[kCGWindowName as String] as? String ?? ""
            return WindowInfo(windowID: wid, frame: frame, title: title)
        }
        // Größtes Fenster zuerst (das ist in der Regel das Hauptfenster)
        return candidates.max(by: { $0.frame.width * $0.frame.height < $1.frame.width * $1.frame.height })
    }
}
#endif
