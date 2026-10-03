//
//  ConfigurationTests.swift
//  DeallocTests
//
//  Copyright © 2026 STRV. All rights reserved.
//

import DeallocTests
import Testing

#if compiler(>=6.1)

/// Matches a leak report of `RetainCycleObject` that names the expected timeout
func isLeakReport(within timeout: String) -> (Issue) -> Bool {
    { issue in
        issue.comments.contains { $0.rawValue.hasPrefix("DeallocTestsTests.RetainCycleObject was not deallocated within \(timeout).") }
    }
}

@Suite("Deallocation configuration", .deallocationTimeout(.milliseconds(100)))
@MainActor
struct ConfigurationTests {
    @Test func suiteTimeoutApplies() async {
        let clock = ContinuousClock()
        let start = clock.now

        await withKnownIssue {
            await expectDeallocation { RetainCycleObject() }
        } matching: { issue in
            isLeakReport(within: "100 ms")(issue)
        }

        #expect(clock.now - start < .seconds(1), "the default 2 s timeout must not apply")
    }

    @Test(.deallocationTimeout(.milliseconds(300)))
    func testTraitWinsOverSuiteTrait() async {
        await withKnownIssue {
            await expectDeallocation { RetainCycleObject() }
        } matching: { issue in
            isLeakReport(within: "300 ms")(issue)
        }
    }

    @Test func explicitTimeoutWinsOverTraits() async {
        await withKnownIssue {
            await expectDeallocation(timeout: .milliseconds(50)) { RetainCycleObject() }
        } matching: { issue in
            isLeakReport(within: "50 ms")(issue)
        }
    }

    @Test func withDeallocationConfigurationChangesTheTimeout() async {
        await withKnownIssue {
            await withDeallocationConfiguration({ $0.timeout = .milliseconds(150) }) {
                await expectDeallocation { RetainCycleObject() }
            }
        } matching: { issue in
            isLeakReport(within: "150 ms")(issue)
        }
    }

    /// A leak reported as a warning doesn't fail the test
    @Test(.deallocationIssues(.warning))
    func warningSeverityDoesNotFailTheTest() async {
        await expectDeallocation { RetainCycleObject() }
    }

    @Test func trackedObjectsUseTheConfiguredTimeout() async throws {
        try await withKnownIssue {
            try await DeallocationCheckTrait.checksDeallocation.provideScope(
                for: #require(Test.current),
                testCase: Test.Case.current,
                performing: {
                    await MainActor.run {
                        _ = trackForDeallocation(RetainCycleObject())
                    }
                }
            )
        } matching: { issue in
            isLeakReport(within: "100 ms")(issue)
        }
    }
}

#endif
