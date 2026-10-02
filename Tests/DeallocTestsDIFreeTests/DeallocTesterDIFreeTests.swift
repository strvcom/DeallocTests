//
//  DeallocTesterDIFreeTests.swift
//  DeallocTests
//
//  Copyright © 2026 STRV. All rights reserved.
//

import DeallocTestsDIFree
import XCTest

final class CleanObject: DeallocTestable {}

final class LeakingObject: DeallocTestable {
    var closure: (() -> Void)?

    init() {
        closure = { _ = self }
    }
}

final class DeallocTesterDIFreeTests: DeallocTester {
    @MainActor
    func test_cleanObject_passes() async {
        await run([
            DeallocTest(objectCreation: { CleanObject() })
        ])
    }

    @MainActor
    func test_retainCycle_fails() async {
        XCTExpectFailure("LeakingObject has a retain cycle")

        await run([
            DeallocTest(objectCreation: { LeakingObject() })
        ])
    }
}

private extension DeallocTesterDIFreeTests {
    @MainActor
    func run(_ deallocTests: [DeallocTest]) async {
        let expectation = expectation(description: "dealloc test")

        await performDeallocTest(deallocTests: deallocTests, expectation: expectation)

        await fulfillment(of: [expectation], timeout: 10)
    }
}
