//
//  DefaultValue.swift
//  DeallocTests-iOS
//
//  Created by Daniel Cech on 15/05/2020.
//  Copyright © 2020 DanielCech. All rights reserved.
//

import Foundation

@available(*, deprecated, message: "DefaultInitializable is unrelated to dealloc testing and will be removed in DeallocTests 4.0")
public protocol DefaultInitializable {
    static var defaultValue: Self { get }
}

@available(*, deprecated)
extension Int: DefaultInitializable {
    public static var defaultValue: Int {
        return Int.random(in: 0 ... 100)
    }
}

@available(*, deprecated)
extension Float: DefaultInitializable {
    public static var defaultValue: Float {
        return Float.random(in: 0 ... 100)
    }
}

@available(*, deprecated)
extension Double: DefaultInitializable {
    public static var defaultValue: Double {
        return Double.random(in: 0 ... 100)
    }
}

@available(*, deprecated)
extension Bool: DefaultInitializable {
    public static var defaultValue: Bool {
        return Bool.random()
    }
}

@available(*, deprecated)
extension String: DefaultInitializable {
    public static var defaultValue: String {
        let letters = "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789"
        return String((0 ..< 10).map{ _ in letters.randomElement()! })
    }
}

@available(*, deprecated)
extension URL: DefaultInitializable {
    public static var defaultValue: URL {
        return URL(string: "http://google.com")!
    }
}

@available(*, deprecated)
extension Array: DefaultInitializable {
    public static var defaultValue: Array {
        return []
    }
}

@available(*, deprecated)
extension Dictionary: DefaultInitializable {
    public static var defaultValue: Dictionary {
        return [:]
    }
}

@available(*, deprecated)
extension Set: DefaultInitializable {
    public static var defaultValue: Set {
        return Set()
    }
}

@available(*, deprecated)
extension Optional: DefaultInitializable {
    public static var defaultValue: Optional {
        return nil
    }
}

