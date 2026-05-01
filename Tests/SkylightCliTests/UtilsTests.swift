import XCTest
@testable import skylight
final class UtilsTests: XCTestCase {
    func test_skylight_version_defined() { XCTAssertFalse(SKYLIGHT_VERSION.isEmpty); XCTAssertEqual(SKYLIGHT_VERSION, "0.2.0") }
    func test_missing_pid_error() { let e = CLIError.missingPID; XCTAssertEqual(e.code, "missing_pid"); XCTAssertEqual(e.exitCode, 2) }
    func test_element_not_found_error() { let e = CLIError(code: "element_not_found", message: "idx 5", exitCode: 3); XCTAssertEqual(e.exitCode, 3) }
    func test_json_error_output() { let e = CLIError(code: "timeout", message: "15s", exitCode: 5, context: ["pid":"1234"]); XCTAssertEqual(e.context?["pid"], "1234") }
    func test_environment_debug_default_off() { XCTAssertFalse(SKLEnvironment.isDebug) }
    func test_version_matches_semver() { let p = SKYLIGHT_VERSION.split(separator: "."); XCTAssertEqual(p.count, 3) }
}
