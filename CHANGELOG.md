# Changelog

## 4.0.0

See "Migrating to 4.0" in the README.

### Added
- `expectDeallocation(_:timeout:afterRelease:of:)`: creates an object, runs its lifecycle, releases it and checks that it deallocates. Works in Swift Testing and XCTest, checks any class without conformances and reports leaks at the line of the test.
- Lifecycles: `.none`, `.loadView`, `.present`, `.push` (with an optional interaction while on screen), `.hosting` for SwiftUI views (UIKit and AppKit) and `.custom`.
- Leak messages list likely causes found in the leaked object's stored properties: closures, `Task`s, Combine subscriptions, timers and reference cycles through properties, including a property that holds the object itself. Properties that are `nil` or empty are skipped.
- Leak messages show readable names for private and local types, without Swift's `(unknown context at $…)`.
- Durations in messages read the same in every locale ("400 ms", "3.2 sec").
- With hints, the leak message also reminds that the object may be held from outside (a parent's list of children, a cache, a singleton), which hints can't see.
- Hints show `@Observable` properties by their declared names, without the macro's `_` prefix and registrar.
- UIKit lifecycles wait up to 10 s for a screen to appear, be dismissed or popped, instead of 2 s, so they stay reliable on a loaded simulator.
- `trackForDeallocation(_:)`: an `XCTestCase` method and the `.checksDeallocation` Swift Testing trait for checking objects at the end of ordinary unit tests. Inside an `expectDeallocation` closure, it checks the object together with the tested one.
- `DeallocationConfiguration` with the `.deallocationTimeout(_:)`, `.deallocationGracePeriod(_:)` and `.deallocationIssues(_:)` Swift Testing traits for a test or a whole suite, and `withDeallocationConfiguration(_:operation:)` for XCTest (also around `invokeTest()` for a whole class). Leaks can be reported as warnings that don't fail the test.
- Grace period: an object still alive at the timeout is watched a little longer (3 s by default). If it goes away then, it's reported as a warning, "released after 3.2 sec … bounded retention, not a leak", instead of a failure. It's skipped when leaks are reported as warnings anyway.
- `expectDeallocation(of:resolvedFrom:)` for dependencies resolved from an `AsyncContainer`. A dependency that turns out to be a value type is reported with its concrete type, since it can't leak.
- Swift Testing and XCTest tests of the library on macOS and the iOS simulator, and GitHub Actions CI.

### Breaking
- STRV Dependency Injection support is the `DependencyInjection` package trait. It's on by default; with `traits: []` the dependency isn't downloaded.
- Works with STRV Dependency Injection 1.0.4 up to 2.x.
- The `DeallocTestsDIFree` product is removed. Use the `DeallocTests` product and `import DeallocTests`.
- Swift 6.1 (Xcode 16.3) is required. Turning the trait off from an Xcode project needs Xcode 26.4.
- `DefaultInitializable` is removed.
- `DeallocTester`, `DeallocTest`, `DeallocTestable` and `ClassNameIdentifiable` are removed. Each `DeallocTest` becomes one `expectDeallocation` call; see "Migrating to 4.0" in the README.

### Fixed
- The dependency URL uses https, so the package resolves without SSH access to GitHub.

### Removed
- Travis CI, Danger, Carthage, jazzy and unused headers.
