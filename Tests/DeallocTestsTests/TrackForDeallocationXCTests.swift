//
//  TrackForDeallocationXCTests.swift
//  DeallocTests
//
//  Copyright © 2026 STRV. All rights reserved.
//

import DeallocTests
import XCTest

final class TrackForDeallocationXCTests: XCTestCase {
    override func invokeTest() {
        withDeallocationConfiguration({ $0.gracePeriod = .zero }) {
            super.invokeTest()
        }
    }

    @MainActor
    func test_invokeTestConfiguration_appliesToTheTest() async {
        let options = XCTExpectedFailure.Options()
        options.issueMatcher = { issue in
            issue.compactDescription.contains("within 100 ms.") && !issue.compactDescription.contains("watched for another")
        }
        XCTExpectFailure("RetainCycleObject has a retain cycle", options: options)

        await expectDeallocation(timeout: .milliseconds(100)) { RetainCycleObject() }
    }

    @MainActor
    func test_trackedObject_passes() {
        let object = trackForDeallocation(PlainObject())
        _ = object
    }

    @MainActor
    func test_trackedLeak_fails() {
        XCTExpectFailure("RetainCycleObject has a retain cycle")

        withDeallocationConfiguration({ $0.timeout = .milliseconds(100) }) {
            _ = trackForDeallocation(RetainCycleObject())
        }
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

    @MainActor
    func test_trackedObject_usesTheConfigurationItWasTrackedWith() {
        let options = XCTExpectedFailure.Options()
        options.issueMatcher = { $0.compactDescription.contains("within 130 ms") }
        XCTExpectFailure("RetainCycleObject has a retain cycle", options: options)

        withDeallocationConfiguration({
            $0.timeout = .milliseconds(130)
            $0.gracePeriod = .zero
        }) {
            _ = trackForDeallocation(RetainCycleObject())
        }
    }

    @MainActor
    func test_warningSeverity_doesNotFailTheTest() async {
        await withDeallocationConfiguration({
            $0.timeout = .milliseconds(100)
            $0.severity = .warning
        }) {
            await expectDeallocation { RetainCycleObject() }
        }
    }

    @MainActor
    func test_lateRelease_isAWarning() async {
        await withDeallocationConfiguration({
            $0.timeout = .milliseconds(100)
            $0.gracePeriod = .seconds(2)
        }) {
            await expectDeallocation { makeObjectReleasedAfter(.milliseconds(400)) }
        }
    }
}
