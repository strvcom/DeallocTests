//
//  DeallocationTracker.swift
//  DeallocTests
//
//  Copyright © 2026 STRV. All rights reserved.
//


@MainActor
final class DeallocationTracker {
    private struct TrackedObject {
        weak var object: AnyObject?
        let typeName: String
        let location: TestSourceLocation
    }

    @TaskLocal static var current: DeallocationTracker?

    private var trackedObjects = [TrackedObject]()
    private var configuration = DeallocationConfiguration.current

    func track(_ object: AnyObject, at location: TestSourceLocation) {
        if trackedObjects.isEmpty {
            configuration = DeallocationConfiguration.current
        }

        trackedObjects.append(
            TrackedObject(object: object, typeName: TypeNames.readableName(of: object), location: location)
        )
    }

    func verifyDeallocation(timeout: Duration? = nil) async {
        let objects = trackedObjects
        trackedObjects.removeAll()

        let timeout = timeout ?? configuration.timeout
        let gracePeriod = configuration.severity == .error ? configuration.gracePeriod : .zero
        let clock = ContinuousClock()
        let start = clock.now

        _ = await Polling.waitUntil(timeout: timeout) {
            !objects.contains { $0.object != nil }
        }

        var lateReleases = [(TrackedObject, Duration)]()
        var pending = objects.filter { $0.object != nil }

        if !pending.isEmpty, gracePeriod > .zero {
            _ = await Polling.waitUntil(timeout: gracePeriod) {
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

        guard !Task.isCancelled else {
            return
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
                    gracePeriod: gracePeriod,
                    hints: LeakHints.hints(for: object)
                ).message,
                at: trackedObject.location,
                severity: configuration.severity
            )
        }
    }
}
