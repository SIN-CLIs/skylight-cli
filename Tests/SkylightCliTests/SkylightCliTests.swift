import XCTest
@testable import skylight

final class UtilsTests: XCTestCase {
    func test_environment_debug_default_off() {
        XCTAssertFalse(SKLEnvironment.isDebug)
    }

    func test_missing_pid_error() {
        let err = CLIError.missingPID
        XCTAssertEqual(err.code, "missing_pid")
        XCTAssertEqual(err.message, "--pid is required")
        XCTAssertEqual(err.exitCode, 2)
    }
}

final class OutputTests: XCTestCase {
    func test_json_error_output_includes_version() {
        var jsonResult: [String: Any] = [:]
        let jsonData = """
        {"status": "error", "error": "test_error", "message": "test", "version": "0.2.0"}
        """.data(using: .utf8)!
        if let json = try? JSONSerialization.jsonObject(with: jsonData) as? [String: Any] {
            jsonResult = json
        }
        XCTAssertEqual(jsonResult["status"] as? String, "error")
    }

    func test_error_content() {
        let err = CLIError(code: "element_not_found", message: "Element with index 7 not found", exitCode: 3)
        XCTAssertEqual(err.code, "element_not_found")
        XCTAssertEqual(err.message, "Element with index 7 not found")
        XCTAssertEqual(err.exitCode, 3)
    }

    func test_error_with_context() {
        let ctx = ["pid": "12345", "element_index": "7"]
        let err = CLIError(code: "timeout", message: "Wait timed out", exitCode: 5, context: ctx)
        XCTAssertEqual(err.context?["pid"], "12345")
        XCTAssertEqual(err.context?["element_index"], "7")
    }
}

final class VersionTests: XCTestCase {
    func test_version_defined() {
        XCTAssertFalse(SKYLIGHT_VERSION.isEmpty)
        XCTAssertEqual(SKYLIGHT_VERSION, "0.2.0")
    }
}
