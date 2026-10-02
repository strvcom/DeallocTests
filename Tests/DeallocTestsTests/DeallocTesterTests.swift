//
//  DeallocTesterTests.swift
//  DeallocTests
//
//  Copyright © 2026 STRV. All rights reserved.
//

import DependencyInjection
import XCTest
@testable import DeallocTests

// MARK: - Fixtures

final class CleanObject: DeallocTestable {}

final class LeakingObject: DeallocTestable {
    var closure: (() -> Void)?

    init() {
        // Strong reference to self creates a retain cycle
        closure = { _ = self }
    }
}

final class NotTestableObject {}

protocol Service: AnyObject, Sendable {}

final class SharedService: Service, DeallocTestable {}

@MainActor
enum Leaks {
    static var retained = [AnyObject]()
}

// MARK: - Tests

final class DeallocTesterTests: DeallocTester {
    @MainActor
    func test_cleanObject_passes() async {
        await run([
            DeallocTest(objectCreation: { _ in CleanObject() })
        ])
    }

    @MainActor
    func test_retainCycle_fails() async {
        XCTExpectFailure("LeakingObject has a retain cycle")

        await run([
            DeallocTest(objectCreation: { _ in LeakingObject() })
        ])
    }

    @MainActor
    func test_leakIsDetectedPerInstance() async {
        XCTExpectFailure("Second CleanObject instance is retained")

        await run([
            DeallocTest(objectCreation: { _ in
                let leaked = CleanObject()
                leaked.initializeDeallocTestSupport()
                Leaks.retained.append(leaked)
                return CleanObject()
            })
        ])
    }

    @MainActor
    func test_nilObject_failsWithoutHanging() async {
        XCTExpectFailure("objectCreation returned nil")

        let start = ContinuousClock.now
        await run([
            DeallocTest(objectCreation: { _ in nil }),
            DeallocTest(objectCreation: { _ in CleanObject() })
        ])

        XCTAssertLessThan(ContinuousClock.now - start, .seconds(5))
    }

    @MainActor
    func test_notDeallocTestable_failsWithoutHanging() async {
        XCTExpectFailure("NotTestableObject is not DeallocTestable")

        let start = ContinuousClock.now
        await run([
            DeallocTest(objectCreation: { _ in NotTestableObject() })
        ])

        XCTAssertLessThan(ContinuousClock.now - start, .seconds(5))
    }

    @MainActor
    func test_checkClasses_failsForUntrackedClass() async {
        XCTExpectFailure("NotTestableObject is never tracked")

        await run([
            DeallocTest(objectCreation: { _ in CleanObject() }, checkClasses: [CleanObject.self, NotTestableObject.self])
        ])
    }

    @MainActor
    func test_checkClasses_passesForDeallocatedClass() async {
        await run([
            DeallocTest(objectCreation: { _ in CleanObject() }, checkClasses: [CleanObject.self])
        ])
    }

    @MainActor
    func test_sharedInstanceFromContainer_isReleased() async {
        await run([
            DeallocTest(objectCreation: { await $0.resolve(type: Service.self) as AnyObject })
        ])
    }

    @MainActor
    func test_actionBeforeCheck_isCalled() async {
        var called = false

        await run([
            DeallocTest(objectCreation: { _ in CleanObject() }, actionBeforeCheck: { called = true })
        ])

        XCTAssertTrue(called)
    }

    override func registerDependencies() async {
        await container.register(type: Service.self, in: .shared) { _ in SharedService() }
    }
}

private extension DeallocTesterTests {
    @MainActor
    func run(_ deallocTests: [DeallocTest]) async {
        let expectation = expectation(description: "dealloc test")

        await performDeallocTest(deallocTests: deallocTests, expectation: expectation)

        await fulfillment(of: [expectation], timeout: 10)
    }
}
