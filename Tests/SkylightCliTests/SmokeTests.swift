import XCTest; import Foundation
final class SmokeTests: XCTestCase {
    func testVersion() throws {
        let p = Process(); p.executableURL = URL(fileURLWithPath: "/usr/bin/env")
        p.arguments = ["~/.local/bin/skylight-cli", "version"]
        let pipe = Pipe(); p.standardOutput = pipe
        try p.run(); p.waitUntilExit()
        let out = String(data: pipe.fileHandleForReading.readDataToEndOfFile(), encoding: .utf8) ?? ""
        XCTAssertFalse(out.isEmpty); XCTAssertEqual(p.terminationStatus, 0)
    }
}
