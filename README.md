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

The main version of DeallocTests uses [STRV Dependency Injection library](https://github.com/strvcom/ios-dependency-injection) as the only dependency. The support of dependency injection is a great benefit, but DeallocTests also work without it. If you don't use STRV Dependency Injection in your app, use the `DeallocTestsDIFree` product instead.

## Requirements

- iOS 17.0+ / macOS 13.0+
- Swift 6.0+ / Xcode 16.0+
- XCTest

## Installation

DeallocTests is distributed via [Swift Package Manager](https://swift.org/package-manager/). Add it to the **test target** of your app:

``` swift
// swift-tools-version:6.0

import PackageDescription

let package = Package(
    name: "HelloDeallocTests",
    dependencies: [
        .package(url: "https://github.com/strvcom/DeallocTests.git", .upToNextMajor(from: "3.1.0"))
    ],
    targets: [
        .testTarget(
            name: "HelloDeallocTestsTests",
            dependencies: [
                "HelloDeallocTests",
                // or "DeallocTestsDIFree" if you don't use STRV Dependency Injection
                .product(name: "DeallocTests", package: "DeallocTests")
            ]
        )
    ]
)
```

In Xcode, add the package via *File › Add Package Dependencies…* and link the `DeallocTests` (or `DeallocTestsDIFree`) product to your test target only.

## Usage

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

### STRV Dependency Injection

With the `DeallocTests` product, `objectCreation` receives an `AsyncContainer`. Before every step the container is cleaned and `registerDependencies()` is called. Shared instances are released before the check:

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

With `DeallocTestsDIFree`, `objectCreation` takes no parameter: `DeallocTest(objectCreation: { MyObject() })`.

## Sample Apps

The folder `SampleApps` contains two demo projects, `DeallocTestsAppSPM` (with STRV Dependency Injection) and `DeallocTestsAppDIFreeSPM`. The application itself is very simple: there are just three screens in the navigation stack, all handled by `MainCoordinator`.

- `DeallocTestConformances.swift` adds the `DeallocTestable` conformances to all tested classes.
- `MainCoordinatorDeallocTester.swift` defines the testing scenario for `MainCoordinator`: the three view controllers one by one, then the coordinator itself.
- `DependencyGraphDeallocTester.swift` (DI sample only) checks a service resolved from the container.

The sample app intentionally contains a memory leak in `SecondViewController.swift`. This class contains a closure with a strong reference to `self`. The test fails with:

```
DeallocTester.swift:233: error: -[DeallocTestsAppSPMTests.MainCoordinatorDeallocTester test_mainCoordinatorDealloc] : failed - Failed: dealloc test #1 failed on classes: [DeallocTestsAppSPM.SecondViewController] (1 tracked instance(s) still alive)
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
