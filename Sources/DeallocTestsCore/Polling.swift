//
//  Polling.swift
//  DeallocTestsCore
//
//  Copyright © 2026 STRV. All rights reserved.
//

import Foundation

package enum Polling {
    /// Polls the condition until it holds or the timeout elapses. Returns as soon as the
    /// condition holds. Sleeping between checks lets the run loop drain autorelease pools
    /// and finish UIKit transitions.
    @MainActor
    package static func waitUntil(
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
