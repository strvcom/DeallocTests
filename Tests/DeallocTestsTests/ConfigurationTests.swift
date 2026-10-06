//
//  ConfigurationTests.swift
//  DeallocTests
//
//  Copyright © 2026 STRV. All rights reserved.
//

import DeallocTests
import Foundation
import Testing

final class RecordedComments: @unchecked Sendable {
    private let lock = NSLock()
    private var comments = [String]()

    func append(_ issue: Issue) {
        lock.withLock { comments += issue.comments.map(\.rawValue) }
    }

    func contains(_ text: String) -> Bool {
        lock.withLock { comments.contains { $0.contains(text) } }
    }
}

func isLeakReport(within timeout: String) -> (Issue) -> Bool {
    { issue in
        issue.comments.contains { $0.rawValue.hasPrefix("DeallocTestsTests.RetainCycleObject was not deallocated within \(timeout).") }
    }
}

@Suite("Deallocation configuration", .deallocationTimeout(.milliseconds(100)), .deallocationGracePeriod(.zero))
@MainActor
struct ConfigurationTests {
    @Test func suiteTimeoutApplies() async {
        await withKnownIssue {
            await expectDeallocation { RetainCycleObject() }
        } matching: { issue in
            isLeakReport(within: "100 ms")(issue)
        }
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

    @Test(.deallocationIssues(.warning))
    func warningSeverityRecordsAWarning() async {
        #if compiler(>=6.3)
            await withKnownIssue {
                await expectDeallocation { RetainCycleObject() }
            } matching: { issue in
                issue.severity == .warning && isLeakReport(within: "100 ms")(issue)
            }
        #else
            await expectDeallocation { RetainCycleObject() }
        #endif
    }

    @Test func eachTrackedObjectUsesItsOwnConfiguration() async throws {
        let test = try #require(Test.current)
        let recorded = RecordedComments()

        try await withKnownIssue {
            try await DeallocationCheckTrait.checksDeallocation.provideScope(
                for: test,
                testCase: Test.Case.current,
                performing: {
                    await MainActor.run {
                        withDeallocationConfiguration({ $0.timeout = .milliseconds(150) }) {
                            _ = trackForDeallocation(RetainCycleObject())
                        }
                        withDeallocationConfiguration({ $0.timeout = .milliseconds(250) }) {
                            _ = trackForDeallocation(RetainCycleObject())
                        }
                    }
                }
            )
        } matching: { issue in
            recorded.append(issue)
            return isLeakReport(within: "150 ms")(issue) || isLeakReport(within: "250 ms")(issue)
        }

        #expect(recorded.contains("within 150 ms"))
        #expect(recorded.contains("within 250 ms"))
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

    @Test func trackedObjectsUseTheConfigurationOfANestedTrait() async throws {
        let test = try #require(Test.current)

        try await withKnownIssue {
            try await DeallocationCheckTrait.checksDeallocation.provideScope(
                for: test,
                testCase: Test.Case.current,
                performing: {
                    try await DeallocationConfigurationTrait.deallocationTimeout(.milliseconds(130)).provideScope(
                        for: test,
                        testCase: Test.Case.current,
                        performing: {
                            await MainActor.run {
                                _ = trackForDeallocation(RetainCycleObject())
                            }
                        }
                    )
                }
            )
        } matching: { issue in
            isLeakReport(within: "130 ms")(issue)
        }
    }
}
