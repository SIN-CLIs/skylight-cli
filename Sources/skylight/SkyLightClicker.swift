import Foundation
#if canImport(CoreGraphics)
import CoreGraphics
import Darwin

/// Bridge zur privaten SkyLight.framework. Wird per dlopen geladen, damit
/// das Build ohne Code-Sign-Entitlements funktioniert. Wenn das Symbol
/// nicht auflösbar ist, fallen wir auf CGEvent.post (cursor-stealing) zurück
/// und melden das im JSON-Output.
enum SkyLight {

    typealias SLPSPostEventRecordToType = @convention(c) (pid_t, UnsafePointer<UInt8>) -> Int32
    typealias CGEventPostToPidType      = @convention(c) (pid_t, CGEvent) -> Void

    static let handle: UnsafeMutableRawPointer? = {
        let paths = [
            "/System/Library/PrivateFrameworks/SkyLight.framework/SkyLight",
            "/System/Library/PrivateFrameworks/SkyLight.framework/Versions/A/SkyLight"
        ]
        for p in paths {
            if let h = dlopen(p, RTLD_LAZY | RTLD_LOCAL) { return h }
        }
        return nil
    }()

    /// SLPSPostEventRecordTo(pid_t, UInt8[0xf4]) - akzeptiert ein
    /// 244-Byte serialisiertes Event-Record. Wir liefern die Routine
    /// zur Vollständigkeit aus, nutzen aber primär das einfachere
    /// CGEventPostToPid (privat, aber stabil seit 10.6).
    static let postEventRecordTo: SLPSPostEventRecordToType? = {
        guard let h = handle, let sym = dlsym(h, "SLPSPostEventRecordTo") else { return nil }
        return unsafeBitCast(sym, to: SLPSPostEventRecordToType.self)
    }()

    /// CGEventPostToPid(pid_t, CGEventRef) - dokumentiert seit 10.11,
    /// aber nicht in den public Headern. Liefert in der Regel das
    /// gewünschte „kein-Cursor-Diebstahl" Verhalten für Browser.
    static let postToPid: CGEventPostToPidType? = {
        guard let sym = dlsym(UnsafeMutableRawPointer(bitPattern: -2), "CGEventPostToPid") else { return nil }
        return unsafeBitCast(sym, to: CGEventPostToPidType.self)
    }()
}

struct ClickResult {
    let posted: Bool
    let skylightLoaded: Bool
    let usedFallback: Bool
}

enum SkyLightClicker {

    static func click(at point: CGPoint, targetPID: pid_t, button: String = "left", forceFallback: Bool = false) -> ClickResult {
        let cgButton: CGMouseButton
        let downType: CGEventType
        let upType: CGEventType
        switch button {
        case "right":
            cgButton = .right
            downType = .rightMouseDown
            upType = .rightMouseUp
        default:
            cgButton = .left
            downType = .leftMouseDown
            upType = .leftMouseUp
        }

        guard
            let move = CGEvent(mouseEventSource: nil, mouseType: .mouseMoved, mouseCursorPosition: point, mouseButton: cgButton),
            let down = CGEvent(mouseEventSource: nil, mouseType: downType, mouseCursorPosition: point, mouseButton: cgButton),
            let up   = CGEvent(mouseEventSource: nil, mouseType: upType,   mouseCursorPosition: point, mouseButton: cgButton)
        else {
            return ClickResult(posted: false, skylightLoaded: SkyLight.handle != nil, usedFallback: false)
        }

        if !forceFallback, let post = SkyLight.postToPid {
            post(targetPID, move)
            post(targetPID, down)
            post(targetPID, up)
            return ClickResult(posted: true, skylightLoaded: SkyLight.handle != nil, usedFallback: false)
        }

        // Fallback: globaler Post (System-Cursor wird gestohlen, NICHT stealthy)
        move.post(tap: .cghidEventTap)
        down.post(tap: .cghidEventTap)
        up.post(tap: .cghidEventTap)
        return ClickResult(posted: true, skylightLoaded: SkyLight.handle != nil, usedFallback: true)
    }
}
#endif
