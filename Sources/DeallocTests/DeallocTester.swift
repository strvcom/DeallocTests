//
//  DeallocTester.swift
//  DeallocTests
//
//  Created by Dan Cech on 17.01.2019.
//  Copyright © 2019 STRV. All rights reserved.
//

import Foundation

#if DependencyInjection
    import DependencyInjection
#endif

import XCTest

#if canImport(UIKit)
    import UIKit
#endif

@available(*, deprecated, message: "Use expectDeallocation(_:timeout:afterRelease:of:), which needs no DeallocTestable conformance. See \"Migrating to 4.0\" in the README.")
public struct DeallocTest {
#if DependencyInjection
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

@available(*, deprecated, message: "Use expectDeallocation(_:timeout:afterRelease:of:), which needs no DeallocTestable conformance. See \"Migrating to 4.0\" in the README.")
open class DeallocTester: XCTestCase {
    // MARK: - Properties

    public var deallocTests = [DeallocTest]()

    /// How long to wait for tracked objects to deallocate before the step fails
    open var deallocationTimeout: Duration = .seconds(2)

    /// Prints `Alloc`/`Dealloc` messages for every tracked object. Off by default.
    public static var isLoggingEnabled: Bool {
        get { DeallocRegistry.shared.isLoggingEnabled }
        set { DeallocRegistry.shared.isLoggingEnabled = newValue }
    }

#if canImport(UIKit)
    // swiftlint:disable:next implicitly_unwrapped_optional
    var window: UIWindow!

    /// Controller used for presenting tested view controllers.
    /// It's created automatically when a tested object is a `UIViewController`.
    // swiftlint:disable:next implicitly_unwrapped_optional
    public var presentingController: UIViewController!
#endif

#if DependencyInjection
    /// Dependency Injection container
    // swiftlint:disable:next implicitly_unwrapped_optional
    public var container: AsyncContainer!
#endif

    /// Initialize DI container with shared dependency registrations
    @MainActor
    open func registerDependencies() async {
        // Override in descendants. Initialize assembler from main project
    }

#if canImport(UIKit)
    /// Controller for presenting tested controllers
    @MainActor
    public func showPresentingController() async -> UIViewController {
        // `UIApplication.shared` is accessed via KVC so the library stays app-extension safe
        if let application = UIApplication.value(forKeyPath: #keyPath(UIApplication.shared)) as? UIApplication,
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

    override open func setUp() async throws {
        try await super.setUp()

        #if DependencyInjection
            container = AsyncContainer()
        #endif

        DeallocRegistry.shared.reset()
    }

    override open func tearDown() {
        #if canImport(UIKit)
            let window = window
            self.window = nil
            presentingController = nil

            // XCTest calls the synchronous tearDown on the main thread
            MainActor.assumeIsolated {
                window?.isHidden = true
            }
        #endif

        super.tearDown()
    }

    /// Instantiate and release tested items one by one.
    /// The expectation is always fulfilled, failures are reported via `XCTFail`.
    @MainActor
    public func performDeallocTest(
        deallocTests: [DeallocTest],
        expectation: XCTestExpectation
    ) async {
        for (index, deallocTest) in deallocTests.enumerated() {
            await performDeallocTest(deallocTest, index: index)
        }

        expectation.fulfill()
    }
}

// MARK: - Private

@available(*, deprecated)
private extension DeallocTester {
    var registry: DeallocRegistry {
        DeallocRegistry.shared
    }

    @MainActor
    func performDeallocTest(_ deallocTest: DeallocTest, index: Int) async {
        registry.reset()

        #if DependencyInjection
            await container.clean()
            await registerDependencies()
        #endif

        registry.log("\nChecking:")

        // The tested instance lives only inside this call
        guard await createAndExercise(deallocTest, index: index) else {
            return
        }

        #if DependencyInjection
            await container.releaseSharedInstances()
        #endif

        deallocTest.actionBeforeCheck?()

        await waitForDeallocation()
        checkResult(checkedClasses: deallocTest.checkClasses, index: index)
    }

    /// Returns `false` when the step cannot be checked
    @MainActor
    func createAndExercise(_ deallocTest: DeallocTest, index: Int) async -> Bool {
        #if DependencyInjection
            let instance = await deallocTest.objectCreation(container)
        #else
            let instance = await deallocTest.objectCreation()
        #endif

        guard let instance else {
            XCTFail("Failed: objectCreation of dealloc test #\(index) returned nil")
            return false
        }

        guard let testable = instance as? DeallocTestable else {
            XCTFail("Failed: class \(NSStringFromClass(type(of: instance))) is not DeallocTestable")
            return false
        }

        testable.initializeDeallocTestSupport()

        #if canImport(UIKit)
            if let controller = instance as? UIViewController {
                return await presentAndDismiss(controller)
            }
        #endif

        return true
    }

    /// Polls until every tracked instance is gone or the timeout elapses
    @MainActor
    func waitForDeallocation() async {
        let deadline = ContinuousClock.now + deallocationTimeout

        while registry.hasLiveInstances, ContinuousClock.now < deadline {
            try? await Task.sleep(for: .milliseconds(10))
        }
    }

    @MainActor
    func checkResult(checkedClasses: [AnyClass]?, index: Int) {
        let entries = registry.entries
        var failedClasses = [AnyClass]()

        if let checkedClasses {
            for checkedClass in checkedClasses {
                let matching = entries.filter { $0.objectClass == checkedClass }
                if matching.isEmpty || matching.contains(where: { !$0.isDeallocated }) {
                    failedClasses.append(checkedClass)
                }
            }
        } else {
            for entry in entries where !entry.isDeallocated && !failedClasses.contains(where: { $0 == entry.objectClass }) {
                failedClasses.append(entry.objectClass)
            }
        }

        if !failedClasses.isEmpty {
            let liveCount = entries.filter { !$0.isDeallocated }.count
            XCTFail("Failed: dealloc test #\(index) failed on classes: \(failedClasses) (\(liveCount) tracked instance(s) still alive)")
        }
    }
}

#if canImport(UIKit)
@available(*, deprecated)
private extension DeallocTester {
    /// Presents and dismisses the controller to run its lifecycle
    @MainActor
    func presentAndDismiss(_ controller: UIViewController) async -> Bool {
        if presentingController == nil {
            presentingController = await showPresentingController()
        }

        guard let presentingController, presentingController.view.window != nil else {
            XCTFail("Failed: presentingController is not in a window hierarchy")
            return false
        }

        if presentingController.presentedViewController != nil {
            await withCheckedContinuation { continuation in
                presentingController.dismiss(animated: false) { continuation.resume() }
            }
        }

        controller.modalPresentationStyle = .fullScreen

        await withCheckedContinuation { continuation in
            presentingController.present(controller, animated: false) { continuation.resume() }
        }

        await Task.yield()

        await withCheckedContinuation { continuation in
            presentingController.dismiss(animated: false) { continuation.resume() }
        }

        return true
    }
}
#endif
