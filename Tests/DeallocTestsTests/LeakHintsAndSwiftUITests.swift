//
//  LeakHintsAndSwiftUITests.swift
//  DeallocTests
//
//  Copyright © 2026 STRV. All rights reserved.
//

import DeallocTests
import SwiftUI
import Testing

// MARK: - Fixtures

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
            isLeakReport(of: "TaskLeakModel")(issue)
        }
    }
}
