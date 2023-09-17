import Dispatch
import WeakRef

/// `EventBus` provides a centralized hub to dispatch and listen to events throughout an application.
public final class EventBus {
    /// The shared instance of `EventBus`.
    public static let shared: EventBus = .init()

    /// The callback to be invoked when an event occurs.
    /// - Parameters:
    ///   - subscriber: The subscribing object.
    ///   - payload: The associated payload for the event.
    public typealias EventCallback<Subscriber: AnyObject, Event: EventProtocol> = (_ subscriber: Subscriber, _ payload: Event.Payload) -> Void

    /// A type-erased event callback.
    public typealias AnyEventCallback = (_ subscriber: AnyObject?, _ payload: Any) -> Void

    /// A function that returns a subscription token.
    public typealias TokenProvider = () -> any SubscriptionToken

    /// Configuration settings for `EventBus`.
    public struct Config {
        /// An optional custom token provider.
        let tokenProvider: TokenProvider?
    }

    private enum SubscriptionIdentifier: Hashable {
        case token(any SubscriptionToken)
        case subscriber(WeakRef<AnyObject>)

        var isValid: Bool {
            if case let .subscriber(weakSubscriber) = self {
                return weakSubscriber.hasValue
            }
            return true
        }

        static func == (lhs: EventBus.SubscriptionIdentifier, rhs: EventBus.SubscriptionIdentifier) -> Bool {
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

    private struct Subscription {
        var callback: AnyEventCallback
    }

    private var subscriptionsMap: [Identifier: [SubscriptionIdentifier: Subscription]] = [:]
    private let tokenProvider: TokenProvider

    private(set) var queue = DispatchQueue(label: "com.eventbus.queue", attributes: .concurrent)
    private func read<T>(_ action: () -> T) -> T { queue.sync { action() } }
    private func write<T>(_ action: () -> T) -> T { queue.sync(flags: .barrier) { action() } }

    init(config: Config? = nil) {
        self.tokenProvider = config?.tokenProvider ?? { DefaultToken() }
    }

    /// Subscribe to a specific event type, associating it with a subscriber.
    ///
    /// - Parameters:
    ///   - event: Type of the event.
    ///   - subscriber: Object that is subscribing to the event.
    ///   - callback: Function to be executed when the event is emitted.
    ///
    /// - Example:
    ///   ```swift
    ///   eventBus.on(UserLoggedIn.self, by: self) { subscriber, payload in
    ///       print("\(payload.name) has logged in!")
    ///   }
    ///   ```
    public func on<Subscriber: AnyObject, Event: EventProtocol>(
        _ event: Event.Type,
        by subscriber: Subscriber?,
        _ callback: @escaping EventCallback<Subscriber, Event>
    ) {
        let anyCallback: AnyEventCallback = { subscriber, payload in
            if let subscriber = subscriber as? Subscriber,
               let payload = payload as? Event.Payload
            { callback(subscriber, payload) }
        }
        write {
            let id = Identifier(event)
            let subscription: Subscription = .init(callback: anyCallback)
            let identifier: SubscriptionIdentifier = .subscriber(.init(subscriber))
            subscriptionsMap[id, default: [:]].updateValue(subscription, forKey: identifier)
        }
    }

    /// Subscribe to a specific event type and get a token for the subscription.
    /// This version does not require a subscriber.
    ///
    /// - Parameters:
    ///   - event: Type of the event.
    ///   - callback: Function to be executed when the event is emitted.
    /// - Returns: Token for the subscription which can be used for unsubscribing.
    ///
    /// - Example:
    ///   ```swift
    ///   let token = eventBus.on(UserLoggedOut.self) { payload in
    ///       print("\(payload.name) has logged out!")
    ///   }
    ///   ```
    @discardableResult
    public func on<Event: EventProtocol>(
        _ event: Event.Type,
        _ callback: @escaping (_ payload: Event.Payload) -> Void
    ) -> any SubscriptionToken {
        let anyCallback: AnyEventCallback = { _, payload in
            if let payload = payload as? Event.Payload {
                callback(payload)
            }
        }
        return write {
            let id = Identifier(event)
            let token = tokenProvider()
            let subscription: Subscription = .init(callback: anyCallback)
            let identifier: SubscriptionIdentifier = .token(token)
            subscriptionsMap[id, default: [:]].updateValue(subscription, forKey: identifier)
            return token
        }
    }

    /// Unsubscribe a specific subscriber from a particular event.
    ///
    /// - Parameters:
    ///   - event: Type of the event.
    ///   - subscriber: Object to unsubscribe.
    public func off<Subscriber: AnyObject, Event: EventProtocol>(_ event: Event.Type, by subscriber: Subscriber) {
        write {
            let identifier: SubscriptionIdentifier = .subscriber(.init(subscriber))
            subscriptionsMap[Identifier(event)]?.removeValue(forKey: identifier)
        }
    }

    /// Unsubscribe from a particular event using a subscription token.
    ///
    /// - Parameters:
    ///   - event: Type of the event.
    ///   - token: Token representing the subscription to be removed.
    public func off<Token: SubscriptionToken, Event: EventProtocol>(_ event: Event.Type, by token: Token) {
        write {
            let identifier: SubscriptionIdentifier = .token(token)
            subscriptionsMap[Identifier(event)]?.removeValue(forKey: identifier)
        }
    }

    /// Reset all subscriptions associated with a particular subscriber.
    ///
    /// - Parameters:
    ///   - subscriber: The subscriber whose subscriptions should be reset.
    public func reset<Subscriber: AnyObject>(by subscriber: Subscriber) {
        write {
            subscriptionsMap.keys.forEach { key in
                let identifier: SubscriptionIdentifier = .subscriber(.init(subscriber))
                subscriptionsMap[key]?.removeValue(forKey: identifier)
            }
        }
    }

    /// Emit a particular event to notify all its subscribers.
    ///
    /// - Parameters:
    ///   - event: The event instance to be emitted.
    ///
    /// - Example:
    ///   ```swift
    ///   eventBus.emit(UserLoggedIn(payload: user))
    ///   ```
    public func emit<Event: EventProtocol>(_ event: Event) {
        read { subscriptionsMap[Identifier(event)] }?.forEach { identifier, subscription in
            guard identifier.isValid else { return }
            switch identifier {
            case .token: subscription.callback(nil, event.payload)
            case let .subscriber(subscriber): subscription.callback(subscriber.value, event.payload)
            }
        }
    }
}
