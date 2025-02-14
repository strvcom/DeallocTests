//
//  ServicesDeallocTester.swift
//  DeallocTestsAppSPMTests
//
//  Created by Jan Schwarz on 06.04.2022.
//  Copyright © 2022 STRV. All rights reserved.
//

import Foundation

@testable import DeallocTestsAppSPM
import DependencyInjection
import DeallocTests
import XCTest

class DependencyGraphDeallocTester: DeallocTester {
    func test_dependencyGraphDealloc() async {
        presentingController = showPresentingController()

        deallocTests = [
            DeallocTest(
                objectCreation: { $0.resolve(type: APIManaging.self) as AnyObject }
            ),
        ]

        let expectation = self.expectation(description: "deallocTest test_todayCoordinatorDealloc")

        await performDeallocTest(
            deallocTests: deallocTests,
            expectation: expectation
        )

        waitForExpectations(timeout: 200, handler: nil)
    }
    
    override func applyAssembliesToContainer() {
        container.autoregister(type: APIManaging.self, in: .shared, initializer: APIManager.init)
    }
}
