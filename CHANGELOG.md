# Changelog

## 4.0.0

See "Migrating to 4.0" in the README.

### Added
- `expectDeallocation(_:timeout:afterRelease:of:)`: creates an object, runs its lifecycle, releases it and checks that it deallocates. Works in Swift Testing and XCTest, needs no `DeallocTestable` conformance and reports leaks at the line of the test.
- Lifecycles: `.none`, `.loadView`, `.present`, `.push` (with an optional interaction while on screen), `.hosting` for SwiftUI views (UIKit and AppKit) and `.custom`.
- Leak messages list likely causes found in the leaked object's stored properties: closures, `Task`s, Combine subscriptions, timers and reference cycles through properties.
- `trackForDeallocation(_:)`: an `XCTestCase` method and the `.checksDeallocation` Swift Testing trait for checking objects at the end of ordinary unit tests. Inside an `expectDeallocation` closure, it checks the object together with the tested one.
- `expectDeallocation(of:resolvedFrom:)` for dependencies resolved from an `AsyncContainer`.
- Swift Testing and XCTest tests of the library on macOS and the iOS simulator, and GitHub Actions CI.

### Breaking
- STRV Dependency Injection support is the `DependencyInjection` package trait. It's on by default; with `traits: []` the dependency isn't downloaded.
- The `DeallocTestsDIFree` product is removed. Use the `DeallocTests` product and `import DeallocTests`.
- Swift 6.1 (Xcode 16.3) is required. Turning the trait off from an Xcode project needs Xcode 26.4.
- `DefaultInitializable` is removed.
- `DeallocTestable` no longer requires `Sendable`.
- `Alloc`/`Dealloc` logging is off by default (`DeallocTester.isLoggingEnabled`).

### Deprecated
- `DeallocTester`, `DeallocTest`, `DeallocTestable` and `ClassNameIdentifiable`. Use `expectDeallocation`. They will be removed in 5.0.

### Fixed (`DeallocTester`)
- Dealloc tests no longer hang on macOS.
- A `nil` or non-`DeallocTestable` object no longer crashes or hangs the test.
- Leaks are detected per instance instead of per class.
- Thread-safe dealloc tracking; no more associated-object key warnings.
- Polling with `deallocationTimeout` (2 s) replaces the fixed delays.
- The presenting controller is created automatically; the test window is cleaned up in `tearDown`. `setUp()` is `open`.
- The dependency URL uses https, so the package resolves without SSH access to GitHub.

### Removed
- Travis CI, Danger, Carthage, jazzy and unused headers.
