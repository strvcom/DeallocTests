//
//  DependencyGraphDeallocTester.swift
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

@available(*, deprecated, message: "Shows the deprecated DeallocTester API. See ExpectDeallocationTests for the current API.")
class DependencyGraphDeallocTester: DeallocTester {
    @MainActor
    func test_dependencyGraphDealloc() async {
        deallocTests = [
            DeallocTest(
                objectCreation: { await $0.resolve(type: APIManaging.self) as AnyObject }
            ),
        ]

        let expectation = self.expectation(description: "deallocTest test_todayCoordinatorDealloc")

        await performDeallocTest(
            deallocTests: deallocTests,
            expectation: expectation
        )

        await fulfillment(of: [expectation], timeout: 200)
    }
    
    override func registerDependencies() async {
        await container.register(type: APIManaging.self, in: .new, factory: { _ in APIManager()})
    }
}
