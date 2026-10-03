//
//  GracePeriodTests.swift
//  DeallocTests
//
//  Copyright © 2026 STRV. All rights reserved.
//

import DeallocTests
import Foundation
import Testing

#if compiler(>=6.1)

/// Keeps a new object alive for a while, like a task or animation finishing late
@MainActor
func makeObjectReleasedAfter(_ delay: Duration) -> PlainObject {
    let object = PlainObject()
    Task { @MainActor in
        try? await Task.sleep(for: delay)
        withExtendedLifetime(object) {}
    }
    return object
}

@Suite("Grace period")
@MainActor
struct GracePeriodTests {
    /// Released after the timeout but within the grace period: a warning, the test passes
    @Test(.deallocationTimeout(.milliseconds(100)), .deallocationGracePeriod(.seconds(2)))
    func lateReleaseIsAWarning() async {
        await expectDeallocation { makeObjectReleasedAfter(.milliseconds(400)) }
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

    /// With the grace period off, a late release is a leak
    @Test(.deallocationTimeout(.milliseconds(100)), .deallocationGracePeriod(.zero))
    func zeroGracePeriodTurnsItOff() async {
        await withKnownIssue {
            await expectDeallocation { makeObjectReleasedAfter(.milliseconds(400)) }
        } matching: { issue in
            issue.comments.contains { $0.rawValue.hasPrefix("DeallocTestsTests.PlainObject was not deallocated within 100 ms. Something") }
        }
    }
}

#endif
