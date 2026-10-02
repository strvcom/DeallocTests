//
//  ExpectDeallocationDIFreeTests.swift
//  DeallocTests
//
//  Copyright © 2026 STRV. All rights reserved.
//

import DeallocTestsDIFree
import Testing

final class PlainObject {}

@Suite("expectDeallocation without Dependency Injection")
@MainActor
struct ExpectDeallocationDIFreeTests {
    @Test func cleanObjectPasses() async {
        await expectDeallocation { PlainObject() }
    }

    @Test func retainCycleIsReported() async {
        await withKnownIssue {
            await expectDeallocation(timeout: .milliseconds(100)) { LeakingObject() }
        } matching: { issue in
            issue.comments.contains { $0.rawValue.contains("LeakingObject was not deallocated") }
        }
    }
}
