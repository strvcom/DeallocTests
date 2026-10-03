//
//  DurationText.swift
//  DeallocTestsCore
//
//  Copyright © 2026 STRV. All rights reserved.
//

import Foundation

package enum DurationText {
    /// "400 ms", "2 sec", "3.2 sec": the same in every locale, so test output and the
    /// strings tests match against don't change with the machine's settings
    package static func describe(_ duration: Duration) -> String {
        let (seconds, attoseconds) = duration.components
        let milliseconds = seconds * 1000 + attoseconds / 1_000_000_000_000_000

        guard milliseconds >= 1000 else {
            return "\(milliseconds) ms"
        }

        let tenths = milliseconds / 100
        return tenths % 10 == 0 ? "\(tenths / 10) sec" : "\(tenths / 10).\(tenths % 10) sec"
    }
}
