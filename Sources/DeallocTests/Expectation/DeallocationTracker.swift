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
        let releaseRecorder: ReleaseRecorder
    }

    private struct Check {
        let trackedObject: TrackedObject
        let timeout: Duration
        let gracePeriod: Duration
    }

    private enum Outcome {
        case released
        case releasedLate(after: Duration)
        case leaked
    }

    @TaskLocal static var current: DeallocationTracker?

    private var trackedObjects = [TrackedObject]()

    func track(_ object: AnyObject, at location: TestSourceLocation) {
        trackedObjects.append(
            TrackedObject(
                object: object,
                typeName: TypeNames.readableName(of: object),
                location: location,
                configuration: DeallocationConfiguration.current,
                releaseRecorder: ReleaseRecorder.attached(to: object)
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

        let (lateReleases, leaks) = await waitForOutcomes(of: checks)

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
            // An object released after the deadline is still a leak, but there's nothing left to inspect for hints
            reportIssue(
                LeakReport(
                    typeName: check.trackedObject.typeName,
                    timeout: check.timeout,
                    gracePeriod: check.gracePeriod,
                    hints: check.trackedObject.object.map(LeakHints.hints(for:)) ?? []
                ).message,
                at: check.trackedObject.location,
                severity: check.trackedObject.configuration.severity
            )
        }
    }

    private func waitForOutcomes(of checks: [Check]) async -> (lateReleases: [(Check, Duration)], leaks: [Check]) {
        let start = ContinuousClock.now
        let longestWait = checks.map { $0.timeout + $0.gracePeriod }.max() ?? .zero
        var outcomes = [(Check, Outcome)]()
        var pending = checks

        _ = await Polling.waitUntil(timeout: longestWait) {
            pending.removeAll { check in
                guard let outcome = Self.outcome(of: check, since: start) else {
                    return false
                }
                outcomes.append((check, outcome))
                return true
            }

            return pending.isEmpty
        }

        outcomes += pending.map { ($0, Self.outcome(of: $0, since: start) ?? .leaked) }

        var lateReleases = [(Check, Duration)]()
        var leaks = [Check]()
        for (check, outcome) in outcomes {
            switch outcome {
            case .released:
                break
            case let .releasedLate(releasedAfter):
                lateReleases.append((check, releasedAfter))
            case .leaked:
                leaks.append(check)
            }
        }
        return (lateReleases, leaks)
    }

    /// Judges a check by when its object was actually released, not by when the polling noticed it,
    /// so a busy main actor can't turn a leak into a late release or an on-time release into a late one.
    /// Returns `nil` while the object is alive and its deadline hasn't passed.
    private static func outcome(of check: Check, since start: ContinuousClock.Instant) -> Outcome? {
        let deadline = check.timeout + check.gracePeriod

        guard let releaseInstant = check.trackedObject.releaseRecorder.releaseInstant else {
            return ContinuousClock.now - start >= deadline ? .leaked : nil
        }

        let releasedAfter = releaseInstant - start
        if releasedAfter <= check.timeout {
            return .released
        }
        if releasedAfter < deadline {
            return .releasedLate(after: releasedAfter)
        }
        return .leaked
    }
}
