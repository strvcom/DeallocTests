<p align="center">
    <img src="https://i.ibb.co/pWcqs9c/Dealloc-Tests-Git-Hub.png" width="100%" alt="MemoryLeak" />
</p>

# DeallocTests
DeallocTests are a tool for automated memory leak detection in Swift iOS apps. DeallocTests are a special kind of unit tests that can be easily added to your existing project. They can separately check isolated parts of your app to ensure that every part is managing memory correctly. The basic principle is easy: DeallocTests try to instantiate an object (ViewController, ViewModel, Manager, etc.) and, after a short period, try to deallocate it from memory. DeallocTests check whether the object’s `deinit` was called properly—which is the case if there is no retain cycle and possible memory leak.

Of course, there are also other tools for memory leak detection, namely Instruments and, more recently, Memory Debugger within Xcode. These tools are useful for catching a particular memory leak. What is specific about DeallocTests is that they provide tests automatically and it is possible to run them on CI as well.

It is very easy to create a memory leak by mistake. Memory leaks have various forms; it’s not always about just forgetting to add `[weak self]` to closures. That's why it is very important to prevent them from happening. DeallocTests can help with their detection.

## When can I use DeallocTests?

DeallocTests work well with apps that use MVVM-C (MVVM with ViewCoordinators) architecture. Using coordinators helps to make the ViewControllers independent and easily constructible. DeallocTests work great with Swinject, the dependency injection framework. And best of all—DeallocTests don’t need any modifications of the main target of your app.

####  Does it sound too good to be true :-)? Hold on…

## Testing

1) We can focus on view controller testing. Apps written in MVVM-C architecture often have many screens (view controllers) that are grouped with view coordinators. The recommended approach is to create a separate deallocation test scenario for each view coordinator. DeallocTests present the view controllers in view coordinator one-by-one (the method of presentation is not important). If a memory leak is found, the test fails with an error that can help you find the leak. After successful tests of all of the coordinator's controllers, the coordinator itself is checked for memory leaks.

2) Testing of "invisible" objects. Apps often have plenty of classes that encapsulate business logic: Managers, Services, Models, ViewModels, etc. These objects can be checked for deallocation, too. The recommended approach here is to create the testing scenario in order of simplicity. The most simple classes with no dependencies should be checked first, followed by the classes that use the already-tested classes as their dependencies, etc. On the following figure you are supposed to test the `APIManager` first, then `WeatherService` and only then `ForecastViewModel`:

<p align="center">
    <img src="https://i.ibb.co/GCfh7Ty/Dependency-Graph.png" width="400" max-width="90%" alt="DependencyGraph" />
</p>

## Swinject

The main version of DeallocTests uses Swinject dependency injection framework as the only dependency. Swinject is often considered to be the leading dependency injection framework and it is part of almost every STRV iOS app. The support of dependency injection is great benefit but DeallocTests can work also without it if needed. If you don't use Swinject in your app, use `feature/swinject-free branch` instead.

##  DeallocTests. Easy-to-use framework for custom deallocation tests.

