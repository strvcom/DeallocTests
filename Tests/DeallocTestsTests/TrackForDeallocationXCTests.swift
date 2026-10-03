//
//  TrackForDeallocationXCTests.swift
//  DeallocTests
//
//  Copyright © 2026 STRV. All rights reserved.
//

import DeallocTests
import XCTest

final class TrackForDeallocationXCTests: XCTestCase {
    @MainActor
    func test_trackedObject_passes() {
        let object = trackForDeallocation(PlainObject())
        _ = object
    }

    @MainActor
    func test_trackedLeak_fails() {
        XCTExpectFailure("RetainCycleObject has a retain cycle")

        trackForDeallocation(RetainCycleObject(), timeout: .milliseconds(100))
    }

    @MainActor
    func test_expectDeallocation_cleanObject_passes() async {
        await expectDeallocation { PlainObject() }
    }

    @MainActor
    func test_expectDeallocation_leak_fails() async {
        XCTExpectFailure("RetainCycleObject has a retain cycle")

        await expectDeallocation(timeout: .milliseconds(100)) { RetainCycleObject() }
    }

    @MainActor
    func test_trackedChildInsideExpectDeallocation_isCheckedWithIt() async {
        XCTExpectFailure("The child is kept alive by the cache")
        let cache = Cache()

        await expectDeallocation(timeout: .milliseconds(100)) {
            let child = trackForDeallocation(PlainObject())
            cache.objects.append(child)
            return OwnerObject(viewModel: child)
        }
    }

    @MainActor
    func test_withDeallocationConfiguration_changesTheTimeout() async {
        let options = XCTExpectedFailure.Options()
        options.issueMatcher = { $0.compactDescription.contains("within 120 ms") }
        XCTExpectFailure("RetainCycleObject has a retain cycle", options: options)

        await withDeallocationConfiguration({ $0.timeout = .milliseconds(120) }) {
            await expectDeallocation { RetainCycleObject() }
        }
    }

    /// Reported as a non-strict expected failure, so the test passes
    @MainActor
    func test_warningSeverity_doesNotFailTheTest() async {
        await withDeallocationConfiguration({
            $0.timeout = .milliseconds(100)
            $0.severity = .warning
        }) {
            await expectDeallocation { RetainCycleObject() }
        }
    }
}
