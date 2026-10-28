# Getting Started

Add DeallocTests to your test target and write your first deallocation checks.

## Overview

A deallocation check creates an object, uses it the way the app does, releases it and waits
for its `deinit`. Leaks often appear only once a screen loads or appears, so the check runs the
object through a ``Lifecycle`` first.

### Add the package

Add DeallocTests to the **test target** of your app:

```swift
.package(url: "https://github.com/strvcom/DeallocTests.git", .upToNextMajor(from: "4.0.0"))
```

```swift
.testTarget(
    name: "MyAppTests",
    dependencies: [
        "MyApp",
        .product(name: "DeallocTests", package: "DeallocTests")
    ]
)
```

In Xcode, add the package via *File › Add Package Dependencies…* and link the `DeallocTests`
product to your test target only.

The integration with [STRV Dependency Injection](https://github.com/strvcom/ios-dependency-injection)
is the `DependencyInjection` package trait, which is on by default. If your project doesn't use it,
turn the default traits off, so the library isn't downloaded:

```swift
.package(url: "https://github.com/strvcom/DeallocTests.git", .upToNextMajor(from: "4.0.0"), traits: [])
```

In an Xcode project, disable the package's default traits in Xcode 26.4 or later.

### Check a screen

``expectDeallocation(_:timeout:afterRelease:fileID:filePath:line:column:of:)`` takes the lifecycle
and a closure that creates the object. Don't keep any other reference to the object, or the check
reports it as a leak.

```swift
@MainActor
struct ProfileLeakTests {
    let coordinator = MainCoordinator()

    @Test func profileScreen() async {
        await expectDeallocation(.present) { coordinator.createProfileViewController() }
    }
}
```

The same call works inside an `XCTestCase`.

### Choose a lifecycle

| Lifecycle | What happens before release |
|---|---|
| `.none` (default) | Nothing, the object is released right away |
| `.loadView` | The view controller loads its view (`viewDidLoad`). UIKit and AppKit. |
| `.present`, `.present(style:interaction:)` | The view controller is presented in a test window, then dismissed |
| `.push`, `.push(interaction:)` | The view controller is pushed onto a navigation controller in a test window, then popped |
| `.hosting { object in SomeView(model: object) }` | A SwiftUI view built from the object is shown in a test window, then removed. `onAppear` and `.task` run. |
| `.custom { object in … }` | Your code runs with the object, e.g. calls the methods you suspect of leaking |

`interaction` runs while the controller is on screen:

```swift
await expectDeallocation(.present(interaction: { controller in
    controller.searchBar.text = "query"
    await controller.search()
})) {
    coordinator.createSearchViewController()
}
```

SwiftUI views are values, so check the object behind them, typically the view model:

```swift
await expectDeallocation(.hosting { ProfileView(viewModel: $0) }) {
    ProfileViewModel(api: MockAPI())
}
```

`.present` needs a test target with a host app, because modal presentation needs a window scene.
The other lifecycles also work in package tests.

### Check the objects it owns

To also check objects the tested one owns, wrap them in
``trackForDeallocation(_:fileID:filePath:line:column:)`` inside the closure. They must deallocate
together with it:

```swift
await expectDeallocation(.present) {
    let viewModel = trackForDeallocation(ProfileViewModel(api: MockAPI()))
    return ProfileViewController(viewModel: viewModel)
}
```

`afterRelease` runs after the object is released and before the check, e.g. to clear a cache that
legitimately holds it.

### Check objects in ordinary unit tests

Any unit test can catch leaks of its system under test. In Swift Testing, add the
``Testing/Trait/checksDeallocation`` trait to a test or a whole suite. In XCTest, call
`trackForDeallocation(_:)` on the test case. Each tracked object is checked when the test ends.

```swift
// Swift Testing
@Test(.checksDeallocation) @MainActor func loadsProfile() async {
    let viewModel = trackForDeallocation(ProfileViewModel(api: MockAPI()))
    await viewModel.load()
    #expect(viewModel.name == "Daniel")
}

// XCTest
@MainActor
func test_loadsProfile() async {
    let viewModel = trackForDeallocation(ProfileViewModel(api: MockAPI()))
    await viewModel.load()
    XCTAssertEqual(viewModel.name, "Daniel")
}
```

In XCTest, keep the object in a local variable. A property of the test case lives until the test
case is released.

### Check a dependency from STRV Dependency Injection

With the `DependencyInjection` trait, a dependency can be resolved from an `AsyncContainer`,
released together with the container's shared instances and checked:

```swift
@Test func apiManager() async {
    let container = AsyncContainer()
    await container.register(type: APIManaging.self, in: .shared) { _ in APIManager() }

    await expectDeallocation(of: APIManaging.self, resolvedFrom: container)
}
```

### Decide what to check

- **Screens.** Create a check for each screen a coordinator creates, then for the coordinator itself.
- **Everything else.** Managers, services and view models can be checked too. Start with the
  classes without dependencies, then check the ones that use them. A leak in a dependency then
  fails its own test first, instead of every test that uses it.

### Read the hints

The hints in a leak message come from the leaked object's stored properties: closures, `Task`s,
Combine subscriptions, timers, and reference cycles through properties. Reflection can't tell weak
properties from strong ones or look inside closures, so treat them as suggestions.
