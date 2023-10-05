import AutoCleaner
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
        var tokenProvider: TokenProvider?
        var cleanFrequency: AutoCleaner.Frequency?
        var dispatchQueue: DispatchQueue?
    }

    struct Subscription {
        var callback: AnyEventCallback
    }

    typealias SubscriptionWrapper = AutoCleaner<[SubscriptionIdentifier: Subscription]>
    var subscriptionsMap: [Identifier: SubscriptionWrapper] = [:]
    let tokenProvider: TokenProvider
    let cleanFrequency: AutoCleaner.Frequency

    private(set) var queue: DispatchQueue
    private func read<T>(_ action: () -> T) -> T { queue.sync { action() } }
    private func write<T>(_ action: () -> T) -> T { queue.sync(flags: .barrier) { action() } }

    public init(config: Config? = nil) {
        self.queue = config?.dispatchQueue ?? DispatchQueue(label: "com.event-bus.queue", attributes: .concurrent)
        self.tokenProvider = config?.tokenProvider ?? { DefaultToken() }
        self.cleanFrequency = config?.cleanFrequency ?? { count in
            let interval = (min: 10.0, max: 120.0)
            let rate = (interval.max - interval.min) / 100.0
            let frequency = interval.max - (rate * Double(count))
            return .seconds(Int(max(min(frequency, interval.max), interval.min)))
        }
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
    ///   eventBus.on(UserLoggedInEvent.self, by: self) { subscriber, payload in
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
            let subscription: Subscription = .init(callback: anyCallback)
            let identifier: SubscriptionIdentifier = .subscriber(.init(subscriber))
            updateSubscription(subscription, for: identifier, in: event)
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
            let token = tokenProvider()
            let subscription: Subscription = .init(callback: anyCallback)
            let identifier: SubscriptionIdentifier = .token(token)
            updateSubscription(subscription, for: identifier, in: event.self)
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
            subscriptionsMap[Identifier(event)]?.items.removeValue(forKey: identifier)
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
            subscriptionsMap[Identifier(event)]?.items.removeValue(forKey: identifier)
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
                subscriptionsMap[key]?.items.removeValue(forKey: identifier)
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
    ///   eventBus.emit(UserLoggedInEvent(payload: user))
    ///   ```
    public func emit<Event: EventProtocol>(_ event: Event) {
        read {
            let subscriptionWrapper = subscriptionsMap[Identifier(event)]
            subscriptionWrapper?.clean()
            return subscriptionWrapper?.items
        }?.forEach { identifier, subscription in
            guard identifier.isValid else { return }
            switch identifier {
            case .token: subscription.callback(nil, event.payload)
            case let .subscriber(subscriber): subscription.callback(subscriber.value, event.payload)
            }
        }
    }

    private func updateSubscription<Event: EventProtocol>(
        _ subscription: Subscription,
        for identifier: SubscriptionIdentifier,
        in event: Event.Type
    ) {
        let id = Identifier(event)
        if let cleaner = subscriptionsMap[id] {
            cleaner.items.updateValue(subscription, forKey: identifier)
        } else {
            subscriptionsMap[id] = .init([identifier: subscription]) { element in
                !element.key.isValid
            }.start(cleanFrequency)
        }
    }
}
