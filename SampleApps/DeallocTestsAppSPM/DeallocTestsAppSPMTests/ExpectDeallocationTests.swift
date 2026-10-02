//
//  ExpectDeallocationTests.swift
//  DeallocTestsAppSPMTests
//
//  Copyright © 2026 STRV. All rights reserved.
//

import DeallocTests
import DependencyInjection
import Testing
@testable import DeallocTestsAppSPM

/// The same checks as `MainCoordinatorDeallocTester` and `DependencyGraphDeallocTester`,
/// written with `expectDeallocation`. No `DeallocTestable` conformances are needed.
@Suite("Dealloc tests")
@MainActor
struct ExpectDeallocationTests {
    let coordinator = MainCoordinator()

    @Test func firstScreen() async {
        await expectDeallocation(.present) { coordinator.createFirstViewController() }
    }

    /// Fails on purpose: `SecondViewController` captures `self` strongly in `viewDidLoad`
    @Test func secondScreen() async {
        await expectDeallocation(.push) { coordinator.createSecondViewController() }
    }

    @Test func thirdScreen() async {
        await expectDeallocation(.present) { coordinator.createThirdViewController() }
    }

    @Test func coordinator() async {
        await expectDeallocation {
            let coordinator = MainCoordinator()
            _ = coordinator.initialViewController()
            return coordinator
        }
    }

    @Test func apiManager() async {
        let container = AsyncContainer()
        await container.register(type: APIManaging.self, in: .shared) { _ in APIManager() }

        await expectDeallocation(of: APIManaging.self, resolvedFrom: container)
    }

    #if compiler(>=6.1)
        @Test(.checksDeallocation) func trackedController() {
            let controller = trackForDeallocation(coordinator.createThirdViewController())
            controller.loadViewIfNeeded()
        }
    #endif
}
