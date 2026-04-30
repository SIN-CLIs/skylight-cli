import Foundation
#if canImport(CoreGraphics)
import CoreGraphics
import ApplicationServices

enum Hold {
    static func run(pid: pid_t, elementIndex: Int, durationMs: Int = 3000) throws {
        let capture = try WindowCapture.capture(pid: pid)
        let elements = AXElementFinder.interactiveElements(pid: pid, windowFrame: capture.frame)
        guard elementIndex >= 0 && elementIndex < elements.count else {
            throw CLIError(code: "element_not_found",
                           message: "Element index \(elementIndex) out of range (have \(elements.count))",
                           exitCode: 3)
        }
        let el = elements[elementIndex]
        
        if SkyLightClicker.axPress(element: el.axElement) {
            usleep(UInt32(durationMs) * 1000)
        }
        Output.json([
            "status": "ok",
            "command": "hold",
            "pid": pid,
            "element_index": elementIndex,
            "duration_ms": durationMs,
            "element": ["role": el.role, "label": el.label, "path": el.path]
        ])
    }
}
#endif
