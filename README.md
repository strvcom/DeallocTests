<p align="center">
    <img src="https://i.ibb.co/pWcqs9c/Dealloc-Tests-Git-Hub.png" width="100%" alt="MemoryLeak" />
</p>

# DeallocTests
DeallocTests are a tool for automated memory leak detection in Swift iOS apps. DeallocTests are a special kind of unit tests that can be easily added to your existing project. They can separately check isolated parts of your app to ensure that every part is managing memory correctly. The basic principle is easy: DeallocTests try to instantiate an object (ViewController, ViewModel, Manager, etc.) and, after a short period, try to deallocate it from memory. DeallocTests check whether the object’s `deinit` was called properly—which is the case if there is no retain cycle and possible memory leak.

Of course, there are also other tools for memory leak detection, namely Instruments and, more recently, Memory Debugger within Xcode. These tools are useful for catching a particular memory leak. What is specific about DeallocTests is that they provide tests automatically and it is possible to run them on CI as well.

It is very easy to create a memory leak by mistake. Memory leaks have various forms; it’s not always about just forgetting to add `[weak self]` to closures. That's why it is very important to prevent them from happening. DeallocTests can help with their detection.

## When can I use DeallocTests?

DeallocTests work well with apps that use MVVM-C (MVVM with ViewCoordinators) architecture. Using coordinators helps to make the ViewControllers independent and easily constructible. DeallocTests work great with [STRV Dependency Injection library](https://github.com/strvcom/ios-dependency-injection). And best of all—DeallocTests don’t need any modifications of the main target of your app.

####  Does it sound too good to be true :-)? Hold on…

## Testing

1) We can focus on view controller testing. Apps written in MVVM-C architecture often have many screens (view controllers) that are grouped with view coordinators. The recommended approach is to create a separate deallocation test scenario for each view coordinator. DeallocTests present the view controllers in view coordinator one-by-one (the method of presentation is not important). If a memory leak is found, the test fails with an error that can help you find the leak. After successful tests of all of the coordinator's controllers, the coordinator itself is checked for memory leaks.

2) Testing of "invisible" objects. Apps often have plenty of classes that encapsulate business logic: Managers, Services, Models, ViewModels, etc. These objects can be checked for deallocation, too. The recommended approach here is to create the testing scenario in order of simplicity. The most simple classes with no dependencies should be checked first, followed by the classes that use the already-tested classes as their dependencies, etc. On the following figure you are supposed to test the `APIManager` first, then `WeatherService` and only then `ForecastViewModel`:

<p align="center">
    <img src="https://i.ibb.co/GCfh7Ty/Dependency-Graph.png" width="400" max-width="90%" alt="DependencyGraph" />
</p>

## STRV Dependency Injection library

