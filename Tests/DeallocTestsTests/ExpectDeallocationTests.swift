//
//  ExpectDeallocationTests.swift
//  DeallocTests
//
//  Copyright © 2026 STRV. All rights reserved.
//

import DeallocTests
import Testing

#if DependencyInjection
    import DependencyInjection
#endif

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

protocol AnyService: Sendable {}

protocol Service: AnyObject, Sendable {}

final class ContainerService: Service {}

struct ValueService: AnyService {}

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

// MARK: - Dependency Injection

#if DependencyInjection

@Suite("expectDeallocation with AsyncContainer")
@MainActor
struct ExpectDeallocationDependencyInjectionTests {
    let container = AsyncContainer()

    @Test func sharedInstanceIsReleasedWithContainer() async {
        await container.register(type: Service.self, in: .shared) { _ in ContainerService() }

        await expectDeallocation(of: Service.self, resolvedFrom: container)
    }

    @Test func newInstanceIsChecked() async {
        await container.register(type: Service.self, in: .new) { _ in ContainerService() }

        await expectDeallocation(of: Service.self, resolvedFrom: container)
    }

    @Test func valueTypeIsReported() async {
        await container.register(type: AnyService.self, in: .new) { _ in ValueService() }

        await withKnownIssue {
            await expectDeallocation(of: AnyService.self, resolvedFrom: container)
        } matching: { issue in
            issue.comments.contains { $0.rawValue.hasPrefix("ValueService resolved for AnyService is a value type") }
        }
    }
}

#endif

// MARK: - trackForDeallocation

@Suite("trackForDeallocation")
@MainActor
struct TrackForDeallocationTests {
    @Test(.checksDeallocation) func trackedObjectPasses() {
        let object = trackForDeallocation(PlainObject())
        _ = object
    }

    @Test func trackedLeakIsReported() async throws {
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
            isLeakReport(of: "RetainCycleObject")(issue)
        }
    }

    @Test func missingTraitIsReported() {
        withKnownIssue {
            _ = trackForDeallocation(PlainObject())
        } matching: { issue in
            issue.comments.contains { $0.rawValue.contains("needs the .checksDeallocation trait") }
        }
    }
}

@Suite("trackForDeallocation on a suite", .checksDeallocation)
@MainActor
struct TrackForDeallocationSuiteTests {
    let object = trackForDeallocation(PlainObject())

    @Test func storedPropertyIsChecked() {
        _ = object
    }

    @Test(arguments: [1, 2, 3])
    func parameterizedTestIsChecked(value: Int) {
        _ = trackForDeallocation(PlainObject())
    }
}