- [Requirements](#requirements)
- [Installation](#installation)
- [License](#license)

## Requirements

- iOS 8.0+ / Mac OS X 10.10+ / tvOS 9.0+ / watchOS 2.0+
- Xcode 10.0+

## Installation

### Dependency Managers
<details>
  <summary><strong>CocoaPods</strong></summary>

[CocoaPods](http://cocoapods.org) is a dependency manager for Cocoa projects. You can install it with the following command:

```bash
$ gem install cocoapods
```

To integrate DeallocTests into your Xcode project using CocoaPods, specify it in your `Podfile`:

```ruby
source 'https://github.com/CocoaPods/Specs.git'
platform :ios, '8.0'
use_frameworks!

pod 'DeallocTests', '~> 0.0.1'
```

Then, run the following command:

```bash
$ pod install
```

</details>

<details>
  <summary><strong>Swift Package Manager</strong></summary>

To use DeallocTests as a [Swift Package Manager](https://swift.org/package-manager/) package just add the following in your Package.swift file.

``` swift
// swift-tools-version:4.2

import PackageDescription

let package = Package(
    name: "HelloDeallocTests",
    dependencies: [
        .package(url: "https://github.com/DanielCech/DeallocTests.git", .upToNextMajor(from: "0.0.1"))
    ],
    targets: [
        .target(name: "HelloDeallocTests", dependencies: ["DeallocTests"])
    ]
)
```
</details>

### Manually

If you prefer not to use either of the aforementioned dependency managers, you can integrate DeallocTests into your project manually.

<details>
  <summary><strong>Git Submodules</strong></summary><p>

- Open up Terminal, `cd` into your top-level project directory, and run the following command "if" your project is not initialized as a git repository:

```bash
$ git init
```

- Add DeallocTests as a git [submodule](http://git-scm.com/docs/git-submodule) by running the following command:

```bash
$ git submodule add https://github.com/DanielCech/DeallocTests.git
$ git submodule update --init --recursive
```

- Open the new `DeallocTests` folder, and drag the `DeallocTests.xcodeproj` into the Project Navigator of your application's Xcode project.

    > It should appear nested underneath your application's blue project icon. Whether it is above or below all the other Xcode groups does not matter.

- Select the `DeallocTests.xcodeproj` in the Project Navigator and verify the deployment target matches that of your application target.
- Next, select your application project in the Project Navigator (blue project icon) to navigate to the target configuration window and select the application target under the "Targets" heading in the sidebar.
- In the tab bar at the top of that window, open the "General" panel.
- Click on the `+` button under the "Embedded Binaries" section.
- You will see two different `DeallocTests.xcodeproj` folders each with two different versions of the `DeallocTests.framework` nested inside a `Products` folder.

    > It does not matter which `Products` folder you choose from.

- Select the `DeallocTests.framework`.

- And that's it!

> The `DeallocTests.framework` is automagically added as a target dependency, linked framework and embedded framework in a copy files build phase which is all you need to build on the simulator and a device.

</p></details>

<details>
  <summary><strong>Embedded Binaries</strong></summary><p>

- Download the latest release from https://github.com/DanielCech/DeallocTests/releases
- Next, select your application project in the Project Navigator (blue project icon) to navigate to the target configuration window and select the application target under the "Targets" heading in the sidebar.
- In the tab bar at the top of that window, open the "General" panel.
- Click on the `+` button under the "Embedded Binaries" section.
- Add the downloaded `DeallocTests.framework`.
- And that's it!

</p></details>

## Sample App

The folder SampleApps contains a demo project that demonstrates at least some features. The application itself is very simple—there are just three screens in the navigation stack. All screens are handled by `MainCoordinator`.

The Podfile adds DeallocTests support to the app's test target.

```ruby
target 'DeallocTestsAppCocoapodsTests' do
  pod 'DeallocTests', :path=>'../../'
end
```

The file `DeallocTestsConformances.swift` contains the DeallocTestable protocol conformances to all tested classes.

```swift
import DeallocTests
@testable import DeallocTestsAppCocoapods

extension MainCoordinator: DeallocTestable {}
extension FirstViewController: DeallocTestable {}
extension SecondViewController: DeallocTestable {}
extension ThirdViewController: DeallocTestable {}
```

The file `MainCoordinatorDeallocTester.swift` is also very simple. It defines the testing scenario for MainCoordinator.

```swift
var mainCoordinator: MainCoordinator? {
    applyAssembliesToContainer()
    return MainCoordinator()
}
```

This will initialize a Swinject dependency container and instantiate the main coordinator. The method `applyAssembliesToContainer` is defined in the main target. The scenario for the main coordinator test looks like this: (Don't be scared, it is almost boilerplate code which is common for every test scenario.)

```swift
func test_mainCoordinatorDealloc() {
    presentingController = showPresentingController()

    deallocTests = [
        DeallocTest(
            objectCreation: { [weak self] _ in
                return self?.mainCoordinator?.createFirstViewController()
            }
        ),
        DeallocTest(
            objectCreation: { [weak self] _ in
                return self?.mainCoordinator?.createSecondViewController()
            }
        ),
        DeallocTest(
            objectCreation: { [weak self] _ in
                return self?.mainCoordinator?.createThirdViewController()
            }
        ),
        DeallocTest(
            objectCreation: { _ in
                return MainCoordinator()
            }
        )
    ]

    let expectation = self.expectation(description: "deallocTest test_mainCoordinatorDealloc")

    performDeallocTest(
        deallocTests: deallocTests,
        expectation: expectation
    )

    waitForExpectations(timeout: 200, handler: nil)
}
```

The variable `presentingController` is just simple empty controller on top of everything - it is handled by DeallocTests framework. The array `deallocTests` consists of four items. The first three are for view controllers and the last one is for the view coordinator itself. The `objectCreation` closure initializes the particular view controller from the view coordinator. The `expectation` is a standard `XCTestExpectation` used to wait for the result of the test. The main test processing is hidden in the `performDeallocTest` call.

The sample app intentionally contains a memory leak in SecondViewController.swift. This class contains the closure with a strong reference to `self`. The DeallocTests console output looks like this:

```
Checking:
Alloc FirstViewController
Dealloc FirstViewController

Checking:
Alloc SecondViewController
/Users/danielcech/Documents/[Development]/[Projects]/ios-research-dealloc-tests/Sources/Core/DeallocTester.swift:175: error: -[DeallocTestsAppCocoapodsTests.MainCoordinatorDeallocTester test_mainCoordinatorDealloc] : failed - Failed: dealloc test failed on classes: [DeallocTestsAppCocoapods.SecondViewController]

Checking:
Alloc ThirdViewController
Dealloc ThirdViewController

Checking:
Alloc MainCoordinator
Dealloc MainCoordinator
```

If you comment out the first line and uncomment the second one, you will see that the retain cycle disappears and the test will succeed.

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

DeallocTests is released under the MIT license. See [LICENSE](https://github.com/DanielCech/DeallocTests/blob/master/LICENSE) for details.
