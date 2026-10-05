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

    private var trackedObjects = [TrackedObject]()

    func track(_ object: AnyObject, at location: TestSourceLocation) {
        trackedObjects.append(
            TrackedObject(object: object, typeName: TypeNames.readableName(of: object), location: location)
        )
    }

    func verifyDeallocation(timeout: Duration) async {
        let objects = trackedObjects
        trackedObjects.removeAll()

        _ = await Polling.waitUntil(timeout: timeout) {
            !objects.contains { $0.object != nil }
        }

        guard !Task.isCancelled else {
            return
        }

        for trackedObject in objects where trackedObject.object != nil {
            reportIssue(
                LeakReport(typeName: trackedObject.typeName, timeout: timeout).message,
                at: trackedObject.location
            )
        }
    }
}
