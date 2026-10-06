//
//  MainCoordinatorDeallocTests.swift
//  DeallocTestsAppTests
//
//  Created by Daniel Cech on 01/05/2020.
//  Copyright © 2020 STRV. All rights reserved.
//

import DeallocTests
import XCTest
@testable import DeallocTestsAppSPM

final class MainCoordinatorDeallocTests: XCTestCase {
    @MainActor
    func test_firstScreen() async {
        let coordinator = MainCoordinator()
        await expectDeallocation(.present) { coordinator.createFirstViewController() }
    }

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
