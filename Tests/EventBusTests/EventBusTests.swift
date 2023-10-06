@testable import EventBus
import XCTest

final class EventBusTests: XCTestCase {
    var eventBus: EventBus!
    let value = "Hello, World!"

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

    func testSubscribe() {
        let expect = expectation(description: "subscribe")
        expect.expectedFulfillmentCount = 2

        eventBus.on(TestEvent.self) { payload in
            XCTAssertEqual(payload, self.value)
            expect.fulfill()
        }

        eventBus.on(TestEvent.self, by: self) { subscriber, payload in
            XCTAssertEqual(payload, subscriber.value)
            expect.fulfill()
        }

        eventBus.emit(TestEvent(payload: value))
        waitForExpectations(timeout: 1.0)
    }

    func testSubscriberIsNil() {
        let optionalSubscriber: TestSubscriber? = nil
        eventBus.on(TestEvent.self, by: optionalSubscriber) { _, _ in
            XCTFail("Callback should not be called if subscriber not exists")
        }

        eventBus.emit(TestEvent(payload: value))
        sleep(1)
    }

    func testMultipleSubscribeByToken() {
        let iterations = 100000
        let expect = expectation(description: "multiple subscribe by token")
        expect.expectedFulfillmentCount = iterations

        for _ in 0 ..< iterations {
            eventBus.on(TestEvent.self) { payload in
                XCTAssertEqual(payload, self.value)
                expect.fulfill()
            }
        }

        eventBus.emit(TestEvent(payload: value))
        waitForExpectations(timeout: 1.0)
    }

    func testMultipleSubscribeBySubscriber() {
        let iterations = 100000
        let expect = expectation(description: "multiple subscribe by subscriber")
        expect.expectedFulfillmentCount = iterations

        let subscribers = (1 ... iterations).map { _ in TestSubscriber() }
        subscribers.forEach { subscriber in
            eventBus.on(TestEvent.self, by: subscriber) { [weak subscriber] sub, payload in
                XCTAssertIdentical(subscriber, sub)
                XCTAssertEqual(payload, self.value)
                expect.fulfill()
            }
        }

        eventBus.emit(TestEvent(payload: value))
        waitForExpectations(timeout: 1.0)
    }

    func testMultipleEmissions() {
        let iterations = 10000
        let expect = expectation(description: "multiple emit")
        expect.expectedFulfillmentCount = iterations * 2

        eventBus.on(TestEvent.self) { payload in
            XCTAssertEqual(payload, self.value)
            expect.fulfill()
        }

        eventBus.on(TestEvent.self, by: self) { subscriber, payload in
            XCTAssertEqual(payload, subscriber.value)
            expect.fulfill()
        }

        for _ in 0 ..< iterations {
            eventBus.emit(TestEvent(payload: value))
        }

        waitForExpectations(timeout: 1.0)
    }

    func testMultipleEventTypes() {
        let expect = expectation(description: "multiple event")
        expect.expectedFulfillmentCount = 2

        let value1 = "Event1 Payload"
        let value2 = "Event2 Payload"

        eventBus.on(TestEvent1.self) { payload in
            XCTAssertEqual(payload, value1)
            expect.fulfill()
        }

        eventBus.on(TestEvent2.self) { payload in
            XCTAssertEqual(payload, value2)
            expect.fulfill()
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
        let expect = expectation(description: "reset")
        expect.expectedFulfillmentCount = 3

        eventBus.on(TestEvent.self) { payload in
            XCTAssertEqual(payload, self.value)
            expect.fulfill()
        }

        eventBus.on(TestEvent1.self) { payload in
            XCTAssertEqual(payload, self.value)
            expect.fulfill()
        }

        eventBus.on(TestEvent2.self) { payload in
            XCTAssertEqual(payload, self.value)
            expect.fulfill()
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

    func testSubscribeWithNilObject() {
        let subscriber1: TestSubscriber? = nil
        eventBus.on(TestEvent.self, by: subscriber1) { _, _ in
            XCTFail("Callback should not be called")
        }
        eventBus.emit(TestEvent(payload: ""))
    }

    func testWeakReferences() {
        let expect = expectation(description: "weak references")

        var subscriber1: TestSubscriber? = TestSubscriber()
        let subscriber2: TestSubscriber? = TestSubscriber()
        var subscriber3: TestSubscriber? = TestSubscriber()

        eventBus.on(TestEvent.self, by: subscriber1) { _, _ in
            XCTFail("Callback should not be called after object is released")
        }

        eventBus.on(TestEvent.self, by: subscriber2) { [weak subscriber2] subscriber, payload in
            XCTAssertIdentical(subscriber, subscriber2)
            XCTAssertEqual(payload, self.value)
            expect.fulfill()
        }

        eventBus.on(TestEvent.self, by: subscriber3) { _, _ in
            XCTFail("Callback should not be called after object is released")
        }

        subscriber1 = nil
        subscriber3 = nil

        eventBus.emit(TestEvent(payload: value))
        waitForExpectations(timeout: 1.0)
    }

    func testSubscribeAfterReleasing() {
        var subscriber1: TestSubscriber? = .init()

        for _ in 1 ... 10000 {
            eventBus.on(TestEvent.self, by: subscriber1) { _, _ in }

            subscriber1 = nil
            subscriber1 = .init()
        }
    }

    func testCallbackPayload() {
        let expect = expectation(description: "callback")
        expect.expectedFulfillmentCount = 2

        eventBus.on(TestEventWithCallback.self) { payload in
            payload.handler(self.value)
        }

        eventBus.on(TestEventWithCallback.self, by: self) { subscriber, payload in
            payload.handler(subscriber.value)
        }

        eventBus.emit(TestEventWithCallback(payload: .init(handler: { string in
            XCTAssertEqual(string, self.value)
            expect.fulfill()
        })))

        waitForExpectations(timeout: 1.0)
    }
}
