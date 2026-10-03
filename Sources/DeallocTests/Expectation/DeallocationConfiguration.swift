//
//  DeallocationConfiguration.swift
//  DeallocTests
//
//  Copyright © 2026 STRV. All rights reserved.
//

import Foundation

#if canImport(Testing)
    import Testing
#endif

/// How deallocation checks behave by default.
///
/// Every check uses the current configuration unless it passes its own values. Set it for a
/// Swift Testing suite or test with traits such as `.deallocationTimeout(_:)`, or for a block
/// of code with `withDeallocationConfiguration(_:operation:)`.
public struct DeallocationConfiguration: Sendable {
    /// How long a check waits for the objects to deallocate
    public var timeout: Duration = .seconds(2)
    /// Whether a leak fails the test or is reported as a warning
    public var severity: DeallocationIssueSeverity = .error

    public init() {}

    /// The configuration that applies to the current task
    @TaskLocal public static var current = DeallocationConfiguration()
}

/// How a leak is reported
public enum DeallocationIssueSeverity: Sendable {
    /// The test fails
    case error
    /// The test passes and the leak is shown as a warning, e.g. while adopting dealloc tests
    case warning
}

/// Runs the operation with a changed deallocation configuration.
///
/// The way to configure checks in XCTest, which has no traits:
///
/// ```swift
/// func test_profileScreen() async {
///     await withDeallocationConfiguration({ $0.timeout = .seconds(5) }) {
///         await expectDeallocation(.present) { makeProfileViewController() }
///     }
/// }
/// ```
///
/// It runs on the caller's actor, so it can be called from `@MainActor` tests.
public func withDeallocationConfiguration<Result>(
    _ change: (inout DeallocationConfiguration) -> Void,
    isolation: isolated (any Actor)? = #isolation,
    operation: () async throws -> Result
) async rethrows -> Result {
    var configuration = DeallocationConfiguration.current
    change(&configuration)
    return try await DeallocationConfiguration.$current.withValue(configuration) {
        try await operation()
    }
}

#if canImport(Testing) && compiler(>=6.1)

/// Changes the deallocation configuration for a test, or for every test in a suite.
/// A test's own trait wins over its suite's.
public struct DeallocationConfigurationTrait: TestTrait, SuiteTrait, TestScoping {
    let change: @Sendable (inout DeallocationConfiguration) -> Void

    public var isRecursive: Bool {
        true
    }

    public func provideScope(
        for test: Test,
        testCase: Test.Case?,
        performing function: @Sendable () async throws -> Void
    ) async throws {
        var configuration = DeallocationConfiguration.current
        change(&configuration)
        try await DeallocationConfiguration.$current.withValue(configuration) {
            try await function()
        }
    }
}

public extension Trait where Self == DeallocationConfigurationTrait {
    /// How long deallocation checks wait for objects to deallocate
    ///
    /// ```swift
    /// @Suite(.deallocationTimeout(.seconds(5)))
    /// struct ScreenDeallocTests { … }
    /// ```
    static func deallocationTimeout(_ timeout: Duration) -> Self {
        Self { $0.timeout = timeout }
    }

    /// Whether leaks fail the test (`.error`, the default) or are reported as warnings
    static func deallocationIssues(_ severity: DeallocationIssueSeverity) -> Self {
        Self { $0.severity = severity }
    }
}

#endif
