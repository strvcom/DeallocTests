//
//  DeallocationTracker.swift
//  DeallocTests
//
//  Copyright © 2026 STRV. All rights reserved.
//

import DeallocTestsCore
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
            TrackedObject(object: object, typeName: TypeNames.readableName(of: object), location: location)
        )
    }

    /// Waits until all tracked objects deallocate and reports the ones that didn't within the timeout.
    /// - Parameter timeout: Overrides the timeout of the current `DeallocationConfiguration`
    func verifyDeallocation(timeout: Duration?) async {
        let configuration = DeallocationConfiguration.current
        let timeout = timeout ?? configuration.timeout

        _ = await Polling.waitUntil(timeout: timeout) { [trackedObjects] in
            !trackedObjects.contains { $0.object != nil }
        }

        for trackedObject in trackedObjects {
            guard let object = trackedObject.object else {
                continue
            }

            reportIssue(
                LeakReport(typeName: trackedObject.typeName, timeout: timeout, hints: LeakHints.hints(for: object)).message,
                at: trackedObject.location,
                severity: configuration.severity
            )
        }

        trackedObjects.removeAll()
    }
}
