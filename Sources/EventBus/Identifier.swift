internal struct Identifier: Hashable {
    private let identifier: String

    init<T>(_ target: T.Type) {
        identifier = String(describing: target.self)
    }

    init(_ target: Any) {
        identifier = String(describing: type(of: target))
    }
}
