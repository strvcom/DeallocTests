//
//  ExpectDeallocation.swift
//  DeallocTests
//
//  Copyright © 2026 STRV. All rights reserved.
//

import Foundation

/// Creates an object, runs its lifecycle, releases it and checks that it deallocates.
///
/// Works in Swift Testing and XCTest. A leak is reported at the line that calls this function.
///
/// ```swift
/// @Test func secondScreenDoesNotLeak() async {
///     await expectDeallocation(.present) {
///         coordinator.createSecondViewController()
///     }
/// }
/// ```
///
/// - Parameters:
///   - lifecycle: What happens with the object before it's released, e.g. `.present` for a view controller
///   - timeout: How long to wait for the object to deallocate
///   - afterRelease: Runs after the object is released and before the check, e.g. to release cached instances
///   - makeObject: Creates the tested object. Don't keep any other reference to it.
@MainActor
public func expectDeallocation<Object: AnyObject>(
    _ lifecycle: Lifecycle<Object> = .none,
    timeout: Duration = .seconds(2),
    afterRelease: @MainActor () async -> Void = {},
    fileID: StaticString = #fileID,
    filePath: StaticString = #filePath,
    line: UInt = #line,
    column: UInt = #column,
    of makeObject: @MainActor () async throws -> Object
) async rethrows {
    let location = TestSourceLocation(fileID: fileID, filePath: filePath, line: line, column: column)
    let tracker = DeallocationTracker()

    guard try await createAndRun(makeObject, lifecycle: lifecycle, tracker: tracker, location: location) else {
        return
    }

    await afterRelease()
    await tracker.verifyDeallocation(timeout: timeout)
}

/// The object only lives inside this call, so it's released when it returns.
/// Returns `false` when the lifecycle couldn't run.
@MainActor
private func createAndRun<Object: AnyObject>(
    _ makeObject: @MainActor () async throws -> Object,
    lifecycle: Lifecycle<Object>,
    tracker: DeallocationTracker,
    location: TestSourceLocation
) async rethrows -> Bool {
    let object = try await makeObject()
    tracker.track(object, at: location)
    return await lifecycle.run(object, location)
}
