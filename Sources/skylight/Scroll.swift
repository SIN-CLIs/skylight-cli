import Foundation
import CoreGraphics
struct Scroll {
    static func run(args: [String]) throws {
        let opts = ArgParser(args)
        guard opts.pid("--pid") != nil else { throw CLIError.missingPID }
        let deltaY = Int32(opts.int("--delta-y") ?? -300)
        let deltaX = Int32(opts.int("--delta-x") ?? 0)
        CGEvent(scrollWheelEvent2Source: nil, units: .pixel, wheelCount: 2, wheel1: deltaY, wheel2: deltaX, wheel3: 0)!.post(tap: .cghidEventTap)
        print("{\"status\":\"ok\",\"scrolled\":{\"dx\":\(deltaX),\"dy\":\(deltaY)}}")
    }
}
