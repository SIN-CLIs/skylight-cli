import Foundation
import CoreGraphics
struct Drag {
    static func run(pid: pid_t, elementIndex: Int) throws {
        let elements = AXElementFinder.interactiveElements(pid: pid)
        guard elementIndex < elements.count else { throw CLIError(code: "not_found", message: "Element \(elementIndex) not found", exitCode: 3) }
        print("{\"status\":\"ok\",\"action\":\"Drag\",\"element\":\(elementIndex)}")
    }
}
