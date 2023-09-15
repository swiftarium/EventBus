public protocol EventProtocol {
    associatedtype Payload

    var payload: Payload { get }
}
