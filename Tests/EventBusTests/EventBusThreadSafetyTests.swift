@testable import EventBus
import XCTest

final class EventBusThreadSafetyTests: XCTestCase {
    struct TestEvent: EventProtocol {
        struct Payload {
            let number: Int
        }

        let payload: Payload
    }

    class TestSubscriber {}

    private var eventBus: EventBus!

    override func setUp() {
        super.setUp()
        eventBus = EventBus()
    }

    func testConcurrentSubscribe() {
        let iterations = 100000
        let expect = expectation(description: "Concurrent subscribes")
        expect.expectedFulfillmentCount = iterations * 2

        DispatchQueue.concurrentPerform(iterations: iterations) { _ in
            eventBus.on(TestEvent.self) { payload in
                XCTAssertNotNil(payload.number)
                expect.fulfill()
            }

            eventBus.on(TestEvent.self, by: self) { _, payload in
                XCTAssertNotNil(payload.number)
                expect.fulfill()
            }
        }

        eventBus.emit(TestEvent(payload: .init(number: 0)))

        waitForExpectations(timeout: 1.0)
    }

    func testConcurrentEmissions() {
        let iterations = 100000
        let expect = expectation(description: "Concurrent emissions")
        expect.expectedFulfillmentCount = iterations * 2

        eventBus.on(TestEvent.self) { payload in
            XCTAssertNotNil(payload.number)
            expect.fulfill()
        }

        eventBus.on(TestEvent.self, by: self) { _, payload in
            XCTAssertNotNil(payload.number)
            expect.fulfill()
        }

        DispatchQueue.concurrentPerform(iterations: iterations) { iteration in
            self.eventBus.emit(TestEvent(payload: .init(number: iteration)))
        }

        waitForExpectations(timeout: 1)
    }

    func testConcurrentUnsubscribes() {
        let iterations = 1000
        let expect = expectation(description: "Concurrent emissions")
        expect.expectedFulfillmentCount = iterations

        var tokens = [any SubscriptionToken]()
        for _ in 0 ..< iterations {
            tokens.append(eventBus.on(TestEvent.self) { _ in
                XCTFail("Callback should be not called after unsubscribing")
            })

            eventBus.on(TestEvent.self, by: self) { _, _ in
                XCTFail("Callback should be not called after unsubscribing")
            }
        }

        DispatchQueue.concurrentPerform(iterations: iterations) { iteration in
            let token = tokens[iteration]
            self.eventBus.off(TestEvent.self, by: token)
            self.eventBus.off(TestEvent.self, by: self)
            expect.fulfill()
        }

        wait(for: [expect], timeout: 10)
        eventBus.emit(TestEvent(payload: .init(number: 0)))
        sleep(1)
    }

    func testConcurrentResets() {
        let iterations = 10000
        let expectation = XCTestExpectation(description: "Concurrent resets")
        expectation.expectedFulfillmentCount = iterations

        let subscriber = TestSubscriber()

        for _ in 0 ..< iterations {
            eventBus.on(TestEvent.self, by: subscriber) { subscriber, payload in
                XCTFail("Callback should be not called after reseting")
            }
        }

        DispatchQueue.concurrentPerform(iterations: iterations) { _ in
            self.eventBus.reset(by: subscriber)
            expectation.fulfill()
        }

        wait(for: [expectation], timeout: 10)
        eventBus.emit(TestEvent(payload: .init(number: 0)))
        sleep(1)
    }
}
