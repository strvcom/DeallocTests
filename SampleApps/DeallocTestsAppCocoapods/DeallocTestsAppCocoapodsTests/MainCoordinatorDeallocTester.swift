//
//  MainCoordinatorDeallocTester.swift
//  DeallocTestsAppCocoapodsTests
//
//  Created by Daniel Cech on 01/05/2020.
//  Copyright © 2020 STRV. All rights reserved.
//

import Foundation
import Swinject
import DeallocTests
@testable import DeallocTestsAppCocoapods


class MainCoordinatorDeallocTester: DeallocTester {
    var mainCoordinator: MainCoordinator? {
        applyAssembliesToContainer()

        return MainCoordinator()
    }

    func test_mainCoordinatorDealloc() {
        presentingController = showPresentingController()
        
        deallocTests = [
            DeallocTest(
                objectCreation: { [weak self] _ in
                    guard let firstController = self?.mainCoordinator?.createFirstViewController() else {
                        return nil
                    }
                    return firstController
                }
            ),
            DeallocTest(
                objectCreation: { [weak self] _ in
                    guard let secondController = self?.mainCoordinator?.createSecondViewController() else {
                        return nil
                    }
                    return secondController
                }
            ),
            DeallocTest(
                objectCreation: { [weak self] _ in
                    guard let thirdController = self?.mainCoordinator?.createThirdViewController() else {
                        return nil
                    }
                    return thirdController
                }
            ),
        ]

        let expectation = self.expectation(description: "deallocTest test_mainCoordinatorDealloc")

        performDeallocTest(
            index: 0,
            deallocTests: deallocTests,
            expectation: expectation
        )

        waitForExpectations(timeout: 200, handler: nil)
    }
}