DeallocTests integrates with [STRV Dependency Injection library](https://github.com/strvcom/ios-dependency-injection). The integration is the `DependencyInjection` [package trait](#installation), which is on by default. Projects that don't use STRV Dependency Injection can turn it off, and the library is then not even downloaded.

## Requirements

- iOS 17.0+ / macOS 13.0+
- Swift 6.1+ / Xcode 16.3+
- Swift Testing or XCTest
- Turning the `DependencyInjection` trait off from an Xcode project needs Xcode 26.4 or later

## Installation

DeallocTests is distributed via [Swift Package Manager](https://swift.org/package-manager/). Add it to the **test target** of your app:

``` swift
// swift-tools-version:6.1

import PackageDescription

let package = Package(
    name: "HelloDeallocTests",
    dependencies: [
        .package(url: "https://github.com/strvcom/DeallocTests.git", .upToNextMajor(from: "4.0.0"))
    ],
    targets: [
        .testTarget(
            name: "HelloDeallocTestsTests",
            dependencies: [
                "HelloDeallocTests",
                .product(name: "DeallocTests", package: "DeallocTests")
            ]
        )
    ]
)
```

This includes the STRV Dependency Injection integration. If your project doesn't use STRV Dependency Injection, turn off the default trait, so the library isn't downloaded:

``` swift
.package(url: "https://github.com/strvcom/DeallocTests.git", .upToNextMajor(from: "4.0.0"), traits: [])
```

In Xcode, add the package via *File › Add Package Dependencies…* and link the `DeallocTests` product to your test target only. To turn the STRV Dependency Injection integration off, disable the package's default traits in Xcode 26.4 or later. The package reference in the project file then has an empty list:

```
traits = (
);
```

## Usage

### `expectDeallocation` (recommended)

`expectDeallocation` creates an object, runs its lifecycle, releases it and checks that it deallocates. It works in **Swift Testing and XCTest**, any class can be checked without a `DeallocTestable` conformance, and a leak is reported at the line of your test.

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

    @Test func settingsScreen() async {
        await expectDeallocation(.push) { coordinator.createSettingsViewController() }
    }

    @Test func profileViewModel() async {
        await expectDeallocation { ProfileViewModel(api: MockAPI()) }
    }
}
```

The same calls work inside an `XCTestCase`. A leak fails at the line of the test, and the message points at the likely cause:

```
LeakTests.swift:12: MyApp.ProfileViewController was not deallocated within 2 sec. Possible causes:
  • `onUpdate` is a closure. Make sure it captures self weakly
  • `self.viewModel.owner` refers back to the object. That's a retain cycle unless one of the references is weak
  • Or something outside still holds it: a parent's list of children, a cache or a singleton
```

The hints come from the leaked object's stored properties: closures, `Task`s, Combine subscriptions, timers, and reference cycles through properties. Reflection can't tell weak properties from strong ones or look inside closures, so treat them as suggestions.

Many leaks only appear once a screen loads or appears, so pick the lifecycle that exercises the object:

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

To also check objects the tested one owns, wrap them in `trackForDeallocation` inside the closure. They must deallocate together with it:

```swift
await expectDeallocation(.present) {
    let viewModel = trackForDeallocation(ProfileViewModel(api: MockAPI()))
    return ProfileViewController(viewModel: viewModel)
}
```

Other parameters:

- `timeout` sets how long to wait for the deallocation (2 seconds by default). The check passes as soon as the object is gone.
- An object still alive at the timeout is watched for a **grace period** (3 seconds by default). If it goes away then, the check reports a warning, "released after 3.2 sec … bounded retention, not a leak", instead of failing. Only real leaks fail, and they take the timeout plus the grace period to report.

#### Configuring a suite

Instead of passing the same values to every call, configure a test or a whole suite with traits:

```swift
@Suite(.deallocationTimeout(.seconds(5)))
struct ScreenDeallocTests { … }

// Adopting dealloc tests in an existing project: report leaks as warnings for now
@Suite(.deallocationIssues(.warning))
struct LegacyDeallocTests { … }
```

A test's own trait wins over its suite's, and a value passed to the call wins over both. In XCTest, use `withDeallocationConfiguration`:

```swift
await withDeallocationConfiguration({ $0.timeout = .seconds(5) }) {
    await expectDeallocation(.present) { makeProfileViewController() }
}
```
- `afterRelease` runs after the object is released and before the check, e.g. to clear a cache that legitimately holds it.

`.present` needs a test target with a host app, because modal presentation needs a window scene. The other lifecycles also work in package tests.

### Checking objects used in ordinary unit tests

`trackForDeallocation` checks that an object deallocates when the test ends, so any unit test can catch leaks of its system under test.

```swift
// Swift Testing: add the trait to a test or a whole suite
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

In XCTest, keep the object in a local variable. A property of the test case lives until the test case is released.

### STRV Dependency Injection

With the `DependencyInjection` trait, a dependency can be resolved from an `AsyncContainer`, released together with the container's shared instances and checked:

```swift
@Test func apiManager() async {
    let container = AsyncContainer()
    await container.register(type: APIManaging.self, in: .shared) { _ in APIManager() }

    await expectDeallocation(of: APIManaging.self, resolvedFrom: container)
}
```

Following the dependency graph, check the simplest dependencies first, then the ones that use them.

### Deprecated: `DeallocTester`

`DeallocTester`, `DeallocTest` and `DeallocTestable` are deprecated in 4.0 and will be removed in 5.0. They still work. See [Migrating to 4.0](#migrating-to-40).

<details>
  <summary>Documentation of the deprecated API</summary>

1. Conform the tested classes to `DeallocTestable` in your test target. No changes to the main target are needed:

```swift
import DeallocTests
@testable import MyApp

extension MainCoordinator: @retroactive DeallocTestable {}
extension FirstViewController: @retroactive DeallocTestable {}
```

2. Subclass `DeallocTester` and describe the scenario:

```swift
import DeallocTests
@testable import MyApp

final class MainCoordinatorDeallocTester: DeallocTester {
    @MainActor
    func test_mainCoordinatorDealloc() async {
        let mainCoordinator = MainCoordinator()
        let expectation = expectation(description: "dealloc test")

        await performDeallocTest(
            deallocTests: [
                DeallocTest(objectCreation: { [mainCoordinator] _ in mainCoordinator.createFirstViewController() }),
                DeallocTest(objectCreation: { [mainCoordinator] _ in mainCoordinator.createSecondViewController() }),
                DeallocTest(objectCreation: { _ in MainCoordinator() })
            ],
            expectation: expectation
        )

        await fulfillment(of: [expectation], timeout: 60)
    }
}
```

Each `DeallocTest` creates an object, releases it and checks that it was deallocated:

- A `UIViewController` is presented full screen and dismissed first, so its whole lifecycle runs. The presenting controller is created automatically. You can still call `showPresentingController()` and assign `presentingController` yourself.
- Any other object is released right away.
- After release, DeallocTests waits up to `deallocationTimeout` (2 seconds by default) for every tracked instance to deallocate. Leaks are detected per instance, so a second leaked instance of the same class is caught.
- `checkClasses` restricts the check to the listed classes. Each listed class must have been tracked (it is `DeallocTestable` and `initializeDeallocTestSupport()` was called on it).
- `actionBeforeCheck` runs after the object is released and before the check.
- A failing step is reported with `XCTFail` and the scenario continues with the next step. The expectation is always fulfilled.

Set `DeallocTester.isLoggingEnabled = true` to print `Alloc`/`Dealloc` messages for every tracked object.

#### Dependency Injection in `DeallocTester`

With the `DependencyInjection` trait, `objectCreation` receives an `AsyncContainer`. Before every step the container is cleaned and `registerDependencies()` is called. Shared instances are released before the check:

```swift
final class DependencyGraphDeallocTester: DeallocTester {
    override func registerDependencies() async {
        await container.register(type: APIManaging.self, in: .shared) { _ in APIManager() }
    }

    @MainActor
    func test_dependencyGraphDealloc() async {
        let expectation = expectation(description: "dealloc test")

        await performDeallocTest(
            deallocTests: [
                DeallocTest(objectCreation: { await $0.resolve(type: APIManaging.self) as AnyObject })
            ],
            expectation: expectation
        )

        await fulfillment(of: [expectation], timeout: 60)
    }
}
```

Without the trait, `objectCreation` takes no parameter: `DeallocTest(objectCreation: { MyObject() })`.

</details>

## Migrating to 4.0

**Dependency Injection.** The `DeallocTestsDIFree` product is gone. Everyone uses the `DeallocTests` product and `import DeallocTests`:

- If you used `DeallocTests` with STRV Dependency Injection, nothing changes. The `DependencyInjection` trait is on by default.
- If you used `DeallocTestsDIFree`, link the `DeallocTests` product instead, replace `import DeallocTestsDIFree` with `import DeallocTests`, and turn the default trait off (see [Installation](#installation)) so STRV Dependency Injection isn't downloaded.

**`DeallocTester`.** Existing tests keep working but produce deprecation warnings. Each `DeallocTest` becomes one `expectDeallocation` call, and the `DeallocTestable` conformances can be deleted:

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
| `registerDependencies()` + `objectCreation: { $0.resolve(...) }` | `expectDeallocation(of:resolvedFrom:)` with your own `AsyncContainer` |
| `checkClasses` | `trackForDeallocation(_:)` inside the closure |
| `actionBeforeCheck` | `afterRelease` |
| `deallocationTimeout` | `timeout` |

**`DefaultInitializable`** is removed. It wasn't related to dealloc testing.

## Sample Apps

The folder `SampleApps` contains two demo projects. The application itself is very simple: there are just three screens in the navigation stack, all handled by `MainCoordinator`.

- `DeallocTestsAppDIFreeSPM` checks the screens and the coordinator with `expectDeallocation` in **XCTest** (`MainCoordinatorDeallocTester.swift`).
- `DeallocTestsAppDIFreeSPM` turns the `DependencyInjection` trait off in its Xcode project, so STRV Dependency Injection isn't downloaded.
- `DeallocTestsAppSPM` uses the default `DependencyInjection` trait. `ExpectDeallocationTests.swift` does the checks with `expectDeallocation` in **Swift Testing**, including a service resolved from an `AsyncContainer`. The other test files show the deprecated `DeallocTester` API.

The sample app intentionally contains a memory leak in `SecondViewController.swift`. This class contains a closure with a strong reference to `self`. The test fails with:

```
MainCoordinatorDeallocTester.swift:25: error: -[DeallocTestsAppSPMTests.MainCoordinatorDeallocTester test_secondScreen] : failed - DeallocTestsAppSPM.SecondViewController was not deallocated within 2 sec. Possible causes:
  • `someClosure` is a closure. Make sure it captures self weakly
  • Or something outside still holds it: a parent's list of children, a cache or a singleton
```

If you comment out the first line and uncomment the second one, the retain cycle disappears and the test will succeed.

```swift
    someClosure = { number in self.view(number) }
     // someClosure = { [weak self] number in self?.view(number) }
```

## Contributing

Issues and pull requests are welcome!

## Authors

* Daniel Čech [GitHub](https://github.com/DanielCech)
* Jan Kaltoun [GitHub](https://github.com/jankaltoun)

## License

DeallocTests is released under the MIT license. See [LICENSE](https://github.com/strvcom/DeallocTests/blob/master/LICENSE) for details.
