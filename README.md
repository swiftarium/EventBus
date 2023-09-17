# EventBus

`EventBus` provides a centralized hub for dispatching and listening to events throughout an application. Using this class allows for event-driven communication while maintaining loose coupling between objects.


## Features

1. Concurrency Control: The EventBus supports concurrent access from multiple threads, ensuring thread safety.
2. Memory Safety: Subscribers are stored as weak references, preventing memory leaks.
3. Token & Subscriber Based Subscriptions: Subscribe to events using either a subscriber object or a token.
4. Automatic Cleanup: Subscriptions that are no longer required are automatically cleaned up, enhancing memory efficiency.

## Installation

### Swift Package Manager

To install `EventBus` into your Xcode project using SPM, add it to the dependencies value of your Package.swift:

```swift
dependencies: [
    .package(url: "https://github.com/jinyongp/EventBus.git", from: "1.1.0"),
]
```

And specify `"EventBus"` as a dependency of the Target in which you wish to use `EventBus`.

```swift
targets: [
    .target(name: "YourTarget", dependencies: ["EventBus"]),
]
```

## Usage 

### Define an Event

To define a new event, conform to the `EventProtocol`:

```swift
struct UserLoggedIn: EventProtocol {
    typealias Payload = User

    let payload: Payload
}
```

A Payload can be defined another way.

```swift
struct UserLoggedIn: EventProtocol {
    struct Payload {
        let user: User
    }

    let payload: Payload
}

struct UserLoggedIn: EventProtocol {
    struct Payload {
        let completion: (User) -> Void
    }

    let payload: Payload
}
```

### Subscribe to an Event

Using the shared EventBus instance, subscribe to the event:

```swift
EventBus.shared.on(UserLoggedIn.self, by: self) { subscriber, user in
    print("\(user.name) has logged in!")
}
```

Or without specifying a subscriber:

```swift
let token = EventBus.shared.on(UserLoggedIn.self) { user in
    print("\(user.name) has logged in!")
}
```

### Emit an Event

To notify all subscribers of a particular event:

```swift
EventBus.shared.emit(UserLoggedIn(payload: user))
```

After the event is emitted, all subscribers will be notified.

### Unsubscribe from an Event

You can unsubscribe in multiple ways:

Using a subscriber:

```swift
EventBus.shared.off(UserLoggedIn.self, by: self)
```

Using a token:

```swift
EventBus.shared.off(UserLoggedIn.self, by: token)
```

Or unsubscribe all events by passing subscriber

```swift
EventBus.shared.reset(by: self)
```

After unsubscribing, the subscriber will no longer be notified of the event.

## Test

To run the included tests, use the command:

```bash
$ swift test
```

## License

This library is released under the MIT license. See [LICENSE](/LICENSE) for details.
