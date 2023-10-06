@testable import EventBus
import XCTest

class EventBusMemoryLeakTests: XCTestCase {
    var eventBus: EventBus!
    let value = "Hello, World!"

    class TestSubscriber {
        let num: Int

        init(num: Int = 0) {
            self.num = num
        }
    }

    struct TestEvent: EventProtocol {
        typealias Payload = String
        let payload: Payload
    }

    override func setUp() {
        super.setUp()

        let config = EventBus.Config(cleanFrequency: { _ in
            .milliseconds(500)
        })
        eventBus = EventBus(config: config)
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

    func testMemoryLeakForSubscriber() {
        let iterations = 100000

        var subscribers: [TestSubscriber?] = (1 ... iterations).map { TestSubscriber(num: $0) }
        subscribers.forEach {
            eventBus.on(TestEvent.self, by: $0) { _, _ in
                XCTFail()
            }
        }
        subscribers.removeAll { $0!.num % 2 == 0 }
        sleep(3)

        if let value = eventBus.subscriptionsMap.values.first {
            XCTAssertEqual(value.items.count, iterations / 2)
        }

        subscribers.removeAll { $0!.num % 2 == 1 }
        sleep(3)

        if let value = eventBus.subscriptionsMap.values.first {
            XCTAssertTrue(value.items.isEmpty)
        }
    }
}
