//
//  MainCoordinatorDeallocTester.swift
//  DeallocTestsAppTests
//
//  Created by Daniel Cech on 01/05/2020.
//  Copyright © 2020 STRV. All rights reserved.
//

import DeallocTests
import XCTest
@testable import DeallocTestsAppSPM

/// Dealloc tests with XCTest. No `DeallocTestable` conformances are needed.
final class MainCoordinatorDeallocTester: XCTestCase {
    @MainActor
    func test_firstScreen() async {
        let coordinator = MainCoordinator()
        await expectDeallocation(.present) { coordinator.createFirstViewController() }
    }

    /// Fails on purpose: `SecondViewController` captures `self` strongly in `viewDidLoad`
    @MainActor
    func test_secondScreen() async {
        let coordinator = MainCoordinator()
        await expectDeallocation(.present) { coordinator.createSecondViewController() }
    }

    @MainActor
    func test_thirdScreen() async {
        let coordinator = MainCoordinator()
        await expectDeallocation(.push) { coordinator.createThirdViewController() }
    }

    @MainActor
    func test_coordinator() async {
        await expectDeallocation {
            let coordinator = MainCoordinator()
            _ = coordinator.initialViewController()
            return coordinator
        }
    }
}
