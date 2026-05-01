import XCTest
@testable import skylight
final class AXElementFinderTests: XCTestCase {
    func test_interacting_roles_contains_button() { XCTAssertTrue(AXElementFinder.interactingRoles.contains("AXButton")) }
    func test_interacting_roles_contains_link() { XCTAssertTrue(AXElementFinder.interactingRoles.contains("AXLink")) }
    func test_interacting_roles_contains_textfield() { XCTAssertTrue(AXElementFinder.interactingRoles.contains("AXTextField")) }
    func test_interacting_roles_contains_checkbox() { XCTAssertTrue(AXElementFinder.interactingRoles.contains("AXCheckBox")) }
    func test_interacting_roles_count_minimum() { XCTAssertGreaterThanOrEqual(AXElementFinder.interactingRoles.count, 8) }
    func test_webarea_in_roles() { XCTAssertTrue(AXElementFinder.interactingRoles.contains("AXWebArea")) }
}
