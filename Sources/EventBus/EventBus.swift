public final class EventBus {
    public static let shared: EventBus = .init()

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
        by subscriber: Subscriber?,
        _ callback: @escaping EventCallback<Subscriber, Event>
    ) {
        let anyCallback: AnyEventCallback = { args in
            if let subscriber = args.subscriber as? Subscriber,
               let payload = args.payload as? Event.Payload
            { callback((subscriber, payload)) }
        }
        subscriptionsMap[Identifier(event), default: []].append(.init(
            token: nil,
            subscriber: .init(subscriber),
            callback: anyCallback
        ))
    }

    @discardableResult
    public func on<Event: EventProtocol>(
        _ event: Event.Type,
        _ callback: @escaping (_ payload: Event.Payload) -> Void
    ) -> any SubscriptionToken {
        let anyCallback: AnyEventCallback = { args in
            if let payload = args.payload as? Event.Payload {
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

    public func off<Subscriber: AnyObject, Event: EventProtocol>(_ event: Event.Type, by subscriber: Subscriber) {
        subscriptionsMap[Identifier(event)]?.removeAll { $0.subscriber.isEmpty || $0.subscriber == subscriber }
    }

    public func off<Token: SubscriptionToken, Event: EventProtocol>(_ event: Event.Type, by token: Token) {
        subscriptionsMap[Identifier(event)]?.removeAll { $0.subscriber.isEmpty || token == $0.token }
    }

    public func reset<Subscriber: AnyObject>(by subscriber: Subscriber) {
        subscriptionsMap.keys.forEach { key in
            subscriptionsMap[key]?.removeAll {
                $0.subscriber.isEmpty || $0.subscriber == subscriber
            }
        }
    }

    public func reset<Token: SubscriptionToken>(by token: Token) {
        subscriptionsMap.keys.forEach { key in
            subscriptionsMap[key]?.removeAll { token == $0.token }
        }
    }

    public func emit<Event: EventProtocol>(_ event: Event) {
        let id = Identifier(event)
        let subscriptions = subscriptionsMap[id]
        subscriptionsMap[id] = subscriptions?.filter { subscription in
            guard !subscription.subscriber.isEmpty || subscription.token != nil else { return false }
            subscription.callback((subscription.subscriber.value, event.payload))
            return true
        }
        if let subscriptions, subscriptions.isEmpty {
            subscriptionsMap.removeValue(forKey: id)
        }
    }
}
