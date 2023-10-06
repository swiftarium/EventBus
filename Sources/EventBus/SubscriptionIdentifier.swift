import Foundation
import WeakRef

enum SubscriptionIdentifier: Hashable {
    case token(any SubscriptionToken)
    case subscriber(WeakRef<AnyObject>)

    var isValid: Bool {
        if case let .subscriber(weakSubscriber) = self {
            return weakSubscriber.isValid
        }
        return true
    }

    static func == (lhs: SubscriptionIdentifier, rhs: SubscriptionIdentifier) -> Bool {
        lhs.hashValue == rhs.hashValue
    }

    func hash(into hasher: inout Hasher) {
        switch self {
        case let .token(token):
            hasher.combine(token.id)
        case let .subscriber(subscriber):
            subscriber.isValid
                ? hasher.combine(subscriber)
                : hasher.combine(UUID())
        }
    }
}
