import Foundation
#if canImport(CoreGraphics)
import CoreGraphics
import ApplicationServices

struct ClickResult {
    let posted: Bool
}

enum SkyLightClicker {

    static func axPress(element: AXUIElement) -> Bool {
        let err = AXUIElementPerformAction(element, kAXPressAction as CFString)
        return err == .success
    }

    static func typeText(element: AXUIElement, text: String) -> Bool {
        let err = AXUIElementSetAttributeValue(element, kAXValueAttribute as CFString, text as CFTypeRef)
        return err == .success
    }

    static func click(at point: CGPoint, targetPID: pid_t, button: String = "left") -> ClickResult {
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
            return ClickResult(posted: false)
        }

        move.post(tap: .cghidEventTap)
        usleep(10000)
        down.post(tap: .cghidEventTap)
        usleep(50000)
        up.post(tap: .cghidEventTap)

        return ClickResult(posted: true)
    }
}
#endif
