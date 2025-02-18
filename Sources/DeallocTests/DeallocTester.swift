//
//  DeallocTester.swift
//  DeallocTests
//
//  Created by Dan Cech on 17.01.2019.
//  Copyright © 2019 STRV. All rights reserved.
//

import Foundation

let delayTime: Double = 0.1
let presentationAnimated = false

#if canImport(DependencyInjection)
    import DependencyInjection
#endif

import XCTest

#if canImport(UIKit)
    import UIKit
#endif

public struct DeallocTest {
#if canImport(DependencyInjection)
    public typealias ObjectCreationClosure = @MainActor (AsyncContainer) async -> AnyObject?
#else
    public typealias ObjectCreationClosure = @MainActor () async -> AnyObject?
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

@MainActor
open class DeallocTester: XCTestCase {
    // MARK: - Properties

    public var deallocTests = [DeallocTest]()

#if canImport(UIKit)
    // swiftlint:disable:next implicitly_unwrapped_optional
    public var presentingController: UIViewController!
#endif

    open func applyAssembliesToContainer() async {
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
    public func showPresentingController() async -> UIViewController {
        let window: UIWindow
        if #available(iOS 13.0, *),
            let application = UIApplication.value(forKeyPath: #keyPath(UIApplication.shared)) as? UIApplication,
            let windowScene = application.connectedScenes.first as? UIWindowScene {
            window = UIWindow(windowScene: windowScene)
        } else {
            window = UIWindow(frame: UIScreen.main.bounds)
        }

        let viewController = UIViewController()
        viewController.view.backgroundColor = .green

        window.rootViewController = viewController
        window.windowLevel = UIWindow.Level.alert + 1
        window.makeKeyAndVisible()

        return viewController
    }
#endif

#if canImport(DependencyInjection)
    /// Dependency Injection container
    // swiftlint:disable:next implicitly_unwrapped_optional
    public var container: AsyncContainer!
#endif

    public override func setUp() async throws {
        // try await super.setUp() // TODO: fix this

        #if canImport(DependencyInjection)
            container = AsyncContainer()
        #endif

        allocatedClasses = []
        deallocatedClasses = []
        
        await applyAssembliesToContainer()
    }

    public override func tearDown() {
        super.tearDown()
    }

    /// Instantiate and release tested item
    public func performDeallocTest(
        deallocTests: [DeallocTest],
        expectation: XCTestExpectation
    ) async {
        await performDeallocTest(index: 0, deallocTests: deallocTests, expectation: expectation)
    }
    
    /// Instantiate and release tested item
    private func performDeallocTest(
        index: Int,
        deallocTests: [DeallocTest],
        expectation: XCTestExpectation
    ) async {
        // Last item in sequence
        if index == deallocTests.count {
            print("")
            expectation.fulfill()
            return
        }

        allocatedClasses = []
        deallocatedClasses = []

        #if canImport(DependencyInjection)
            await container.clean()
            await applyAssembliesToContainer()
        #endif

        try? await Task.sleep(for: .seconds(delayTime))

            print("\nChecking:")

            let dependencyDeallocTest = deallocTests[index]
            
            #if canImport(DependencyInjection)
                var instance: AnyObject? = await dependencyDeallocTest.objectCreation(self.container)
            #else
                var instance: AnyObject? = await dependencyDeallocTest.objectCreation()
            #endif

            guard instance is DeallocTestable else {
                // swiftlint:disable:next force_unwrapping
                let className = NSStringFromClass(type(of: instance!))
                XCTFail("Failed: class \(className) is not DeallocTestable")
                return
            }

            (instance as? DeallocTestable)?.initializeDeallocTestSupport()

            #if canImport(UIKit)
                try? await Task.sleep(for: .seconds(delayTime))

                    if let controller = instance as? UIViewController {
                        controller.modalPresentationStyle = .fullScreen
                        presentingController.present(controller, animated: presentationAnimated) { [weak self] in
                            Task {
                                try? await Task.sleep(for: .seconds(delayTime))
                                self?.presentingController.dismiss(animated: presentationAnimated, completion: { [weak self] in
                                    Task {
                                        try? await Task.sleep(for: .seconds(delayTime))
                                        instance = nil

#if canImport(DependencyInjection)
                                        await self?.container.releaseSharedInstances()
#endif

                                        await self?.continueWithNextStep(deallocTests: deallocTests, index: index, expectation: expectation)
                                    }
                                })
                            }
                        }
                    } else {
                        instance = nil
                        await continueWithNextStep(deallocTests: deallocTests, index: index, expectation: expectation)
                    }

            #endif

    }

    /// Start testing of next item
    private func continueWithNextStep(deallocTests: [DeallocTest], index: Int, expectation: XCTestExpectation) async {
        #if canImport(DependencyInjection)
            await container.releaseSharedInstances()
        #endif

        let dependencyDeallocTest = deallocTests[index]
        dependencyDeallocTest.actionBeforeCheck?()

        try? await Task.sleep(for: .seconds(delayTime))
            checkTestResult(checkedClasses: dependencyDeallocTest.checkClasses ?? allocatedClasses)
            await performDeallocTest(index: index + 1, deallocTests: deallocTests, expectation: expectation)
    }

    /// Check proper deallocation
    private func checkTestResult(checkedClasses: [AnyClass]) {
        let notFoundClassNames = checkedClasses.filter { testedClass in deallocatedClasses.first(where: { $0 == testedClass }) == nil }

        if !notFoundClassNames.isEmpty {
            XCTFail("Failed: dealloc test failed on classes: \(notFoundClassNames)")
        }
    }
}
