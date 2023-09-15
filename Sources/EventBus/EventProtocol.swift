/// A protocol for defining events that can be published on the `EventBus`.
///
/// - Note:
///   Each conforming type should define a `Payload` associated type, representing the event's data.
///
/// - Example:
///   ```swift
///   struct UserLoggedInEvent: EventProtocol {
///       typealias Payload = User
///
///       let payload: Payload
///   }
///
///   struct UserLoggedInEvent: EventProtocol {
///       struct Payload {
///           let user: User
///       }
///
///       let payload: Payload
///   }
///
///   struct UserLoggedInEvent: EventProtocol {
///       struct Payload {
///           let completion: (User) -> Void
///       }
///
///       let payload: Payload
///   }
///   ```
public protocol EventProtocol {
    associatedtype Payload

    var payload: Payload { get }
}
