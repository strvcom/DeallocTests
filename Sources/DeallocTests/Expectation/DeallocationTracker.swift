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
        let configuration: DeallocationConfiguration
    }

    private struct Check {
        let trackedObject: TrackedObject
        let timeout: Duration
        let gracePeriod: Duration
    }

    @TaskLocal static var current: DeallocationTracker?

    private var trackedObjects = [TrackedObject]()

    func track(_ object: AnyObject, at location: TestSourceLocation) {
        trackedObjects.append(
            TrackedObject(
                object: object,
                typeName: TypeNames.readableName(of: object),
                location: location,
                configuration: DeallocationConfiguration.current
            )
        )
    }

    func verifyDeallocation(timeout: Duration? = nil) async {
        let checks = trackedObjects.map { trackedObject in
            Check(
                trackedObject: trackedObject,
                timeout: timeout ?? trackedObject.configuration.timeout,
                gracePeriod: trackedObject.configuration.effectiveGracePeriod
            )
        }
        trackedObjects.removeAll()

        let clock = ContinuousClock()
        let start = clock.now
        let longestWait = checks.map { $0.timeout + $0.gracePeriod }.max() ?? .zero
        var pending = checks
        var lateReleases = [(Check, Duration)]()
        var leaks = [Check]()

        _ = await Polling.waitUntil(timeout: longestWait) {
            let elapsed = clock.now - start

            pending.removeAll { check in
                if check.trackedObject.object == nil {
                    if elapsed > check.timeout, check.gracePeriod > .zero {
                        lateReleases.append((check, elapsed))
                    }
                    return true
                }

                if elapsed >= check.timeout + check.gracePeriod {
                    leaks.append(check)
                    return true
                }

                return false
            }

            return pending.isEmpty
        }

        leaks += pending

        guard !Task.isCancelled else {
            return
        }

        for (check, releasedAfter) in lateReleases {
            reportIssue(
                LeakReport.lateReleaseMessage(
                    typeName: check.trackedObject.typeName,
                    releasedAfter: releasedAfter,
                    timeout: check.timeout
                ),
                at: check.trackedObject.location,
                severity: .warning
            )
        }

        for check in leaks {
            guard let object = check.trackedObject.object else {
                continue
            }

            reportIssue(
                LeakReport(
                    typeName: check.trackedObject.typeName,
                    timeout: check.timeout,
                    gracePeriod: check.gracePeriod,
                    hints: LeakHints.hints(for: object)
                ).message,
                at: check.trackedObject.location,
                severity: check.trackedObject.configuration.severity
            )
        }
    }
}
