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
            guard let keyCode = keyCodeForChar(char) else { continue }
            let shift = isShifted(char)
            if shift {
                if let shiftDown = CGEvent(keyboardEventSource: nil, virtualKey: 0x38, keyDown: true) {
                    shiftDown.post(tap: .cghidEventTap)
                    usleep(10000)
                }
            }
            if let down = CGEvent(keyboardEventSource: nil, virtualKey: CGKeyCode(keyCode), keyDown: true),
               let up   = CGEvent(keyboardEventSource: nil, virtualKey: CGKeyCode(keyCode), keyDown: false) {
                down.post(tap: .cghidEventTap)
                usleep(10000)
                up.post(tap: .cghidEventTap)
                usleep(10000)
            }
            if shift {
                if let shiftUp = CGEvent(keyboardEventSource: nil, virtualKey: 0x38, keyDown: false) {
                    shiftUp.post(tap: .cghidEventTap)
                    usleep(10000)
                }
            }
        }
        return true
    }

    private static func keyCodeForChar(_ c: Character) -> Int? {
        switch c {
        case "a": return 0; case "b": return 11; case "c": return 8
        case "d": return 2; case "e": return 14; case "f": return 3
        case "g": return 5; case "h": return 4; case "i": return 34
        case "j": return 38; case "k": return 40; case "l": return 37
        case "m": return 46; case "n": return 45; case "o": return 31
        case "p": return 35; case "q": return 12; case "r": return 15
        case "s": return 1; case "t": return 17; case "u": return 32
        case "v": return 9; case "w": return 13; case "x": return 7
        case "y": return 16; case "z": return 6
        case "0": return 29; case "1": return 18; case "2": return 19
        case "3": return 20; case "4": return 21; case "5": return 23
        case "6": return 22; case "7": return 26; case "8": return 28
        case "9": return 25
        case " ": return 49; case ".": return 47; case "@": return 0
        case "-": return 27; case "_": return 27
        default: return nil
        }
    }

    private static func isShifted(_ c: Character) -> Bool {
        return c.isUppercase || "@#$%^&*()_+{}|:\"<>?~".contains(c)
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
