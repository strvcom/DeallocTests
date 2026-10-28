# ``DeallocTests``

Catch memory leaks in unit tests: check that view controllers, view models and services deallocate.

## Overview

DeallocTests creates an object, runs its lifecycle, releases it and checks that its `deinit` was called.
If something still holds the object, typically a retain cycle, the test fails at your line and the
message points at the likely cause:

```swift
import DeallocTests
import Testing
@testable import MyApp

@MainActor
struct LeakTests {
    let coordinator = MainCoordinator()

    @Test func profileScreen() async {
        await expectDeallocation(.present) { coordinator.createProfileViewController() }
    }

    @Test func profileViewModel() async {
        await expectDeallocation { ProfileViewModel(api: MockAPI()) }
    }
}
```

```
LeakTests.swift:12: MyApp.ProfileViewController was not deallocated within 2 sec. It was watched for another 3 sec after that. Possible causes:
  • `onUpdate` is a closure. Make sure it captures self weakly
  • `self.viewModel.owner` refers back to the object. That's a retain cycle unless one of the references is weak
  • Or something outside still holds it: a parent's list of children, a cache or a singleton
```

It works in Swift Testing and XCTest, any class can be checked without conformances, and the app
target doesn't change. Unlike Instruments or the Memory Graph Debugger, the checks run on every
test run, including CI.

## Topics

### Essentials

- <doc:GettingStarted>
- <doc:MigratingTo4>

### Checking an object

- ``expectDeallocation(_:timeout:afterRelease:fileID:filePath:line:column:of:)``
- ``Lifecycle``

### Checking objects used in ordinary unit tests

- ``trackForDeallocation(_:fileID:filePath:line:column:)``
- ``Testing/Trait/checksDeallocation``
- ``DeallocationCheckTrait``

### Configuration

- <doc:ConfigurationAndGracePeriod>
- ``DeallocationConfiguration``
- ``DeallocationIssueSeverity``
- ``withDeallocationConfiguration(_:isolation:operation:)``
- ``withDeallocationConfiguration(_:operation:)``
- ``DeallocationConfigurationTrait``

### STRV Dependency Injection

- ``expectDeallocation(of:resolvedFrom:timeout:fileID:filePath:line:column:)``
