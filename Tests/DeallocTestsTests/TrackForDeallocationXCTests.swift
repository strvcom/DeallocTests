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
    func test_expectDeallocation_cleanObject_passes() async {
        await expectDeallocation { PlainObject() }
    }

    @MainActor
    func test_expectDeallocation_leak_fails() async {
        XCTExpectFailure("RetainCycleObject has a retain cycle")

        await expectDeallocation(timeout: .milliseconds(100)) { RetainCycleObject() }
    }
}
