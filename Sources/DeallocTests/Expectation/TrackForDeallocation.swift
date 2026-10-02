//
//  TrackForDeallocation.swift
//  DeallocTests
//
//  Copyright © 2026 STRV. All rights reserved.
//

import XCTest

#if canImport(Testing)
    import Testing
#endif

// MARK: - XCTest

public extension XCTestCase {
    /// Checks that the object deallocates when the test ends.
    ///
    /// Keep the object in a local variable. A property of the test case lives until the test case is released.
    ///
    /// ```swift
    /// func test_viewModel() {
    ///     let viewModel = trackForDeallocation(ProfileViewModel())
    ///     ...
    /// }
    /// ```
    @MainActor
    @discardableResult
    func trackForDeallocation<Object: AnyObject>(
        _ object: Object,
        timeout: Duration = .seconds(2),
        fileID: StaticString = #fileID,
        filePath: StaticString = #filePath,
        line: UInt = #line,
        column: UInt = #column
    ) -> Object {
        let location = TestSourceLocation(fileID: fileID, filePath: filePath, line: line, column: column)

        // Inside `expectDeallocation`, the object joins its check
        if let tracker = DeallocationTracker.current {
            tracker.track(object, at: location)
            return object
        }

        let tracker = DeallocationTracker()
        tracker.track(object, at: location)

        addTeardownBlock { @MainActor in
            await tracker.verifyDeallocation(timeout: timeout)
        }

        return object
    }
}

// MARK: - Swift Testing

/// Checks that the object deallocates when the test ends. Requires the `.checksDeallocation` trait,
/// or a call inside `expectDeallocation`, which then checks the object together with the tested one.
///
/// ```swift
/// @Test(.checksDeallocation) func viewModel() async {
///     let viewModel = trackForDeallocation(ProfileViewModel())
///     ...
/// }
/// ```
@MainActor
@discardableResult
public func trackForDeallocation<Object: AnyObject>(
    _ object: Object,
    fileID: StaticString = #fileID,
    filePath: StaticString = #filePath,
    line: UInt = #line,
    column: UInt = #column
) -> Object {
    let location = TestSourceLocation(fileID: fileID, filePath: filePath, line: line, column: column)

    guard let tracker = DeallocationTracker.current else {
        reportIssue(
            "trackForDeallocation(_:) needs the .checksDeallocation trait on the test or its suite, "
                + "or a call inside expectDeallocation. In XCTest, call it on the test case.",
            at: location
        )
        return object
    }

    tracker.track(object, at: location)
    return object
}

#if canImport(Testing) && compiler(>=6.1)

/// Checks that every object passed to `trackForDeallocation(_:)` deallocates when the test ends
public struct DeallocationCheckTrait: TestTrait, SuiteTrait, TestScoping {
    let timeout: Duration

    public var isRecursive: Bool {
        true
    }

    public func provideScope(
        for test: Test,
        testCase: Test.Case?,
        performing function: @Sendable () async throws -> Void
    ) async throws {
        guard !test.isSuite else {
            try await function()
            return
        }

        let tracker = await DeallocationTracker()

        try await DeallocationTracker.$current.withValue(tracker) {
            try await function()
        }

        await tracker.verifyDeallocation(timeout: timeout)
    }
}

public extension Trait where Self == DeallocationCheckTrait {
    /// Checks that every object passed to `trackForDeallocation(_:)` deallocates when the test ends
    static var checksDeallocation: Self {
        checksDeallocation(timeout: .seconds(2))
    }

    /// Checks that every object passed to `trackForDeallocation(_:)` deallocates when the test ends
    /// - Parameter timeout: How long to wait for the objects to deallocate
    static func checksDeallocation(timeout: Duration) -> Self {
        Self(timeout: timeout)
    }
}

#endif
