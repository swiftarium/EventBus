# EventBus

The `EventBus` provides a centralized event dispatching system, allowing objects within an application to communicate without needing to have direct references to each other. Events can be defined, subscribed to, and emitted, facilitating loose coupling and clean architecture.

## Installation

### Swift Package Manager

To install `EventBus` into your Xcode project using SPM, add it to the dependencies value of your Package.swift:

```swift
dependencies: [
    .package(url: "https://github.com/jinyongp/EventBus.git", from: "1.0.0"),
]
```

## Usage 

### Define an Event

To define a new event, conform to the EventProtocol:

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
EventBus.shared.emit(UserLoggedIn(payload: someUser))
```

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

Or unsubscribe all events by using self

```swift
EventBus.shared.reset(by: self)
```

## Test

To run the included tests, use the command:

```bash
$ swift test
```

## License

This library is released under the MIT license. See [LICENSE](/LICENSE) for details.
