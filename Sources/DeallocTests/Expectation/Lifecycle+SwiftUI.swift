//
//  Lifecycle+SwiftUI.swift
//  DeallocTests
//
//  Copyright © 2026 STRV. All rights reserved.
//

#if canImport(SwiftUI)

import SwiftUI

public extension Lifecycle {
    /// Shows a SwiftUI view built from the object, typically its view model, in a test window, then removes it.
    ///
    /// `onAppear` and `.task` run while the view is shown. When it's removed, SwiftUI cancels its tasks.
    ///
    /// ```swift
    /// await expectDeallocation(.hosting { ProfileView(viewModel: $0) }) {
    ///     ProfileViewModel()
    /// }
    /// ```
    ///
    /// - Parameters:
    ///   - interaction: Runs while the view is on screen
    ///   - content: Builds the view from the object
    static func hosting<Content: View>(
        interaction: Interaction? = nil,
        @ViewBuilder _ content: @escaping @MainActor (Object) -> Content
    ) -> Self {
        Self { object, location in
            guard let host = await SwiftUIHost(rootView: content(object), location: location) else {
                return false
            }

            // Lets SwiftUI call `onAppear` and start `.task` modifiers
            await settle()
            await perform(interaction, with: object, at: location)

            host.remove()

            // Lets SwiftUI call `onDisappear` and cancel tasks
            await settle()
            return true
        }
    }
}

@MainActor
private func settle() async {
    try? await Task.sleep(for: .milliseconds(50))
}

#if canImport(UIKit)

/// Shows a hosting controller as a child of an empty controller in a test window
@MainActor
private final class SwiftUIHost<Content: View> {
    private let window: TestWindow
    private let hostController: HostViewController
    private let hostingController: UIHostingController<Content>

    init?(rootView: Content, location: TestSourceLocation) async {
        hostController = HostViewController()
        window = TestWindow(rootViewController: hostController)
        hostingController = UIHostingController(rootView: rootView)

        guard await window.waitUntilVisible(hostController, at: location) else {
            window.close()
            return nil
        }

        hostController.addChild(hostingController)
        hostingController.view.frame = hostController.view.bounds
        hostController.view.addSubview(hostingController.view)
        hostingController.didMove(toParent: hostController)

        guard await waitUntil({ [hostingController] in hostingController.viewIfLoaded?.window != nil }) else {
            reportIssue("The SwiftUI view could not be shown", at: location)
            remove()
            return nil
        }
    }

    func remove() {
        hostingController.willMove(toParent: nil)
        hostingController.view.removeFromSuperview()
        hostingController.removeFromParent()
        window.close()
    }
}

#elseif canImport(AppKit)

/// Shows a hosting controller in a test window
@MainActor
private final class SwiftUIHost<Content: View> {
    private let window: NSWindow

    init?(rootView: Content, location: TestSourceLocation) async {
        let hostingController = NSHostingController(rootView: rootView)
        window = NSWindow(contentViewController: hostingController)
        window.isReleasedWhenClosed = false
        window.orderFront(nil)

        guard await waitUntil({ [window] in hostingController.view.window === window && window.isVisible }) else {
            reportIssue("The SwiftUI view could not be shown", at: location)
            remove()
            return nil
        }
    }

    func remove() {
        window.orderOut(nil)
        window.contentViewController = nil
        window.close()
    }
}

#endif

#endif
