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
    ///
    /// Objects still alive at the timeout are watched for the configured grace period. Those
    /// released in that time are reported as warnings (bounded retention); the rest are leaks.
    /// - Parameter timeout: Overrides the timeout of the current `DeallocationConfiguration`
    func verifyDeallocation(timeout: Duration?) async {
        let configuration = DeallocationConfiguration.current
        let timeout = timeout ?? configuration.timeout
        let clock = ContinuousClock()
        let start = clock.now

        _ = await Polling.waitUntil(timeout: timeout) { [trackedObjects] in
            !trackedObjects.contains { $0.object != nil }
        }

        var lateReleases = [(TrackedObject, Duration)]()
        var pending = trackedObjects.filter { $0.object != nil }

        if !pending.isEmpty, configuration.gracePeriod > .zero {
            _ = await Polling.waitUntil(timeout: configuration.gracePeriod) {
                pending.removeAll { trackedObject in
                    guard trackedObject.object == nil else {
                        return false
                    }
                    lateReleases.append((trackedObject, clock.now - start))
                    return true
                }
                return pending.isEmpty
            }
        }

        for (trackedObject, releasedAfter) in lateReleases {
            reportIssue(
                LeakReport.lateReleaseMessage(typeName: trackedObject.typeName, releasedAfter: releasedAfter, timeout: timeout),
                at: trackedObject.location,
                severity: .warning
            )
        }

        for trackedObject in pending {
            guard let object = trackedObject.object else {
                continue
            }

            reportIssue(
                LeakReport(
                    typeName: trackedObject.typeName,
                    timeout: timeout,
                    gracePeriod: configuration.gracePeriod,
                    hints: LeakHints.hints(for: object)
                ).message,
                at: trackedObject.location,
                severity: configuration.severity
            )
        }

        trackedObjects.removeAll()
    }
}
