//
//  LeakReport.swift
//  DeallocTests
//
//  Copyright © 2026 STRV. All rights reserved.
//

struct LeakReport: Sendable {
    let typeName: String
    let timeout: Duration
    let hints: [String]

    init(typeName: String, timeout: Duration, hints: [String] = []) {
        self.typeName = typeName
        self.timeout = timeout
        self.hints = hints
    }

    var message: String {
        let summary = "\(typeName) was not deallocated within \(DurationText.describe(timeout))."

        guard !hints.isEmpty else {
            return summary + " Something still holds a strong reference to it: look for closures capturing self, "
                + "delegates that aren't weak, timers, notification observers and long-running tasks or subscriptions."
        }

        let causes = hints + ["Or something outside still holds it: a parent's list of children, a cache or a singleton"]
        return summary + " Possible causes:\n" + causes.map { "  • \($0)" }.joined(separator: "\n")
    }
}
