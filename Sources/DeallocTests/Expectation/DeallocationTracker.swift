//
//  DeallocationTracker.swift
//  DeallocTests
//
//  Copyright © 2026 STRV. All rights reserved.
//

@MainActor
final class DeallocationTracker {
    private struct TrackedObject {
        weak var object: AnyObject?
        let typeName: String
        let location: TestSourceLocation
    }

    @TaskLocal static var current: DeallocationTracker?

    private var trackedObjects = [TrackedObject]()

    func track(_ object: AnyObject, at location: TestSourceLocation) {
        trackedObjects.append(
            TrackedObject(object: object, typeName: TypeNames.readableName(of: object), location: location)
        )
    }

    func verifyDeallocation(timeout: Duration = .seconds(2)) async {
        let objects = trackedObjects
        trackedObjects.removeAll()

        _ = await Polling.waitUntil(timeout: timeout) {
            !objects.contains { $0.object != nil }
        }

        guard !Task.isCancelled else {
            return
        }

        for trackedObject in objects {
            guard let object = trackedObject.object else {
                continue
            }

            reportIssue(
                LeakReport(
                    typeName: trackedObject.typeName,
                    timeout: timeout,
                    hints: LeakHints.hints(for: object)
                ).message,
                at: trackedObject.location
            )
        }
    }
}
