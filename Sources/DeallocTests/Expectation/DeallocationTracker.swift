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

    /// Tracker installed by the `.checksDeallocation` Swift Testing trait
    @TaskLocal static var current: DeallocationTracker?

    private var trackedObjects = [TrackedObject]()

    var isEmpty: Bool {
        trackedObjects.isEmpty
    }

    func track(_ object: AnyObject, at location: TestSourceLocation) {
        trackedObjects.append(
            TrackedObject(object: object, typeName: String(reflecting: type(of: object)), location: location)
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

        for trackedObject in trackedObjects where trackedObject.object != nil {
            reportIssue(
                Self.leakMessage(typeName: trackedObject.typeName, timeout: timeout),
                at: trackedObject.location
            )
        }

        trackedObjects.removeAll()
    }

    static func leakMessage(typeName: String, timeout: Duration) -> String {
        "\(typeName) was not deallocated within \(timeout.formatted(.units(allowed: [.seconds, .milliseconds]))). "
            + "Something still holds a strong reference to it: look for closures capturing self, "
            + "delegates that aren't weak, timers, notification observers and long-running tasks or subscriptions."
    }
}
