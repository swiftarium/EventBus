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
        switch (lhs, rhs) {
        case let (.token(lhsToken), .token(rhsToken)):
            return lhsToken.id == rhsToken.id
        case let (.subscriber(lhsSubscriber), .subscriber(rhsSubscriber)):
            return lhsSubscriber == rhsSubscriber
        default:
            return false
        }
    }

    func hash(into hasher: inout Hasher) {
        switch self {
        case let .token(token): hasher.combine(token.id)
        case let .subscriber(subscriber): hasher.combine(subscriber)
        }
    }
}
