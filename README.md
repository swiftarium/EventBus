# EventBus

[한글문서 KOREAN](/README_ko.md)

## Overview

`EventBus` is a Swift library that simplifies the implementation of event-based programming. It allows you to define, subscribe to, and publish events with ease.

## Key Features

- Define and publish events with type safety.
- Store subscriber objects with weak references to prevent memory leaks.
- Automatically remove the subscription when the subscriber object is deallocated.
- Provide a thread-safety implementation to prevent concurrency issues in a multi-threaded environment.

## Installation

### Swift Package Manager

To install `EventBus` via SPM, add the following to the `dependencies` value of your `Package.swift`.

```swift
dependencies: [
    .package(url: "https://github.com/swiftarium/EventBus.git", from: "1.1.1"),
]
```

Then, specify `"EventBus"` as a dependency for the target that will use it.

```swift
targets: [
    .target(name: "YourTarget", dependencies: ["EventBus"]),
]
```

## API Reference

### EventProtocol

```swift
protocol EventProtocol {
    associatedtype Payload

    var payload: Payload { get }
}
```

`EventProtocol` is a protocol used to define new events. You can specify the type of `Payload` that will be sent when the event is triggered.

```swift
struct UserLoggedInEvent: EventProtocol {
    typealias Payload = User

    let payload: Payload
}
```

You can define the `Payload` in various ways other than using `typealias`.

```swift
struct UserLoggedInEvent: EventProtocol {
    struct Payload {
        let user: User
    }

    let payload: Payload
}
```

If you don't want to pass a `Payload`, use the `Void` type.

```swift
struct UserLoggedInEvent: EventProtocol {
    let payload: Void = ()
}
```

### EventBus

```swift
/// Subscribe to a given event.
func on<Event>(Event.Type, (Event.Payload) -> Void) -> any SubscriptionToken
func on<Subscriber, Event>(Event.Type, by: Subscriber?, EventCallback<Subscriber, Event>)

/// Unsubscribe from a given event for a specific subscriber.
func off<Token, Event>(Event.Type, by: Token)
func off<Subscriber, Event>(Event.Type, by: Subscriber)

/// Cancel all subscriptions for a given subscriber.
func reset<Subscriber>(by: Subscriber)

/// Publish a given event.
func emit<Event>(Event)
```

With `EventBus`, you can easily subscribe to and publish events. Access the shared instance through the `shared` type property.

```swift
// Subscribe
let token = EventBus.shared.on(UserLoggedInEvent.self) { user in
    print("\(user.name) has logged in.")
}

// Subscribe with a subscriber
EventBus.shared.on(UserLoggedInEvent.self, by: self) { subscriber, user in
    print("\(user.name) has logged in.")
}

// Publish
EventBus.shared.emit(UserLoggedInEvent(payload: user)) 
```

You can unsubscribe by providing either the `SubscriptionToken` or the subscriber object.

```swift
// Unsubscribe with a token
EventBus.shared.off(UserLoggedInEvent.self, by: token)

// Unsubscribe with a subscriber
EventBus.shared.off(UserLoggedInEvent.self, by: self)
```

You can cancel all event subscriptions by providing the subscriber object.

```swift
// Cancel all subscriptions
EventBus.shared.reset(by: self)
```

By passing `EventBus.Config`, you can create a new `EventBus` instance.

- `tokenProvider`: A closure that provides a token generator conforming to the `SubscriptionToken` protocol.
- `cleanFrequency`: Specifies the frequency to clean up the subscriptions. Passes the current subscriber count and returns a value of type `DispatchTimeInterval`.

```swift
let config = EventBus.Config(tokenProvider: customTokenProvider, cleanFrequency: customFrequency)
let customEventBus = EventBus(config: config)
```

## Testing

```bash
$ swift test
```

## License

This library is released under the MIT license. See [LICENSE](/LICENSE) for details.