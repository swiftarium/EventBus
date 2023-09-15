public protocol SubscriptionToken {
    var id: String { get }
}

struct DefaultToken: SubscriptionToken {
    static var counter: UInt = 0

    let id: String

    init() {
        Self.counter += 1
        self.id = "\(Self.counter)"
    }
}
