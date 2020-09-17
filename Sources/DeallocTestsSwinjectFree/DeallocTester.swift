//
//  DeallocTester.swift
//  DeallocTests
//
//  Created by Dan Cech on 17.01.2019.
//  Copyright © 2019 STRV. All rights reserved.
//

import Foundation

#if canImport(Swinject)
    import Swinject
#endif

import XCTest

#if canImport(UIKit)
    import UIKit
#endif

public struct DeallocTest {
#if canImport(Swinject)
    public typealias ObjectCreationClosure = (Container) -> AnyObject?
#else
    public typealias ObjectCreationClosure = () -> AnyObject?
#endif
    
    public typealias SimpleClosure = (() -> Void)

    public var objectCreation: ObjectCreationClosure
    public var checkClasses: [AnyClass]?
    public var actionBeforeCheck: SimpleClosure?

    public init(objectCreation: @escaping ObjectCreationClosure, checkClasses: [AnyClass]? = nil, actionBeforeCheck: SimpleClosure? = nil) {
        self.objectCreation = objectCreation
        self.checkClasses = checkClasses
        self.actionBeforeCheck = actionBeforeCheck
    }
}

open class DeallocTester: XCTestCase {
    // MARK: - Properties

    public var deallocTests = [DeallocTest]()

#if canImport(UIKit)
    // swiftlint:disable:next implicitly_unwrapped_optional
    public var presentingController: UIViewController!
#endif

    open func applyAssembliesToContainer() {
        // TODO: Initialize assembler from main project
        
//        assembler.apply(
//            assemblies: [
//                ManagerAssembly(),
//                ServiceAssembly(),
//                ViewModelAssembly()
//            ]
//        )
    }

#if canImport(UIKit)
    /// Controller for presenting tested controllers
    public func showPresentingController() -> UIViewController {
        let window: UIWindow
        if #available(iOS 13.0, *),
            let application = UIApplication.value(forKeyPath: #keyPath(UIApplication.shared)) as? UIApplication,
            let windowScene = application.connectedScenes.first as? UIWindowScene {
            window = UIWindow(windowScene: windowScene)
        } else {
            window = UIWindow(frame: UIScreen.main.bounds)
        }

        let viewController = UIViewController()
        viewController.view.backgroundColor = .clear

        window.rootViewController = viewController
        window.windowLevel = UIWindow.Level.alert + 1
        window.makeKeyAndVisible()

        return viewController
    }
#endif

#if canImport(Swinject)
    /// Dependency Injection assembler
    // swiftlint:disable:next implicitly_unwrapped_optional
    public var assembler: Assembler!

    /// Dependency Injection container
    // swiftlint:disable:next implicitly_unwrapped_optional
    var container: Container!
#endif

    public override func setUp() {
        super.setUp()

        #if canImport(Swinject)
            container = Container(behaviors: [PostInitBehavior()])
            assembler = Assembler(container: container)
            container.resetObjectScope(.container)
        #endif

        allocatedClasses = []
        deallocatedClasses = []
        
        applyAssembliesToContainer()
    }

    public override func tearDown() {
        super.tearDown()
    }

    /// Instantiate and release tested item
    public func performDeallocTest(
        deallocTests: [DeallocTest],
        expectation: XCTestExpectation
    ) {
        performDeallocTest(index: 0, deallocTests: deallocTests, expectation: expectation)
    }
    
    /// Instantiate and release tested item
    private func performDeallocTest(
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

        #if canImport(Swinject)
            container.removeAll()
            container.resetObjectScope(.container)
            applyAssembliesToContainer()
        #endif

        delay(1) { [weak self] in
            guard let self = self else {
                return
            }

            print("\nChecking:")

            let dependencyDeallocTest = deallocTests[index]
            
            #if canImport(Swinject)
                var instance: AnyObject? = dependencyDeallocTest.objectCreation(self.container)
            #else
                var instance: AnyObject? = dependencyDeallocTest.objectCreation()
            #endif

            guard instance is DeallocTestable else {
                // swiftlint:disable:next force_unwrapping
                let className = NSStringFromClass(type(of: instance!))
                XCTFail("Failed: class \(className) is not DeallocTestable")
                return
            }

            (instance as? DeallocTestable)?.initializeDeallocTestSupport()

            #if canImport(UIKit)
                delay(1) { [weak self] in
                    if let controller = instance as? UIViewController {
                        controller.modalPresentationStyle = .fullScreen
                        self?.presentingController.present(controller, animated: true) {
                            delay(1) {
                                self?.presentingController.dismiss(animated: true, completion: {
                                    delay(1) {
                                        instance = nil
                                        
                                        #if canImport(Swinject)
                                            self?.container.resetObjectScope(.container)
                                        #endif
                                        
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
            #endif
        }
    }

    /// Start testing of next item
    private func continueWithNextStep(deallocTests: [DeallocTest], index: Int, expectation: XCTestExpectation) {
        #if canImport(Swinject)
            container.resetObjectScope(.container)
        #endif

        let dependencyDeallocTest = deallocTests[index]
        dependencyDeallocTest.actionBeforeCheck?()

        delay(1) { [weak self] in
            let dependencyDeallocTest = deallocTests[index]
            self?.checkTestResult(checkedClasses: dependencyDeallocTest.checkClasses ?? allocatedClasses)
            self?.performDeallocTest(index: index + 1, deallocTests: deallocTests, expectation: expectation)
        }
    }

    /// Check proper deallocation
    private func checkTestResult(checkedClasses: [AnyClass]) {
        let notFoundClassNames = checkedClasses.filter { testedClass in deallocatedClasses.first(where: { $0 == testedClass }) == nil }

        if !notFoundClassNames.isEmpty {
            XCTFail("Failed: dealloc test failed on classes: \(notFoundClassNames)")
        }
    }
}
