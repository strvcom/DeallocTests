//
//  DefaultValue.swift
//  DeallocTests-iOS
//
//  Created by Daniel Cech on 15/05/2020.
//  Copyright © 2020 DanielCech. All rights reserved.
//

import Foundation

public protocol DefaultInitializable {
    static var defaultValue: Self { get }
}

extension Int: DefaultInitializable {
    public static var defaultValue: Int {
        return Int.random(in: 0 ... 100)
    }
}

extension Float: DefaultInitializable {
    public static var defaultValue: Float {
        return Float.random(in: 0 ... 100)
    }
}

extension Double: DefaultInitializable {
    public static var defaultValue: Double {
        return Double.random(in: 0 ... 100)
    }
}

extension Bool: DefaultInitializable {
    public static var defaultValue: Bool {
        return Bool.random()
    }
}

extension String: DefaultInitializable {
    public static var defaultValue: String {
        let letters = "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789"
        return String((0 ..< 10).map{ _ in letters.randomElement()! })
    }
}

extension URL: DefaultInitializable {
    public static var defaultValue: URL {
        return URL(string: "http://google.com")!
    }
}

extension Array: DefaultInitializable {
    public static var defaultValue: Array {
        return []
    }
}

extension Dictionary: DefaultInitializable {
    public static var defaultValue: Dictionary {
        return [:]
    }
}

extension Set: DefaultInitializable {
    public static var defaultValue: Set {
        return Set()
    }
}

extension Optional: DefaultInitializable {
    public static var defaultValue: Optional {
        return nil
    }
}

