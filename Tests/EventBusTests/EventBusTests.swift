import XCTest
@testable import EventBus

final class EventBusTests: XCTestCase {
    func testExample() throws {
        // This is an example of a functional test case.
        // Use XCTAssert and related functions to verify your tests produce the correct
        // results.
        XCTAssertEqual(EventBus().text, "Hello, World!")
    }
}
