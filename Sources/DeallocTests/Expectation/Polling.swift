//
//  Polling.swift
//  DeallocTests
//
//  Copyright © 2026 STRV. All rights reserved.
//

enum Polling {
    @MainActor
    static func waitUntil(
        timeout: Duration,
        interval: Duration = .milliseconds(10),
        _ condition: @MainActor () -> Bool
    ) async -> Bool {
        let clock = ContinuousClock()
        let deadline = clock.now + timeout

        while !condition() {
            guard clock.now < deadline else {
                return false
            }

            do {
                try await Task.sleep(for: interval)
            } catch {
                return condition()
            }
        }

        return true
    }
}
