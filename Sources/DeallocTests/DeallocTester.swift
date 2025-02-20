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

open class DeallocTester: XCTestCase {
    // MARK: - Properties

    public var deallocTests = [DeallocTest]()

#if canImport(UIKit)
    // swiftlint:disable:next implicitly_unwrapped_optional
    var window: UIWindow!

    // swiftlint:disable:next implicitly_unwrapped_optional
    public var presentingController: UIViewController!
#endif

    /// Initialize DI container with shared dependency registrations
    @MainActor
    open func registerDependencies() async {
        // TODO: Override in descendants. Initialize assembler from main project

    }

#if canImport(UIKit)
    /// Controller for presenting tested controllers
    @MainActor
    public func showPresentingController() async -> UIViewController {
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

#if canImport(DependencyInjection)
    /// Dependency Injection container
    // swiftlint:disable:next implicitly_unwrapped_optional
    public var container: AsyncContainer!
#endif

    public override func setUp() async throws {
        try await super.setUp()

        #if canImport(DependencyInjection)
            container = AsyncContainer()
        #endif

        await MainActor.run {
            allocatedClasses = []
            deallocatedClasses = []
        }
    }

    public override func tearDown() {
        super.tearDown()
    }

    /// Instantiate and release tested item
    @MainActor
    public func performDeallocTest(
        deallocTests: [DeallocTest],
        expectation: XCTestExpectation
    ) async {
        await performDeallocTest(index: 0, deallocTests: deallocTests, expectation: expectation)
    }
    
    /// Instantiate and release tested item
    @MainActor
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
            await registerDependencies()
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

//                            #if canImport(DependencyInjection)
//                            await self?.container.releaseSharedInstances()
//                            #endif

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
    @MainActor
    private func continueWithNextStep(deallocTests: [DeallocTest], index: Int, expectation: XCTestExpectation) async {
        #if canImport(DependencyInjection)
            await container.releaseSharedInstances()
        #endif

        try? await Task.sleep(for: .seconds(delayTime))

        let dependencyDeallocTest = deallocTests[index]
        dependencyDeallocTest.actionBeforeCheck?()

        try? await Task.sleep(for: .seconds(delayTime))

        await checkTestResult(checkedClasses: dependencyDeallocTest.checkClasses ?? allocatedClasses)

        await performDeallocTest(index: index + 1, deallocTests: deallocTests, expectation: expectation)
    }

    /// Check proper deallocation
    @MainActor
    private func checkTestResult(checkedClasses: [AnyClass]) async {
        let notFoundClassNames = checkedClasses.filter { testedClass in deallocatedClasses.first(where: { $0 == testedClass }) == nil }

        if !notFoundClassNames.isEmpty {
            XCTFail("Failed: dealloc test failed on classes: \(notFoundClassNames)")
        }
    }
}
