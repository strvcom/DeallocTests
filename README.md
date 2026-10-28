<p align="center">
    <img src="https://i.ibb.co/pWcqs9c/Dealloc-Tests-Git-Hub.png" width="100%" alt="MemoryLeak" />
</p>

# DeallocTests
DeallocTests are a tool for automated memory leak detection in Swift iOS apps. DeallocTests are a special kind of unit tests that can be easily added to your existing project. They can separately check isolated parts of your app to ensure that every part is managing memory correctly. The basic principle is easy: DeallocTests try to instantiate an object (ViewController, ViewModel, Manager, etc.) and, after a short period, try to deallocate it from memory. DeallocTests check whether the object’s `deinit` was called properly—which is the case if there is no retain cycle and possible memory leak.

Of course, there are also other tools for memory leak detection, namely Instruments and, more recently, Memory Debugger within Xcode. These tools are useful for catching a particular memory leak. What is specific about DeallocTests is that they provide tests automatically and it is possible to run them on CI as well.

It is very easy to create a memory leak by mistake. Memory leaks have various forms; it’s not always about just forgetting to add `[weak self]` to closures. That's why it is very important to prevent them from happening. DeallocTests can help with their detection.

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

`expectDeallocation` creates an object, runs its lifecycle, releases it and checks that it deallocates. It works in **Swift Testing and XCTest**, any class can be checked without conformances or changes to the app target, and a leak is reported at the line of your test.

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

A leak fails at the line of the test, and the message points at the likely cause:

```
LeakTests.swift:12: MyApp.ProfileViewController was not deallocated within 2 sec. It was watched for another 3 sec after that. Possible causes:
  • `onUpdate` is a closure. Make sure it captures self weakly
  • `self.viewModel.owner` refers back to the object. That's a retain cycle unless one of the references is weak
  • Or something outside still holds it: a parent's list of children, a cache or a singleton
```

Many leaks only appear once a screen loads or appears, so pick the lifecycle that exercises the object: `.loadView`, `.present`, `.push`, `.hosting` for SwiftUI views or `.custom`. Ordinary unit tests can check their system under test with `trackForDeallocation`, and a dependency can be resolved from an STRV Dependency Injection `AsyncContainer` and checked.

## Documentation

The [documentation](https://swiftpackageindex.com/strvcom/DeallocTests/documentation/dealloctests) covers the whole API and has these articles:

- [Getting Started](https://swiftpackageindex.com/strvcom/DeallocTests/documentation/dealloctests/gettingstarted): lifecycles, checking owned objects, checks in ordinary unit tests and STRV Dependency Injection
- [Configuration and Grace Period](https://swiftpackageindex.com/strvcom/DeallocTests/documentation/dealloctests/configurationandgraceperiod): timeouts, the grace period for late releases and reporting leaks as warnings
- [Migrating to 4.0](https://swiftpackageindex.com/strvcom/DeallocTests/documentation/dealloctests/migratingto4): replacing `DeallocTester` and `DeallocTestsDIFree`

In Xcode, *Product › Build Documentation* builds it locally.

## Sample Apps

The folder `SampleApps` contains two demo projects. The application itself is very simple: there are just three screens in the navigation stack, all handled by `MainCoordinator`.

- `DeallocTestsAppDIFreeSPM` checks the screens and the coordinator with `expectDeallocation` in **XCTest** (`MainCoordinatorDeallocTests.swift`).
- `DeallocTestsAppDIFreeSPM` turns the `DependencyInjection` trait off in its Xcode project, so STRV Dependency Injection isn't downloaded.
- `DeallocTestsAppSPM` uses the default `DependencyInjection` trait. `ExpectDeallocationTests.swift` does the checks with `expectDeallocation` in **Swift Testing**, including a service resolved from an `AsyncContainer`.

The sample app intentionally contains a memory leak in `SecondViewController.swift`. This class contains a closure with a strong reference to `self`. The test fails with:

```
MainCoordinatorDeallocTests.swift:23: error: -[DeallocTestsAppSPMTests.MainCoordinatorDeallocTests test_secondScreen] : failed - DeallocTestsAppSPM.SecondViewController was not deallocated within 2 sec. It was watched for another 3 sec after that. Possible causes:
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
