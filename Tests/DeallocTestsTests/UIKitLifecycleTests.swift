//
//  UIKitLifecycleTests.swift
//  DeallocTests
//
//  Copyright © 2026 STRV. All rights reserved.
//

#if canImport(UIKit)

import DeallocTests
import Testing
import UIKit

final class CleanController: UIViewController {}

final class LoadLeakingController: UIViewController {
    var closure: (() -> Void)?

    override func viewDidLoad() {
        super.viewDidLoad()
        closure = { _ = self }
    }
}

final class AppearLeakingController: UIViewController {
    var closure: (() -> Void)?

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        closure = { _ = self }
    }
}

@MainActor
func hasWindowScene() -> Bool {
    UIApplication.shared.connectedScenes.contains { $0 is UIWindowScene }
}

@Suite("UIKit lifecycles", .serialized)
@MainActor
struct UIKitLifecycleTests {
    @Test func loadViewCatchesViewDidLoadLeak() async {
        await withKnownIssue {
            await expectDeallocation(.loadView, timeout: .milliseconds(200)) { LoadLeakingController() }
        } matching: { issue in
            isLeakReport(of: "LoadLeakingController")(issue)
        }
    }

    @Test func loadViewMissesAppearLeak() async {
        await expectDeallocation(.loadView) { AppearLeakingController() }
    }

    @Test(.enabled("Modal presentation needs a host app") { await hasWindowScene() }) func presentPassesForCleanController() async {
        await expectDeallocation(.present) { CleanController() }
    }

    @Test(.enabled("Modal presentation needs a host app") { await hasWindowScene() }) func presentCatchesAppearLeak() async {
        await withKnownIssue {
            await expectDeallocation(.present, timeout: .milliseconds(200)) { AppearLeakingController() }
        } matching: { issue in
            isLeakReport(of: "AppearLeakingController")(issue)
        }
    }

    @Test(.enabled("Modal presentation needs a host app") { await hasWindowScene() }) func presentInteractionRunsOnScreen() async {
        var wasOnScreen = false

        await expectDeallocation(.present(style: .pageSheet, interaction: { wasOnScreen = $0.view.window != nil })) {
            CleanController()
        }

        #expect(wasOnScreen)
    }

    @Test func pushPassesForCleanController() async {
        await expectDeallocation(.push) { CleanController() }
    }

    @Test func pushCatchesAppearLeak() async {
        await withKnownIssue {
            await expectDeallocation(.push, timeout: .milliseconds(200)) { AppearLeakingController() }
        } matching: { issue in
            isLeakReport(of: "AppearLeakingController")(issue)
        }
    }

    @Test func pushInteractionRunsInNavigationController() async {
        var wasPushed = false

        await expectDeallocation(.push(interaction: { wasPushed = $0.navigationController != nil })) {
            CleanController()
        }

        #expect(wasPushed)
    }
}

#endif
