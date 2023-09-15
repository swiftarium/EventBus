public protocol SubscriptionToken: Equatable {
    var id: String { get }

    static func == (lhs: Self, rhs: Self) -> Bool
    static func == (lhs: Self, rhs: (any SubscriptionToken)?) -> Bool
}

extension SubscriptionToken {
    static func == (lhs: Self, rhs: Self) -> Bool { lhs.id == rhs.id }
    static func == (lhs: Self, rhs: (any SubscriptionToken)?) -> Bool { lhs.id == rhs?.id }
}

struct DefaultToken: SubscriptionToken {
    static var counter: UInt = 0

    let id: String

    init() {
        Self.counter += 1
        self.id = "\(Self.counter)"
    }
}
