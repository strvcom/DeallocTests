//
//  DurationText.swift
//  DeallocTests
//
//  Copyright © 2026 STRV. All rights reserved.
//

enum DurationText {
    static func describe(_ duration: Duration) -> String {
        let (seconds, attoseconds) = duration.components
        let milliseconds = seconds * 1000 + attoseconds / 1_000_000_000_000_000

        guard milliseconds >= 1000 else {
            return "\(milliseconds) ms"
        }

        let tenths = milliseconds / 100
        return tenths % 10 == 0 ? "\(tenths / 10) sec" : "\(tenths / 10).\(tenths % 10) sec"
    }
}
