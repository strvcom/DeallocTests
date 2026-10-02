//
//  DeallocTesterDIFreeTests.swift
//  DeallocTests
//
//  Copyright © 2026 STRV. All rights reserved.
//

#if !DependencyInjection

import DeallocTests
import XCTest

/// `DeallocTester` without the DependencyInjection trait: `objectCreation` takes no container
@available(*, deprecated, message: "Tests the deprecated DeallocTester API")
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

@available(*, deprecated)
private extension DeallocTesterDIFreeTests {
    @MainActor
    func run(_ deallocTests: [DeallocTest]) async {
        let expectation = expectation(description: "dealloc test")

        await performDeallocTest(deallocTests: deallocTests, expectation: expectation)

        await fulfillment(of: [expectation], timeout: 10)
    }
}

#endif
