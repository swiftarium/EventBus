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

    private struct Subscription<Subscriber: AnyObject> {
        var token: (any SubscriptionToken)?
        var subscriber: WeakRef<Subscriber>
        var callback: AnyEventCallback
    }

    private var subscriptionsMap: [Identifier: [Subscription<AnyObject>]] = [:]
    private let tokenProvider: TokenProvider

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

        subscriptionsMap[Identifier(event), default: []].append(.init(
            token: nil,
            subscriber: .init(subscriber),
            callback: anyCallback
        ))
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

        let token = tokenProvider()
        subscriptionsMap[Identifier(event), default: []].append(.init(
            token: token,
            subscriber: .init(nil),
            callback: anyCallback
        ))

        return token
    }

    /// Unsubscribe a specific subscriber from a particular event.
    ///
    /// - Parameters:
    ///   - event: Type of the event.
    ///   - subscriber: Object to unsubscribe.
    public func off<Subscriber: AnyObject, Event: EventProtocol>(_ event: Event.Type, by subscriber: Subscriber) {
        subscriptionsMap[Identifier(event)]?.removeAll {
            !isValid(subscription: $0) || $0.subscriber == subscriber
        }
    }

    /// Unsubscribe from a particular event using a subscription token.
    ///
    /// - Parameters:
    ///   - event: Type of the event.
    ///   - token: Token representing the subscription to be removed.
    public func off<Token: SubscriptionToken, Event: EventProtocol>(_ event: Event.Type, by token: Token) {
        subscriptionsMap[Identifier(event)]?.removeAll {
            !isValid(subscription: $0) || token == $0.token
        }
    }

    /// Reset all subscriptions associated with a particular subscriber.
    ///
    /// - Parameters:
    ///   - subscriber: The subscriber whose subscriptions should be reset.
    public func reset<Subscriber: AnyObject>(by subscriber: Subscriber) {
        subscriptionsMap.keys.forEach { key in
            subscriptionsMap[key]?.removeAll {
                !isValid(subscription: $0) || $0.subscriber == subscriber
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
        let id = Identifier(event)
        let subscriptions = subscriptionsMap[id]
        subscriptionsMap[id] = subscriptions?.filter { subscription in
            guard isValid(subscription: subscription) else { return false }
            subscription.callback(subscription.subscriber.value, event.payload)
            return true
        }
        if let subscriptions, subscriptions.isEmpty {
            subscriptionsMap.removeValue(forKey: id)
        }
    }

    private func isValid(subscription: Subscription<AnyObject>) -> Bool {
        return subscription.subscriber.value != nil || subscription.token != nil
    }
}
