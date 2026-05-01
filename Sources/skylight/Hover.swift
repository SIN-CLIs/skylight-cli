import Foundation
import CoreGraphics
struct Hover {
    static func run(args: [String]) throws {
        let opts = ArgParser(args)
        guard let pid = opts.pid("--pid"), let eid = opts.int("--element-index") else { throw CLIError.missingPID }
        let elements = AXElementFinder.interactiveElements(pid: pid)
        guard eid < elements.count else { throw CLIError.elementNotFound }
        let point = CGPoint(x: elements[eid].frame.midX, y: elements[eid].frame.midY)
        CGEvent(mouseEventSource: nil, mouseType: .mouseMoved, mouseCursorPosition: point, mouseButton: .left)!.post(tap: .cghidEventTap)
        print("{\"status\":\"ok\",\"hovered\":\(eid)}")
    }
}
