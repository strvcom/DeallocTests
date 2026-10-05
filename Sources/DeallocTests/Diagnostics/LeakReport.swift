//
//  LeakReport.swift
//  DeallocTests
//
//  Copyright © 2026 STRV. All rights reserved.
//

struct LeakReport: Sendable {
    let typeName: String
    let timeout: Duration

    var message: String {
        "\(typeName) was not deallocated within \(DurationText.describe(timeout))."
            + " Something still holds a strong reference to it: look for closures capturing self, "
            + "delegates that aren't weak, timers, notification observers and long-running tasks or subscriptions."
    }
}
