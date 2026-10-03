//
//  ExpectDeallocation+DependencyInjection.swift
//  DeallocTests
//
//  Copyright © 2026 STRV. All rights reserved.
//

#if DependencyInjection

import DependencyInjection
import Foundation

/// Resolves a dependency, releases it together with the container's shared instances
/// and checks that it deallocates.
///
/// ```swift
/// @Test func apiManagerDoesNotLeak() async {
///     let container = AsyncContainer()
///     await container.register(type: APIManaging.self, in: .shared) { _ in APIManager() }
///
///     await expectDeallocation(of: APIManaging.self, resolvedFrom: container)
/// }
/// ```
///
/// - Parameters:
///   - type: Registered type to resolve. The resolved instance must be a class instance.
///   - container: Container with the registration
///   - timeout: How long to wait for the object to deallocate. Defaults to `DeallocationConfiguration.current.timeout`
@MainActor
public func expectDeallocation<Dependency: Sendable>(
    of type: Dependency.Type,
    resolvedFrom container: AsyncContainer,
    timeout: Duration? = nil,
    fileID: StaticString = #fileID,
    filePath: StaticString = #filePath,
    line: UInt = #line,
    column: UInt = #column
) async {
    let location = TestSourceLocation(fileID: fileID, filePath: filePath, line: line, column: column)
    let tracker = DeallocationTracker()

    guard await resolveAndTrack(type, from: container, tracker: tracker, location: location) else {
        return
    }

    await container.releaseSharedInstances()
    await tracker.verifyDeallocation(timeout: timeout)
}

/// The dependency only lives inside this call, so it's released when it returns
@MainActor
private func resolveAndTrack<Dependency: Sendable>(
    _ type: Dependency.Type,
    from container: AsyncContainer,
    tracker: DeallocationTracker,
    location: TestSourceLocation
) async -> Bool {
    let dependency = await container.resolve(type: type)

    // A value type would be boxed into a temporary object that deallocates immediately
    guard Mirror(reflecting: dependency).displayStyle == .class else {
        // `as Any` gives the concrete type instead of the protocol it was resolved as
        let concreteType = Swift.type(of: dependency as Any)
        reportIssue(
            "\(concreteType) resolved for \(type) is a value type, so it can't leak. Check the class instances it holds instead.",
            at: location
        )
        return false
    }

    tracker.track(dependency as AnyObject, at: location)
    return true
}

#endif
