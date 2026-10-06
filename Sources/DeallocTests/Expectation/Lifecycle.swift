//
//  Lifecycle.swift
//  DeallocTests
//
//  Copyright © 2026 STRV. All rights reserved.
//


#if canImport(UIKit)
    import UIKit
#elseif canImport(AppKit)
    import AppKit
#endif

/// What happens with the tested object between its creation and release.
///
/// Many leaks only appear once a view controller loads its view or appears on screen,
/// so view controllers should usually be checked with `.present` or `.push`.
public struct Lifecycle<Object: AnyObject>: Sendable {
    public typealias Interaction = @MainActor (Object) async throws -> Void

    let run: @MainActor (Object, TestSourceLocation) async -> Bool

    init(run: @escaping @MainActor (Object, TestSourceLocation) async -> Bool) {
        self.run = run
    }

    /// The object is released right after it's created
    public static var none: Self {
        Self { _, _ in true }
    }

    /// Runs custom code with the object before it's released, e.g. calls the methods you suspect of leaking
    public static func custom(_ body: @escaping Interaction) -> Self {
        Self { object, location in
            await perform(body, with: object, at: location)
            return true
        }
    }
}

extension Lifecycle {
    @MainActor
    static func perform(_ interaction: Interaction?, with object: Object, at location: TestSourceLocation) async {
        guard let interaction else {
            return
        }

        do {
            try await interaction(object)
        } catch is CancellationError {
            return
        } catch {
            reportIssue("Lifecycle interaction with \(type(of: object)) threw an error: \(error)", at: location)
        }
    }
}

@MainActor
func waitUntil(timeout: Duration = .seconds(10), _ condition: @MainActor () -> Bool) async -> Bool {
    await Polling.waitUntil(timeout: timeout, interval: .milliseconds(5), condition)
}

#if canImport(UIKit)

// MARK: - UIKit

public extension Lifecycle where Object: UIViewController {
    /// Loads the view, so `viewDidLoad` runs
    static var loadView: Self {
        Self { controller, _ in
            controller.loadViewIfNeeded()
            return true
        }
    }

    /// Presents the controller modally in a test window, then dismisses it
    static var present: Self {
        present()
    }

    /// Presents the controller modally in a test window, then dismisses it
    /// - Parameters:
    ///   - style: Modal presentation style
    ///   - interaction: Runs while the controller is on screen
    static func present(style: UIModalPresentationStyle = .fullScreen, interaction: Interaction? = nil) -> Self {
        Self { controller, location in
            let hostController = HostViewController()
            let host = TestWindow(rootViewController: hostController)
            defer { host.close() }

            guard await host.waitUntilVisible(hostController, at: location) else {
                return false
            }

            controller.modalPresentationStyle = style
            if let popover = controller.popoverPresentationController {
                let bounds = hostController.view.bounds
                popover.sourceView = hostController.view
                popover.sourceRect = CGRect(x: bounds.midX, y: bounds.midY, width: 0, height: 0)
            }
            hostController.present(controller, animated: false)

            guard await waitUntil({ controller.viewIfLoaded?.window != nil }) else {
                let reason = host.hasWindowScene ? "" : ". Modal presentation needs a window scene, so the test target needs a host app."
                reportIssue("\(type(of: controller)) could not be presented\(reason)", at: location)
                return false
            }

            await perform(interaction, with: controller, at: location)

            hostController.dismiss(animated: false)

            guard await waitUntil({ hostController.presentedViewController == nil }) else {
                reportIssue("\(type(of: controller)) could not be dismissed", at: location)
                return false
            }

            return true
        }
    }

    /// Pushes the controller onto a navigation controller in a test window, then pops it
    static var push: Self {
        push()
    }

    /// Pushes the controller onto a navigation controller in a test window, then pops it
    /// - Parameter interaction: Runs while the controller is on screen
    static func push(interaction: Interaction? = nil) -> Self {
        Self { controller, location in
            let hostController = HostViewController()
            let navigationController = UINavigationController(rootViewController: hostController)
            let host = TestWindow(rootViewController: navigationController)
            defer { host.close() }

            guard await host.waitUntilVisible(hostController, at: location) else {
                return false
            }

            navigationController.pushViewController(controller, animated: false)

            guard await waitUntil({ controller.viewIfLoaded?.window != nil }) else {
                reportIssue("\(type(of: controller)) could not be pushed", at: location)
                return false
            }

            await perform(interaction, with: controller, at: location)

            navigationController.popViewController(animated: false)

            guard await waitUntil({ controller.navigationController == nil }) else {
                reportIssue("\(type(of: controller)) could not be popped", at: location)
                return false
            }

            return true
        }
    }
}

@MainActor
private func foregroundWindowScene() -> UIWindowScene? {
    guard let application = UIApplication.value(forKeyPath: #keyPath(UIApplication.shared)) as? UIApplication else {
        return nil
    }

    let windowScenes = application.connectedScenes.compactMap { $0 as? UIWindowScene }
    return windowScenes.first { $0.activationState == .foregroundActive } ?? windowScenes.first
}

@MainActor
final class TestWindow {
    private let window: UIWindow

    init(rootViewController: UIViewController) {
        if let windowScene = foregroundWindowScene() {
            window = UIWindow(windowScene: windowScene)
        } else {
            window = UIWindow(frame: UIScreen.main.bounds)
        }

        window.rootViewController = rootViewController
        window.windowLevel = UIWindow.Level.alert + 1
        window.makeKeyAndVisible()
    }

    var hasWindowScene: Bool {
        window.windowScene != nil
    }

    func waitUntilVisible(_ hostController: HostViewController, at location: TestSourceLocation) async -> Bool {
        guard await waitUntil({ hostController.hasAppeared }) else {
            reportIssue("The test window could not be shown. Run the tests in a host app.", at: location)
            return false
        }

        return true
    }

    func close() {
        window.isHidden = true
        window.rootViewController = nil
    }
}

final class HostViewController: UIViewController {
    private(set) var hasAppeared = false

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        hasAppeared = true
    }
}

#elseif canImport(AppKit)

// MARK: - AppKit

public extension Lifecycle where Object: NSViewController {
    /// Loads the view, so `viewDidLoad` runs
    static var loadView: Self {
        Self { controller, _ in
            _ = controller.view
            return true
        }
    }
}

#endif
