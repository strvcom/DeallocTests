# Changelog

## 3.3.0

### Added
- Leak messages list likely causes found in the leaked object's stored properties: closures, `Task`s, Combine subscriptions, timers and reference cycles through properties.
- `.hosting { … }` lifecycle that shows a SwiftUI view built from the object in a test window (UIKit and AppKit), so `onAppear` and `.task` run.
- `trackForDeallocation(_:)` inside an `expectDeallocation` closure checks the object together with the tested one, in Swift Testing and XCTest.

## 3.2.0

### Added
- `expectDeallocation(_:timeout:afterRelease:of:)`: creates an object, runs its lifecycle, releases it and checks that it deallocates. Works in Swift Testing and XCTest, needs no `DeallocTestable` conformance and reports leaks at the line of the test.
- Lifecycles: `.none`, `.loadView`, `.present`, `.push` (with an optional interaction while on screen) and `.custom`.
- `trackForDeallocation(_:)` for checking objects at the end of ordinary unit tests: an `XCTestCase` method, and the `.checksDeallocation` Swift Testing trait (Swift 6.1+).
- `expectDeallocation(of:resolvedFrom:)` for dependencies resolved from an `AsyncContainer` (`DeallocTests` product only).
- Swift Testing sample tests in `DeallocTestsAppSPM`.

## 3.1.0

### Fixed
- Dealloc tests no longer hang on macOS.
- A `nil` or non-`DeallocTestable` object no longer crashes or hangs the test.
- Leaks are detected per instance instead of per class.
- Thread-safe dealloc tracking; no more associated-object key warnings.
- The dependency URL uses https, so the package resolves without SSH access to GitHub.

### Changed
- Polling with `deallocationTimeout` (2 s) replaces the fixed delays.
- The presenting controller is created automatically; the test window is cleaned up in `tearDown`.
- `DeallocTestable` no longer requires `Sendable`.
- `Alloc`/`Dealloc` logging is off by default (`DeallocTester.isLoggingEnabled`).
- `setUp()` is `open`.

### Deprecated
- `DefaultInitializable`, to be removed in 4.0.

### Removed
- Travis CI, Danger, Carthage, jazzy and unused headers. CI runs on GitHub Actions.
