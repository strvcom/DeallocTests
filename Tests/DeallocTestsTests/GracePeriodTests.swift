//
//  GracePeriodTests.swift
//  DeallocTests
//
//  Copyright © 2026 STRV. All rights reserved.
//

@testable import DeallocTests
import Foundation
import Testing

@MainActor
func makeObjectReleasedAfter(_ delay: Duration) -> PlainObject {
    let object = PlainObject()
    Task { @MainActor in
        try? await Task.sleep(for: delay)
        withExtendedLifetime(object) {}
    }
    return object
}

private final class ReleasingBox: @unchecked Sendable {
    var object: PlainObject?
}

/// Releases the object on a background queue while the main thread is blocked,
/// so the check can only notice the release once the main thread is free again
@MainActor
func makeObjectReleasedWhileMainThreadIsBlocked(releaseAfter: Duration, blockMainThreadFor: Duration) -> PlainObject {
    let object = PlainObject()
    let box = ReleasingBox()
    box.object = object

    DispatchQueue.main.async {
        Thread.sleep(forTimeInterval: blockMainThreadFor / .seconds(1))
    }
    DispatchQueue.global().asyncAfter(deadline: .now() + releaseAfter / .seconds(1)) {
        box.object = nil
    }

    return object
}

@Suite("Grace period")
@MainActor
struct GracePeriodTests {
    // A passing check ends as soon as the object goes away, so the long grace period only
    // matters on a loaded runner, where the release can come seconds late
    @Test(.deallocationTimeout(.milliseconds(100)), .deallocationGracePeriod(.seconds(60)))
    func lateReleaseIsAWarning() async {
        #if compiler(>=6.3)
            await withKnownIssue {
                await expectDeallocation { makeObjectReleasedAfter(.milliseconds(400)) }
            } matching: { issue in
                issue.severity == .warning
                    && issue.comments.contains { $0.rawValue.hasPrefix("DeallocTestsTests.PlainObject was released after") }
            }
        #else
            await expectDeallocation { makeObjectReleasedAfter(.milliseconds(400)) }
        #endif
    }

    @Test(.deallocationTimeout(.milliseconds(100)), .deallocationGracePeriod(.milliseconds(300)))
    func leakIsStillAFailureAfterTheGracePeriod() async {
        await withKnownIssue {
            await expectDeallocation { RetainCycleObject() }
        } matching: { issue in
            issue.comments.contains {
                $0.rawValue.hasPrefix(
                    "DeallocTestsTests.RetainCycleObject was not deallocated within 100 ms. It was watched for another 300 ms after that."
                )
            }
        }
    }

    // The release happens after the grace period, but the check only gets to look once the
    // main thread is free again, so it has to judge by when the object actually went away
    @Test(.deallocationTimeout(.milliseconds(100)), .deallocationGracePeriod(.milliseconds(200)))
    func releaseAfterTheGracePeriodIsALeakEvenWhenNoticedLate() async {
        await withKnownIssue {
            await expectDeallocation {
                makeObjectReleasedWhileMainThreadIsBlocked(releaseAfter: .milliseconds(400), blockMainThreadFor: .milliseconds(700))
            }
        } matching: { issue in
            issue.comments.contains {
                $0.rawValue.hasPrefix(
                    "DeallocTestsTests.PlainObject was not deallocated within 100 ms. It was watched for another 200 ms after that."
                )
            }
        }
    }

    @Test(.deallocationTimeout(.milliseconds(100)), .deallocationGracePeriod(.zero))
    func zeroGracePeriodTurnsItOff() async {
        await withKnownIssue {
            await expectDeallocation { makeObjectReleasedAfter(.milliseconds(400)) }
        } matching: { issue in
            issue.comments.contains { $0.rawValue.hasPrefix("DeallocTestsTests.PlainObject was not deallocated within 100 ms. Something") }
        }
    }

    @Test func warningSeveritySkipsTheGracePeriod() {
        var configuration = DeallocationConfiguration()
        configuration.gracePeriod = .seconds(3)
        #expect(configuration.effectiveGracePeriod == .seconds(3))

        configuration.severity = .warning
        #expect(configuration.effectiveGracePeriod == .zero)
    }
}
