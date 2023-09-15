public final class EventBus {
    public static let shared: EventBus = .init()

    private struct WeakRef<T: AnyObject> {
        weak var value: T?
        var isAlive: Bool { value != nil }

        init(_ value: T?) {
            self.value = value
        }
    }

    public typealias EventCallback<Subscriber: AnyObject, Event: EventProtocol> = ((subscriber: Subscriber, payload: Event.Payload)) -> Void
    public typealias AnyEventCallback = ((subscriber: AnyObject?, payload: Any)) -> Void
    public typealias TokenProvider = () -> any SubscriptionToken

    public struct Config {
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

    public func on<Subscriber: AnyObject, Event: EventProtocol>(
        _ event: Event.Type,
        by subscriber: Subscriber,
        _ callback: @escaping EventCallback<Subscriber, Event>
    ) {
        let anyCallback: AnyEventCallback = { args in
            if let subscriber = args.subscriber as? Subscriber,
               let payload = args.payload as? Event.Payload
            { callback((subscriber, payload)) }
        }
        let subscription: Subscription<AnyObject> = Subscription(
            token: nil,
            subscriber: .init(subscriber),
            callback: anyCallback
        )
        subscriptionsMap[Identifier(event), default: []].append(subscription)
    }

    public func on<Event: EventProtocol>(
        _ event: Event.Type,
        _ callback: @escaping (_ payload: Event.Payload) -> Void
    ) -> any SubscriptionToken {
        let anyCallback: AnyEventCallback = { args in
            if let payload = args.payload as? Event.Payload {
                callback(payload)
            }
        }
        let subscription: Subscription<AnyObject> = Subscription(
            token: tokenProvider(),
            subscriber: .init(nil),
            callback: anyCallback
        )
        subscriptionsMap[Identifier(event), default: []].append(subscription)
        return subscription.token!
    }

    public func off<Subscriber: AnyObject, Event: EventProtocol>(_ event: Event, by subscriber: Subscriber) {
        subscriptionsMap[Identifier(event)]?.removeAll { !$0.subscriber.isAlive || $0.subscriber.value === subscriber }
    }

    public func reset(by subscriber: AnyObject) {
        subscriptionsMap.keys.forEach { key in subscriptionsMap[key]?.removeAll { $0.subscriber.value === subscriber } }
    }

    public func reset(by token: SubscriptionToken) {
        subscriptionsMap.keys.forEach { key in subscriptionsMap[key]?.removeAll { $0.token?.id == token.id } }
    }

    public func emit<Event: EventProtocol>(_ event: Event) {
        let id = Identifier(event)
        let subscriptions = subscriptionsMap[id]
        subscriptionsMap[id] = subscriptions?.filter { subscription in
            guard subscription.subscriber.isAlive || subscription.token != nil else { return false }
            subscription.callback((subscription.subscriber.value, event.payload))
            return true
        }
        if let subscriptions, subscriptions.isEmpty {
            subscriptionsMap.removeValue(forKey: id)
        }
    }
}
