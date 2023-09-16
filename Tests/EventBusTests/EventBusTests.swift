@testable import EventBus
import XCTest

final class EventBusTests: XCTestCase {
    var eventBus: EventBus!
    
    struct TestEvent: EventProtocol {
        typealias Payload = String
        let payload: Payload
    }

    struct TestEvent1: EventProtocol {
        typealias Payload = String
        let payload: Payload
    }

    struct TestEvent2: EventProtocol {
        typealias Payload = String
        let payload: Payload
    }

    struct TestEventWithCallback: EventProtocol {
        struct Payload {
            let handler: (String) -> Void
        }

        let payload: Payload
    }

    class TestSubscriber {}
    class TestSubscriber1 {}
    class TestSubscriber2 {}
    
    override func setUp() {
        super.setUp()
        eventBus = EventBus()
    }

    func testSubscriber() {
        let value = "Hello, World!"

        let expectation = self.expectation(description: "subscribe")
        expectation.expectedFulfillmentCount = 2

        eventBus.on(TestEvent.self) { payload in
            XCTAssertEqual(payload, value)
            expectation.fulfill()
        }

        eventBus.on(TestEvent.self, by: self) { _, payload in
            XCTAssertEqual(payload, value)
            expectation.fulfill()
        }

        eventBus.emit(TestEvent(payload: value))
        waitForExpectations(timeout: 1.0)
    }

    func testMultipleEmit() {
        let expectation = self.expectation(description: "multiple emit")

        let count = 10
        let value = "Hello, World!"
        expectation.expectedFulfillmentCount = 10 * 2

        eventBus.on(TestEvent.self) { payload in
            XCTAssertEqual(payload, value)
            expectation.fulfill()
        }

        eventBus.on(TestEvent.self, by: self) { _, payload in
            XCTAssertEqual(payload, value)
            expectation.fulfill()
        }

        (0 ..< count).forEach { _ in eventBus.emit(TestEvent(payload: value)) }

        waitForExpectations(timeout: 1.0)
    }

    func testMultipleEventTypes() {
        let expectation1 = self.expectation(description: "test event1 emit")
        let expectation2 = self.expectation(description: "test event2 emit")

        let value1 = "Event1 Payload"
        let value2 = "Event2 Payload"

        eventBus.on(TestEvent1.self) { payload in
            XCTAssertEqual(payload, value1)
            expectation1.fulfill()
        }

        eventBus.on(TestEvent2.self) { payload in
            XCTAssertEqual(payload, value2)
            expectation2.fulfill()
        }

        eventBus.emit(TestEvent1(payload: value1))
        eventBus.emit(TestEvent2(payload: value2))

        waitForExpectations(timeout: 1.0)
    }

    func testUnsubscribe() {
        let token = eventBus.on(TestEvent.self) { _ in
            XCTFail("Callback should not be called after unsubscribing")
        }
        eventBus.off(TestEvent.self, by: token)
        eventBus.emit(TestEvent(payload: "Hello, World!"))
        sleep(1)
    }

    func testUnsubscribeWithObject() {
        eventBus.on(TestEvent.self, by: self) { _, _ in
            XCTFail("Callback should not be called after unsubscribing")
        }
        eventBus.off(TestEvent.self, by: self)
        eventBus.emit(TestEvent(payload: "Hello, World!"))
        sleep(1)
    }

    func testReset() {
        let eventBus = EventBus()

        let value = "Hello, World!"

        let expectation = self.expectation(description: "reset")
        expectation.expectedFulfillmentCount = 3

        eventBus.on(TestEvent.self) { payload in
            XCTAssertEqual(payload, value)
            expectation.fulfill()
        }

        eventBus.on(TestEvent1.self) { payload in
            XCTAssertEqual(payload, value)
            expectation.fulfill()
        }

        eventBus.on(TestEvent2.self) { payload in
            XCTAssertEqual(payload, value)
            expectation.fulfill()
        }

        eventBus.on(TestEvent.self, by: self) { _, _ in
            XCTFail("Callback should not be called after unsubscribing")
        }

        eventBus.on(TestEvent1.self, by: self) { _, _ in
            XCTFail("Callback should not be called after unsubscribing")
        }

        eventBus.on(TestEvent2.self, by: self) { _, _ in
            XCTFail("Callback should not be called after unsubscribing")
        }

        eventBus.reset(by: self)

        eventBus.emit(TestEvent(payload: value))
        eventBus.emit(TestEvent1(payload: value))
        eventBus.emit(TestEvent2(payload: value))
        sleep(1)
        waitForExpectations(timeout: 1.0)
    }

    func testWeakReferences() {
        let eventBus = EventBus()
        var subscriber1: TestSubscriber? = TestSubscriber()
        let subscriber2: TestSubscriber? = TestSubscriber()
        var subscriber3: TestSubscriber? = TestSubscriber()

        let expectation = self.expectation(description: "weak references")
        let value = "Hello, World!"

        eventBus.on(TestEvent.self, by: subscriber1) { _, _ in
            XCTFail("Callback should not be called after object is released")
        }

        eventBus.on(TestEvent.self, by: subscriber2) { [weak subscriber2] subscriber, payload in
            XCTAssertIdentical(subscriber, subscriber2)
            XCTAssertEqual(payload, value)
            expectation.fulfill()
        }

        eventBus.on(TestEvent.self, by: subscriber3) { _, _ in
            XCTFail("Callback should not be called after object is released")
        }

        subscriber1 = nil
        subscriber3 = nil

        eventBus.emit(TestEvent(payload: value))
        waitForExpectations(timeout: 1.0)
    }

    func testCallbackPayload() {
        let eventBus = EventBus()

        let expectation = self.expectation(description: "callback")
        expectation.expectedFulfillmentCount = 2

        let value = "Hello, World!"

        eventBus.on(TestEventWithCallback.self) { payload in
            payload.handler(value)
        }

        eventBus.on(TestEventWithCallback.self, by: self) { _, payload in
            payload.handler(value)
        }

        eventBus.emit(TestEventWithCallback(payload: .init(handler: { string in
            XCTAssertEqual(string, value)
            expectation.fulfill()
        })))

        waitForExpectations(timeout: 1.0)
    }
}
