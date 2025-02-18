//
//  MainCoordinatorDeallocTester.swift
//  DeallocTestsAppTests
//
//  Created by Daniel Cech on 01/05/2020.
//  Copyright © 2020 STRV. All rights reserved.
//

import Foundation
import DeallocTests
@testable import DeallocTestsAppSPM


class MainCoordinatorDeallocTester: DeallocTester {
    var mainCoordinator: MainCoordinator?

    func test_mainCoordinatorDealloc() async {
        presentingController = await showPresentingController()

        await applyAssembliesToContainer()
        mainCoordinator = MainCoordinator()

        deallocTests = [
            DeallocTest(
                objectCreation: { [weak self] _ in
                    return self?.mainCoordinator?.createFirstViewController()
                }
            ),
            DeallocTest(
                objectCreation: { [weak self] _ in
                    return self?.mainCoordinator?.createSecondViewController()
                }
            ),
            DeallocTest(
                objectCreation: { [weak self] _ in
                    return self?.mainCoordinator?.createThirdViewController()
                }
            ),
            DeallocTest(
                objectCreation: { _ in
                    return MainCoordinator()
                }
            )
        ]

        let expectation = self.expectation(description: "deallocTest test_mainCoordinatorDealloc")

        await performDeallocTest(
            deallocTests: deallocTests,
            expectation: expectation
        )

        await fulfillment(of: [expectation], timeout: 200)
    }
}
