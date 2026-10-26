//
//  ReleaseRecorder.swift
//  DeallocTests
//
//  Copyright © 2026 STRV. All rights reserved.
//

import Foundation

/// Records when an object was released, independently of when the check gets to look.
/// The checks poll on the main actor, so a busy main actor would otherwise shift the
/// observed release time and turn a leak into a late release.
final class ReleaseRecorder: @unchecked Sendable {
    private let lock = NSLock()
    private var releasedAt: ContinuousClock.Instant?

    /// When the object was released, or `nil` while it's alive
    var releaseInstant: ContinuousClock.Instant? {
        lock.withLock { releasedAt }
    }

    /// Starts recording the release of `object`. The sentinel is stored as an associated object,
    /// so it's released together with the object, on whichever thread releases it.
    static func attached(to object: AnyObject) -> ReleaseRecorder {
        let recorder = ReleaseRecorder()
        let sentinel = Sentinel(recorder: recorder)
        objc_setAssociatedObject(
            object,
            Unmanaged.passUnretained(sentinel).toOpaque(),
            sentinel,
            .OBJC_ASSOCIATION_RETAIN_NONATOMIC
        )
        return recorder
    }

    private func recordRelease() {
        let now = ContinuousClock.now
        lock.withLock { releasedAt = now }
    }

    private final class Sentinel {
        let recorder: ReleaseRecorder

        init(recorder: ReleaseRecorder) {
            self.recorder = recorder
        }

        deinit {
            recorder.recordRelease()
        }
    }
}
