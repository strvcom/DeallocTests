//
//  DeallocationTracker.swift
//  DeallocTests
//
//  Copyright © 2026 STRV. All rights reserved.
//

import Foundation

/// Keeps weak references to objects and checks that all of them deallocate.
/// No conformance or associated objects are needed, so any class instance can be tracked.
@MainActor
final class DeallocationTracker {
    private struct TrackedObject {
        weak var object: AnyObject?
        let typeName: String
        let location: TestSourceLocation
    }

    /// Tracker that `trackForDeallocation(_:)` adds objects to.
    /// Installed by `expectDeallocation` and the `.checksDeallocation` Swift Testing trait.
    @TaskLocal static var current: DeallocationTracker?

    private var trackedObjects = [TrackedObject]()

    var isEmpty: Bool {
        trackedObjects.isEmpty
    }

    func track(_ object: AnyObject, at location: TestSourceLocation) {
        trackedObjects.append(
            TrackedObject(object: object, typeName: Self.readableTypeName(of: object), location: location)
        )
    }

    /// Waits until all tracked objects deallocate and reports the ones that didn't within the timeout
    func verifyDeallocation(timeout: Duration) async {
        let clock = ContinuousClock()
        let deadline = clock.now + timeout

        // Polling also lets the run loop drain autorelease pools and finish UIKit transitions
        while trackedObjects.contains(where: { $0.object != nil }), clock.now < deadline {
            do {
                try await Task.sleep(for: .milliseconds(10))
            } catch {
                break
            }
        }

        for trackedObject in trackedObjects {
            guard let object = trackedObject.object else {
                continue
            }

            reportIssue(
                Self.leakMessage(typeName: trackedObject.typeName, timeout: timeout, hints: LeakHints.hints(for: object)),
                at: trackedObject.location
            )
        }

        trackedObjects.removeAll()
    }

    /// Module-qualified type name without the `(unknown context at $…)` part
    /// that Swift adds for private and local types
    static func readableTypeName(of object: AnyObject) -> String {
        String(reflecting: type(of: object))
            .replacingOccurrences(of: #"\(unknown context at \$[0-9a-fA-F]+\)\."#, with: "", options: .regularExpression)
    }

    static func leakMessage(typeName: String, timeout: Duration, hints: [String] = []) -> String {
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
