//
//  LeakReport.swift
//  DeallocTestsCore
//
//  Copyright © 2026 STRV. All rights reserved.
//

import Foundation

/// What is known about an object that wasn't deallocated, and how it's described in a failure
package struct LeakReport: Sendable {
    package let typeName: String
    package let timeout: Duration
    package let hints: [String]

    package init(typeName: String, timeout: Duration, hints: [String] = []) {
        self.typeName = typeName
        self.timeout = timeout
        self.hints = hints
    }

    package var message: String {
        let summary = "\(typeName) was not deallocated within \(timeout.formatted(.units(allowed: [.seconds, .milliseconds])))."

        guard !hints.isEmpty else {
            return summary + " Something still holds a strong reference to it: look for closures capturing self, "
                + "delegates that aren't weak, timers, notification observers and long-running tasks or subscriptions."
        }

        // Hints only see the object's own properties; the reference can also come from outside
        let causes = hints + ["Or something outside still holds it: a parent's list of children, a cache or a singleton"]
        return summary + " Possible causes:\n" + causes.map { "  • \($0)" }.joined(separator: "\n")
    }
}
