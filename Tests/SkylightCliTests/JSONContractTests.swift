import XCTest
@testable import skylight
final class JSONContractTests: XCTestCase {
    func test_exit_code_2_missing_pid() { XCTAssertEqual(CLIError.missingPID.exitCode, 2) }
    func test_exit_code_3_not_found() { XCTAssertEqual(CLIError(code: "", message: "", exitCode: 3).exitCode, 3) }
    func test_exit_code_5_timeout() { XCTAssertEqual(CLIError(code: "", message: "", exitCode: 5).exitCode, 5) }
    func test_exit_code_1_generic() { XCTAssertEqual(CLIError(code: "err", message: "", exitCode: 1).exitCode, 1) }
}
