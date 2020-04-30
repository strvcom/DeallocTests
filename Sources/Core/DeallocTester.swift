//
//  DeallocTester.swift
//  iWeather MVVM Tests
//
//  Created by Dan Cech on 17.01.2019.
//  Copyright © 2019 STRV. All rights reserved.
//

import Foundation
import UIKit
import Swinject
import XCTest

struct DeallocTest {
    typealias ObjectCreationClosure = (Container) -> AnyObject?
    typealias SimpleClosure = (() -> Void)

    var objectCreation: ObjectCreationClosure
    var checkClasses: [AnyClass]?
    var actionBeforeCheck: SimpleClosure?

    init(objectCreation: @escaping ObjectCreationClosure, checkClasses: [AnyClass]? = nil, actionBeforeCheck: SimpleClosure? = nil) {
        self.objectCreation = objectCreation
        self.checkClasses = checkClasses
        self.actionBeforeCheck = actionBeforeCheck
    }
}

class DeallocTester: XCTestCase {
    // MARK: - Properties

    var deallocTests = [DeallocTest]()

    // swiftlint:disable:next implicitly_unwrapped_optional
    var presentingController: UIViewController!

    func applyAssembliesToContainer() {
        // TODO: Initialize assembler from main project
        
//        assembler.apply(
//            assemblies: [
//                ManagerAssembly(),
//                ServiceAssembly(),
//                ViewModelAssembly()
//            ]
//        )
    }

    /// Controller for presenting tested controllers
    func showPresentingController() -> UIViewController {
        let window = UIWindow(frame: UIScreen.main.bounds)

        let viewController = UIViewController()
        viewController.view.backgroundColor = .clear

        window.rootViewController = viewController
        window.windowLevel = UIWindow.Level.alert + 1
        window.makeKeyAndVisible()

        return viewController
    }

    /// Dependency Injection assembler
    // swiftlint:disable:next implicitly_unwrapped_optional
    var assembler: Assembler!

    /// Dependency Injection container
    // swiftlint:disable:next implicitly_unwrapped_optional
    var container: Container!

    override func setUp() {
        super.setUp()

        container = Container(behaviors: [PostInitBehavior()])
        assembler = Assembler(container: container)

        allocatedClasses = []
        deallocatedClasses = []

        container.resetObjectScope(.container)
        applyAssembliesToContainer()
    }

    override func tearDown() {
        super.tearDown()
    }

    /// Instantiate and release tested item
    func performDeallocTest(
        index: Int,
        deallocTests: [DeallocTest],
        expectation: XCTestExpectation
    ) {
        // Last item in sequence
        if index == deallocTests.count {
            print("")
            expectation.fulfill()
            return
        }

        allocatedClasses = []
        deallocatedClasses = []

        container.removeAll()
        container.resetObjectScope(.container)
        applyAssembliesToContainer()

        delay(1) { [weak self] in
            guard let self = self else {
                return
            }

            print("\nChecking:")

            let dependencyDeallocTest = deallocTests[index]
            var instance: AnyObject? = dependencyDeallocTest.objectCreation(self.container)

            guard instance is DeallocTestable else {
                // swiftlint:disable:next force_unwrapping
                let className = NSStringFromClass(type(of: instance!))
                XCTFail("Failed: class \(className) is not DeallocTestable")
                return
            }

            (instance as? DeallocTestable)?.initializeDeallocTestSupport()

            delay(1) { [weak self] in
                if let controller = instance as? UIViewController {
                    self?.presentingController.present(controller, animated: true) {
                        delay(1) {
                            self?.presentingController.dismiss(animated: true, completion: {
                                delay(1) {
                                    instance = nil
                                    self?.container.resetObjectScope(.container)
                                    self?.continueWithNextStep(deallocTests: deallocTests, index: index, expectation: expectation)
                                }
                            })
                        }
                    }
                } else {
                    instance = nil
                    self?.continueWithNextStep(deallocTests: deallocTests, index: index, expectation: expectation)
                }
            }
        }
    }

    /// Start testing of next item
    func continueWithNextStep(deallocTests: [DeallocTest], index: Int, expectation: XCTestExpectation) {
        container.resetObjectScope(.container)

        let dependencyDeallocTest = deallocTests[index]
        dependencyDeallocTest.actionBeforeCheck?()

        delay(1) { [weak self] in
            let dependencyDeallocTest = deallocTests[index]
            self?.checkTestResult(checkedClasses: dependencyDeallocTest.checkClasses ?? allocatedClasses)
            self?.performDeallocTest(index: index + 1, deallocTests: deallocTests, expectation: expectation)
        }
    }

    /// Check proper deallocation
    func checkTestResult(checkedClasses: [AnyClass]) {
        let notFoundClassNames = checkedClasses.filter { testedClass in deallocatedClasses.first(where: { $0 == testedClass }) == nil }

        if !notFoundClassNames.isEmpty {
            XCTFail("Failed: dealloc test failed on classes: \(notFoundClassNames)")
        }
    }
}