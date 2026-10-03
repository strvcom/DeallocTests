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
    /// How much longer the object was watched after the timeout
    package let gracePeriod: Duration
    package let hints: [String]

    package init(typeName: String, timeout: Duration, gracePeriod: Duration = .zero, hints: [String] = []) {
        self.typeName = typeName
        self.timeout = timeout
        self.gracePeriod = gracePeriod
        self.hints = hints
    }

    /// For an object that went away after the timeout but within the grace period
    package static func lateReleaseMessage(typeName: String, releasedAfter: Duration, timeout: Duration) -> String {
        "\(typeName) was released after \(format(releasedAfter)), later than the \(format(timeout)) timeout. "
            + "That's bounded retention, not a leak: something kept it alive for a while, e.g. a task, "
            + "an animation or a delayed callback. If that's expected, raise the timeout."
    }

    private static func format(_ duration: Duration) -> String {
        DurationText.describe(duration)
    }

    package var message: String {
        var summary = "\(typeName) was not deallocated within \(DurationText.describe(timeout))."
        if gracePeriod > .zero {
            summary += " It was watched for another \(DurationText.describe(gracePeriod)) after that."
        }

        guard !hints.isEmpty else {
            return summary + " Something still holds a strong reference to it: look for closures capturing self, "
                + "delegates that aren't weak, timers, notification observers and long-running tasks or subscriptions."
        }

        // Hints only see the object's own properties; the reference can also come from outside
        let causes = hints + ["Or something outside still holds it: a parent's list of children, a cache or a singleton"]
        return summary + " Possible causes:\n" + causes.map { "  • \($0)" }.joined(separator: "\n")
    }
}
