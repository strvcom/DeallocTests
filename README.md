

[![Platforms](https://img.shields.io/cocoapods/p/DeallocTests.svg)](https://cocoapods.org/pods/DeallocTests)
[![License](https://img.shields.io/cocoapods/l/DeallocTests.svg)](https://raw.githubusercontent.com/DanielCech/DeallocTests/master/LICENSE)

[![Swift Package Manager](https://img.shields.io/badge/Swift%20Package%20Manager-compatible-brightgreen.svg)](https://github.com/apple/swift-package-manager)
[![Carthage compatible](https://img.shields.io/badge/Carthage-compatible-4BC51D.svg?style=flat)](https://github.com/Carthage/Carthage)
[![CocoaPods compatible](https://img.shields.io/cocoapods/v/DeallocTests.svg)](https://cocoapods.org/pods/DeallocTests)

[![Travis](https://img.shields.io/travis/DanielCech/DeallocTests/master.svg)](https://travis-ci.org/DanielCech/DeallocTests/branches)
[![SwiftFrameworkTemplate](https://img.shields.io/badge/SwiftFramework-Template-red.svg)](http://github.com/RahulKatariya/SwiftFrameworkTemplate)

<p align="center">
    <img src="https://i.ibb.co/z4KTcDq/Pipe.jpg" width="320" max-width="90%" alt="MemoryLeak" />
</p>

# DeallocTests
DeallocTests are tool for memory leak detection of your app. DeallocTests are special kind of unit tests that can be easily added to your existing project. They can check separately the isolated parts of your app whether they manage the memory correctly. The basic principle is easy: DeallocationTests try to instantiate the object (ViewController, ViewModel, Manager, …) and after short period try to deallocate it from memory. DeallocTests are checking whether object’s `deinit` was called properly. It means that there is no retain cycle and possible memory leak.

Of course there are also other tools for memory leaks detection - Instruments and more recently also Memory Debugger within the Xcode. These tools are useful when catching particular memory leak. On the other side DeallocTests  provide tests automatically and it is possible to run them also on CI.

It is very easy to create memory leak by mistake. Memory leaks have different forms - it is simply not always forgotten `[weak self]`. That's why it is very important to prevent them from happening. DeallocTests can help with their detection.

## When can I use DeallocTests?

DeallocTests work well with app which uses MVVM-C (MVVM with ViewCoordinators) architecture. Using coordinators helps to make the ViewControllers independent and easily constructable. DeallocTests work great with Swinject dependency injection framework. And best of all - DeallocTests need no modification of main target of your app.

####  Does it sound too good to be true :-)? Hold on…

1) We can focus on view controller testing. The apps in MVVM-C have often many screens (view controllers) that are grouped with view coordinators. The recommended approach is to create a separate deallocation test scenario for each view coordinator. DeallocTests presents the view controllers in view coordinator one-by-one (the method of presentation is not important). If memory leak is found, test fails and shows the details. After successful test of all view coordinator's controllers is the view coordinator itself checked for memory leaks.

2) Testing of "invisible" objects. The apps have often a plenty of classes that encapsulate the business logic - Managers, Services, Models, ViewModels, etc. Those objects can be checked for deallocation too. The recommended approach here is to create the testing scenario in order of simplicity. The most simple classes with no dependencies should be checked first, then the classes that uses already tested as it's dependencies, etc. The dependency graph can look like this:

<p align="center">
    <img src="https://i.ibb.co/GCfh7Ty/Dependency-Graph.png" width="400" max-width="90%" alt="DependencyGraph" />
</p>

## Sample App

The folder SampleApps contains the demo project that demostrates at least some features. We recommend to use DeallocTests with Cocoapods, the support for Carthage and SPM is possible but not maintained. The application itself is very simple - there are just three screens in navigation stack. All screens are handled by `MainCoordinator`.

The Podfile adds DeallocTests support to the app's test target. 
```ruby
target 'DeallocTestsAppCocoapodsTests' do
  pod 'DeallocTests', :path=>'../../'
end
```

The file `DeallocTestsConformances.swift` contains the `DeallocTestable` protocol conformances to all tested classes. 

```swift
import DeallocTests
@testable import DeallocTestsAppCocoapods

extension MainCoordinator: DeallocTestable {}
extension FirstViewController: DeallocTestable {}
extension SecondViewController: DeallocTestable {}
extension ThirdViewController: DeallocTestable {}
```

The file `MainCoordinatorDeallocTester.swift` is also very simple. It defines the testing scenario for MainCoordinator. Let's talk about it's parts.
```swift
var mainCoordinator: MainCoordinator? {
    applyAssembliesToContainer()
    return MainCoordinator()
}
```
This will inicialize the Swinject dependency container and instantiate the main coordinator. The method `applyAssembliesToContainer` is defined in main target. The  scenario for main coordinator test looks like this:
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
        index: 0,
        deallocTests: deallocTests,
        expectation: expectation
    )

    waitForExpectations(timeout: 200, handler: nil)
}
```
The array `deallocTests` consists of four items. First three are for view controllers and last one is for view coordinator itself. The `objectCreation` closure initializes the particular view controller from view coordinator. The `expectation` is standard `XCTestExpectation` used to wait for result of test. The main test processing is hidden in `performDeallocTest` call.

The sample app contains intentionally a memory leak in SecondViewController.swift. This class contains the closure with strong reference to `self`.
The DeallocTests console output looks like this:
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
If you comment first line and uncomment the second one, you will see that retain cycle disappears and test will succeed.
```swift
    someClosure = { number in self.view(number) }
     // someClosure = { [weak self] number in self?.view(number) }
```

You can find more advanced example of usage bellow. These dealloc tests contain both view coordinator testing and also "invisible" objects testing under real app conditions.
* https://github.com/strvcom/ios-learning-department-app.git
* https://github.com/strvcom/iWeather-MVVM.git


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
  <summary><strong>Carthage</strong></summary>

[Carthage](https://github.com/Carthage/Carthage) is a decentralized dependency manager that automates the process of adding frameworks to your Cocoa application.

You can install Carthage with [Homebrew](http://brew.sh/) using the following command:

```bash
$ brew update
$ brew install carthage
```

To integrate DeallocTests into your Xcode project using Carthage, specify it in your `Cartfile`:

```ogdl
github "DanielCech/DeallocTests" ~> 0.0.1
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

## Contributing

Issues and pull requests are welcome!

## Authors

* Daniel Čech [GitHub](https://github.com/DanielCech) 
* Jan Kaltoun [GitHub](https://github.com/jankaltoun)

## License

DeallocTests is released under the MIT license. See [LICENSE](https://github.com/DanielCech/DeallocTests/blob/master/LICENSE) for details.
