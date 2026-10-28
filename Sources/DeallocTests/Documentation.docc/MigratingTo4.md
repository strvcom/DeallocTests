# Migrating to 4.0

Replace `DeallocTester` with `expectDeallocation` and move from `DeallocTestsDIFree` to the package trait.

## Overview

DeallocTests 4.0 replaces the `DeallocTester` base class with
``expectDeallocation(_:timeout:afterRelease:fileID:filePath:line:column:of:)``, a single call that
works in Swift Testing and XCTest and needs no changes to the app target.

### Dependency Injection

The `DeallocTestsDIFree` product is gone. Everyone uses the `DeallocTests` product and
`import DeallocTests`:

- If you used `DeallocTests` with STRV Dependency Injection, nothing changes. The
  `DependencyInjection` trait is on by default.
- If you used `DeallocTestsDIFree`, link the `DeallocTests` product instead, replace
  `import DeallocTestsDIFree` with `import DeallocTests`, and turn the default traits off
  (see <doc:GettingStarted#Add-the-package>) so STRV Dependency Injection isn't downloaded.

### DeallocTester

`DeallocTester` is removed, together with `DeallocTest`, `DeallocTestable` and
`ClassNameIdentifiable`. Each `DeallocTest` becomes one `expectDeallocation` call, and the
`DeallocTestable` conformances are deleted:

```swift
// Before
final class MainCoordinatorDeallocTester: DeallocTester {
    @MainActor
    func test_mainCoordinatorDealloc() async {
        let coordinator = MainCoordinator()
        let expectation = expectation(description: "dealloc test")

        await performDeallocTest(
            deallocTests: [
                DeallocTest(objectCreation: { _ in coordinator.createFirstViewController() }),
                DeallocTest(objectCreation: { _ in MainCoordinator() })
            ],
            expectation: expectation
        )

        await fulfillment(of: [expectation], timeout: 60)
    }
}

// After (XCTest; in Swift Testing the calls are the same)
final class MainCoordinatorDeallocTests: XCTestCase {
    @MainActor
    func test_firstScreen() async {
        let coordinator = MainCoordinator()
        await expectDeallocation(.present) { coordinator.createFirstViewController() }
    }

    @MainActor
    func test_coordinator() async {
        await expectDeallocation { MainCoordinator() }
    }
}
```

| `DeallocTester` | `expectDeallocation` |
|---|---|
| View controllers are always presented | Choose `.present`, `.push`, `.loadView` or `.hosting` |
| `registerDependencies()` + `objectCreation: { $0.resolve(...) }` | ``expectDeallocation(of:resolvedFrom:timeout:fileID:filePath:line:column:)`` with your own `AsyncContainer` |
| `checkClasses` | ``trackForDeallocation(_:fileID:filePath:line:column:)`` inside the closure |
| `actionBeforeCheck` | `afterRelease` |
| `deallocationTimeout` | `timeout` |
| `isLoggingEnabled` (`Alloc`/`Dealloc` output) | Leak messages name the leaked object and its likely causes |

### DefaultInitializable

`DefaultInitializable` is removed. It wasn't related to dealloc testing.
