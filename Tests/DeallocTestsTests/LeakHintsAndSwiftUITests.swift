//
//  LeakHintsAndSwiftUITests.swift
//  DeallocTests
//
//  Copyright © 2026 STRV. All rights reserved.
//

import Combine
import DeallocTests
import SwiftUI
import Testing

// MARK: - Fixtures

final class ClosureLeak {
    var onUpdate: (() -> Void)?

    init() {
        onUpdate = { _ = self }
    }
}

final class CycleParent {
    var child: CycleChild?

    init() {
        child = CycleChild(parent: self)
    }
}

final class CycleChild {
    let parent: CycleParent

    init(parent: CycleParent) {
        self.parent = parent
    }
}

final class SubscriptionLeak {
    let updates = PassthroughSubject<Int, Never>()
    var cancellables = Set<AnyCancellable>()
    var value = 0

    init() {
        // The subscription stays alive and its sink captures self strongly
        updates.sink { self.value = $0 }.store(in: &cancellables)
    }
}

final class OwnerObject {
    let viewModel: PlainObject

    init(viewModel: PlainObject) {
        self.viewModel = viewModel
    }
}

/// Starts an endless task on appear and never cancels it
@MainActor
final class TaskLeakModel {
    var task: Task<Void, Never>?
    var ticks = 0

    func start() {
        task = Task {
            while !Task.isCancelled {
                try? await Task.sleep(for: .milliseconds(10))
                self.ticks += 1
            }
        }
    }
}

/// Runs work in `.task`, which SwiftUI cancels when the view goes away
@MainActor
final class TaskModifierModel {
    var ticks = 0
    var appeared = false

    func run() async {
        while !Task.isCancelled {
            try? await Task.sleep(for: .milliseconds(10))
            ticks += 1
        }
    }
}

struct TaskLeakView: View {
    let model: TaskLeakModel

    var body: some View {
        Text("Leaking").onAppear { model.start() }
    }
}

struct TaskModifierView: View {
    let model: TaskModifierModel

    var body: some View {
        Text("Clean")
            .onAppear { model.appeared = true }
            .task { await model.run() }
    }
}

func isLeakReport(of typeName: String, mentioning hint: String) -> (Issue) -> Bool {
    { issue in
        isLeakReport(of: typeName)(issue) && issue.comments.contains { $0.rawValue.contains(hint) }
    }
}

// MARK: - Leak hints

@Suite("Leak hints")
@MainActor
struct LeakHintsTests {
    @Test func closurePropertyIsNamed() async {
        await withKnownIssue {
            await expectDeallocation(timeout: .milliseconds(100)) { ClosureLeak() }
        } matching: { issue in
            isLeakReport(of: "ClosureLeak", mentioning: "`onUpdate` is a closure")(issue)
        }
    }

    @Test func propertyCycleIsShown() async {
        await withKnownIssue {
            await expectDeallocation(timeout: .milliseconds(100)) { CycleParent() }
        } matching: { issue in
            isLeakReport(of: "CycleParent", mentioning: "`self.child.parent` refers back to the object")(issue)
        }
    }

    @Test func subscriptionIsNamed() async {
        await withKnownIssue {
            await expectDeallocation(timeout: .milliseconds(100)) { SubscriptionLeak() }
        } matching: { issue in
            isLeakReport(of: "SubscriptionLeak", mentioning: "`cancellables` is a Combine subscription")(issue)
        }
    }

    @Test func leakWithoutSuspectsGetsGenericMessage() async {
        let cache = Cache()

        await withKnownIssue {
            await expectDeallocation(.custom { cache.objects.append($0) }, timeout: .milliseconds(100)) { PlainObject() }
        } matching: { issue in
            isLeakReport(of: "PlainObject", mentioning: "Something still holds a strong reference")(issue)
        }
    }
}

// MARK: - Tracking objects inside expectDeallocation

@Suite("trackForDeallocation inside expectDeallocation")
@MainActor
struct NestedTrackingTests {
    @Test func trackedChildPasses() async {
        await expectDeallocation {
            OwnerObject(viewModel: trackForDeallocation(PlainObject()))
        }
    }

    @Test func leakedChildIsReported() async {
        let cache = Cache()

        await withKnownIssue {
            await expectDeallocation(timeout: .milliseconds(100)) {
                let viewModel = trackForDeallocation(PlainObject())
                cache.objects.append(viewModel)
                return OwnerObject(viewModel: viewModel)
            }
        } matching: { issue in
            isLeakReport(of: "PlainObject")(issue)
        }
    }
}

// MARK: - SwiftUI

@Suite("SwiftUI hosting", .serialized)
@MainActor
struct SwiftUIHostingTests {
    @Test func taskModifierIsCancelledWithView() async {
        var appeared = false

        await expectDeallocation(.hosting { TaskModifierView(model: $0) }) {
            let model = TaskModifierModel()
            return model
        }

        await expectDeallocation(.hosting(interaction: { appeared = $0.appeared }) { TaskModifierView(model: $0) }) {
            TaskModifierModel()
        }

        #expect(appeared)
    }

    @Test func taskStartedOnAppearLeaks() async {
        await withKnownIssue {
            await expectDeallocation(.hosting { TaskLeakView(model: $0) }, timeout: .milliseconds(200)) {
                TaskLeakModel()
            }
        } matching: { issue in
            isLeakReport(of: "TaskLeakModel", mentioning: "`task` is a task")(issue)
        }
    }
}
