# EventBus

## 개요

`EventBus`는 이벤트를 정의하고, 구독하고, 발행하여 이벤트 기반 프로그래밍을 쉽게 구현할 수 있는 Swift 라이브러리입니다.

## 주요 기능

- 유형 안정성을 가진 이벤트를 정의하고 정의한 이벤트를 구독하고 발행할 수 있습니다.
- 구독자 객체를 약한 참조로 저장하여 메모리 누수를 방지합니다.
- 구독자 객체를 전달한 경우, 해당 객체가 해제될 때 구독을 자동으로 제거합니다.
- 쓰레드 안전한 구현을 제공하여 멀티 쓰레드 환경에서 동시성 문제를 방지합니다.

## 설치방법

### Swift Package Manager

SPM으로 `EventBus`를 설치하려면 `Package.swift`의 `dependencies` 배열에 추가하세요.

```swift
dependencies: [
    .package(url: "https://github.com/swiftarium/EventBus.git", from: "1.1.1"),
]
```

그리고, `EventBus`를 사용할 타겟의 의존성으로 `"EventBus"`를 지정하세요.

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

`EventProtocol`은 새로운 이벤트를 정의하기 위한 프로토콜입니다. 이벤트 발생 시 전달할 `Payload` 유형을 지정할 수 있습니다.

```swift
struct UserLoggedInEvent: EventProtocol {
    typealias Payload = User

    let payload: Payload
}
```

`typealias` 외에 다양한 방법으로 `Payload`를 정의할 수 있습니다.

```swift
struct UserLoggedInEvent: EventProtocol {
    struct Payload {
        let user: User
    }

    let payload: Payload
}
```

`Payload`를 전달하고 싶지 않다면 `Void` 타입을 사용하세요.

```swift
struct UserLoggedInEvent: EventProtocol {
    let payload: Void = ()
}
```

### EventBus

```swift
/// 주어진 이벤트를 구독합니다.
func on<Event>(Event.Type, (Event.Payload) -> Void) -> any SubscriptionToken
func on<Subscriber, Event>(Event.Type, by: Subscriber?, EventCallback<Subscriber, Event>)

/// 주어진 구독자의 이벤트 구독을 취소합니다.
func off<Token, Event>(Event.Type, by: Token)
func off<Subscriber, Event>(Event.Type, by: Subscriber)

/// 주어진 구독자의 모든 구독을 취소합니다.
func reset<Subscriber>(by: Subscriber)

/// 주어진 이벤트를 발행합니다.
func emit<Event>(Event)
```

`EventBus`를 통해 이벤트를 구독하고 발행할 수 있습니다. `shared` 타입 속성으로 공유 인스턴스에 접근할 수 있습니다.

```swift
// 구독
let token = EventBus.shared.on(UserLoggedInEvent.self) { user in
    print("\(user.name) 님이 로그인 했습니다.")
}

// 구독 (구독자 지정)
EventBus.shared.on(UserLoggedInEvent.self, by: self) { subscriber, user in
    print("\(user.name) 님이 로그인 했습니다.")
}

// 발행
EventBus.shared.emit(UserLoggedInEvent(payload: user)) 
```

구독을 해제하기 위해 `SubscriptionToken` 혹은 구독자 객체를 전달할 수 있습니다.

```swift
// 구독 해제 (토큰 전달)
EventBus.shared.off(UserLoggedInEvent.self, by: token)

// 구독 해제 (구독자 전달)
EventBus.shared.off(UserLoggedInEvent.self, by: self)
```

구독자 객체를 전달하여 모든 이벤트 구독을 해제할 수 있습니다.

```swift
// 모든 구독 해제
EventBus.shared.reset(by: self)
```

`EventBus.Config`를 전달해서 새로운 `EventBus` 인스턴스를 생성할 수 있습니다.

- `tokenProvider`: `SubscriptionToken` 프로토콜을 채택한 토큰 생성자를 제공하는 클로저입니다.
- `cleanFrequency`: 구독을 정리하는 빈도를 지정합니다. 현재 구독자 수를 전달하며, `DispatchTimeInterval` 타입을 반환하는 클로저입니다.

```swift
let config = EventBus.Config(tokenProvider: customTokenProvider, cleanFrequency: customFrequency)
let customEventBus = EventBus(config: config)
```


## 테스트

```bash
$ swift test
```

## License

This library is released under the MIT license. See [LICENSE](/LICENSE) for details.
