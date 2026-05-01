import Foundation
import CoreGraphics
struct DoubleClick {
    static func run(args: [String]) throws {
        let opts = ArgParser(args)
        guard let pid = opts.pid("--pid"), let eid = opts.int("--element-index") else { throw CLIError.missingPID }
        let elements = AXElementFinder.interactiveElements(pid: pid)
        guard eid < elements.count else { throw CLIError.elementNotFound }
        let point = CGPoint(x: elements[eid].frame.midX, y: elements[eid].frame.midY)
        for _ in 1...2 {
            CGEvent(mouseEventSource: nil, mouseType: .leftMouseDown, mouseCursorPosition: point, mouseButton: .left)!.post(tap: .cghidEventTap)
            usleep(50000)
            CGEvent(mouseEventSource: nil, mouseType: .leftMouseUp, mouseCursorPosition: point, mouseButton: .left)!.post(tap: .cghidEventTap)
            usleep(100000)
        }
        print("{\"status\":\"ok\",\"double_clicked\":\(eid)}")
    }
}
