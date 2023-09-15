struct WeakRef<T: AnyObject> {
    weak var value: T?

    init(_ value: T?) {
        self.value = value
    }
}

extension WeakRef: Equatable {
    static func == (lhs: WeakRef<T>, rhs: WeakRef<T>) -> Bool {
        lhs.value === rhs.value
    }

    static func == (lhs: WeakRef<T>, rhs: AnyObject) -> Bool {
        lhs.value === rhs
    }
}
