//
//  ExpectDeallocationTests.swift
//  DeallocTests
//
//  Copyright © 2026 STRV. All rights reserved.
//

@testable import DeallocTests
import Testing

#if canImport(AppKit)
    import AppKit
#endif

// MARK: - Fixtures

final class PlainObject {}

final class RetainCycleObject {
    var closure: (() -> Void)?

    init() {
        closure = { _ = self }
    }
}

@MainActor
final class Cache {
    var objects = [AnyObject]()
}

struct LifecycleError: Error {}

private final class PrivateRetainCycle {
    var closure: (() -> Void)?

    init() {
        closure = { _ = self }
    }
}

func isLeakReport(of typeName: String) -> (Issue) -> Bool {
    { issue in
        issue.comments.contains { $0.rawValue.contains("\(typeName) was not deallocated") }
            && issue.sourceLocation?.fileName.hasSuffix("Tests.swift") == true
    }
}

// MARK: - expectDeallocation

@Suite("expectDeallocation")
@MainActor
struct ExpectDeallocationTests {
    @Test func cancelledCheckReportsNothing() async {
        let check = Task { @MainActor in
            await expectDeallocation(timeout: .seconds(5)) { RetainCycleObject() }
        }

        try? await Task.sleep(for: .milliseconds(100))
        check.cancel()
        await check.value
    }

    @Test func cancelledInteractionReportsNothing() async {
        let check = Task { @MainActor in
            await expectDeallocation(.custom { _ in try await Task.sleep(for: .seconds(5)) }) { PlainObject() }
        }

        try? await Task.sleep(for: .milliseconds(100))
        check.cancel()
        await check.value
    }

    @Test func afterReleaseRunsWhenTheLifecycleCannotRun() async {
        var didRunAfterRelease = false

        await expectDeallocation(Lifecycle { _, _ in false }, afterRelease: { didRunAfterRelease = true }) { PlainObject() }

        #expect(didRunAfterRelease)
    }

    @Test func cleanObjectPasses() async {
        await expectDeallocation { PlainObject() }
    }

    @Test func retainCycleIsReportedAtCallSite() async {
        await withKnownIssue {
            await expectDeallocation(timeout: .milliseconds(100)) { RetainCycleObject() }
        } matching: { issue in
            isLeakReport(of: "RetainCycleObject")(issue) && issue.sourceLocation?.line == #line - 2
        }
    }

    @Test func privateTypeNameIsReadable() async {
        await withKnownIssue {
            await expectDeallocation(timeout: .milliseconds(100)) { PrivateRetainCycle() }
        } matching: { issue in
            issue.comments.contains { comment in
                comment.rawValue.hasPrefix("DeallocTestsTests.PrivateRetainCycle was not deallocated")
            }
        }
    }

    @Test func customLifecycleRunsBeforeRelease() async {
        var exercisedObject: ObjectIdentifier?

        await expectDeallocation(.custom { exercisedObject = ObjectIdentifier($0) }) { PlainObject() }

        #expect(exercisedObject != nil)
    }

    @Test func customLifecycleLeakIsReported() async {
        let cache = Cache()

        await withKnownIssue {
            await expectDeallocation(.custom { cache.objects.append($0) }, timeout: .milliseconds(100)) { PlainObject() }
        } matching: { issue in
            isLeakReport(of: "PlainObject")(issue)
        }
    }

    @Test func throwingLifecycleIsReported() async {
        await withKnownIssue {
            await expectDeallocation(.custom { _ in throw LifecycleError() }) { PlainObject() }
        } matching: { issue in
            issue.comments.contains { $0.rawValue.contains("threw an error") }
        }
    }

    @Test func throwingFactoryRethrows() async {
        await #expect(throws: LifecycleError.self) {
            try await expectDeallocation { () throws -> PlainObject in throw LifecycleError() }
        }
    }

    @Test func afterReleaseRunsBeforeCheck() async {
        let cache = Cache()

        await expectDeallocation(afterRelease: { cache.objects.removeAll() }) {
            let object = PlainObject()
            cache.objects.append(object)
            return object
        }
    }

    #if canImport(AppKit)
        @Test func appKitLoadViewRunsViewDidLoad() async {
            await withKnownIssue {
                await expectDeallocation(.loadView, timeout: .milliseconds(100)) { LeakingViewController() }
            } matching: { issue in
                isLeakReport(of: "LeakingViewController")(issue)
            }
        }

        @Test func appKitCleanControllerPasses() async {
            await expectDeallocation(.loadView) { CleanViewController() }
        }
    #endif
}

#if canImport(AppKit)
    final class CleanViewController: NSViewController {
        override func loadView() {
            view = NSView()
        }
    }

    final class LeakingViewController: NSViewController {
        var closure: (() -> Void)?

        override func loadView() {
            view = NSView()
        }

        override func viewDidLoad() {
            super.viewDidLoad()
            closure = { _ = self }
        }
    }
#endif
