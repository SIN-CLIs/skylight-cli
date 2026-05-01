import Foundation
import CoreGraphics
struct Drag {
    static func run(args: [String]) throws {
        let opts = ArgParser(args)
        guard let pid = opts.pid("--pid"), let fromIdx = opts.int("--from-element"), let toX = opts.int("--to-x"), let toY = opts.int("--to-y") else { throw CLIError.missingPID }
        let elements = AXElementFinder.interactiveElements(pid: pid)
        guard fromIdx < elements.count else { throw CLIError.elementNotFound }
        let start = CGPoint(x: elements[fromIdx].frame.midX, y: elements[fromIdx].frame.midY)
        let end = CGPoint(x: CGFloat(toX), y: CGFloat(toY))
        func send(_ event: CGEvent) { event.post(tap: .cghidEventTap) }
        send(CGEvent(mouseEventSource: nil, mouseType: .leftMouseDown, mouseCursorPosition: start, mouseButton: .left)!)
        for i in 1...20 { let t=CGFloat(i)/20; send(CGEvent(mouseEventSource: nil, mouseType: .mouseMoved, mouseCursorPosition: CGPoint(x:start.x+(end.x-start.x)*t, y:start.y+(end.y-start.y)*t), mouseButton: .left)!); usleep(10000) }
        send(CGEvent(mouseEventSource: nil, mouseType: .leftMouseUp, mouseCursorPosition: end, mouseButton: .left)!)
        print("{\"status\":\"ok\",\"dragged\":{\"from\":\(fromIdx),\"to\":{\"x\":\(toX),\"y\":\(toY)}}}")
    }
}
