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
        if !axPress(element: element) { return false }
        usleep(50000)
        for char in text {
            let utf16 = String(char).utf16
            var chars = Array(utf16)
            guard let down = CGEvent(keyboardEventSource: nil, virtualKey: 0, keyDown: true),
                  let up   = CGEvent(keyboardEventSource: nil, virtualKey: 0, keyDown: false)
            else { continue }
            down.keyboardSetUnicodeString(stringLength: chars.count, unicodeString: &chars)
            up.keyboardSetUnicodeString(stringLength: chars.count, unicodeString: &chars)
            down.post(tap: .cghidEventTap)
            usleep(30000)
            up.post(tap: .cghidEventTap)
            usleep(UInt32.random(in: 50000...150000))
        }
        return true
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
