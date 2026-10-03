// swift-tools-version:6.1
//
//  Package.swift
//  DeallocTests
//
//  Created by Daniel Cech on 01/04/19.
//  Copyright © 2019 DanielCech. All rights reserved.
//

import PackageDescription

let package = Package(
    name: "DeallocTests",
    platforms: [
        .iOS(.v17),
        .macOS(.v13)
    ],
    products: [
        .library(
            name: "DeallocTests",
            targets: ["DeallocTests"]
        ),
    ],
    traits: [
        .trait(
            name: "DependencyInjection",
            description: "Integration with STRV Dependency Injection: expectDeallocation(of:resolvedFrom:) and the AsyncContainer in DeallocTester"
        ),
        // Most projects use STRV Dependency Injection. Projects that don't can opt out with `traits: []`.
        .default(enabledTraits: ["DependencyInjection"]),
    ],
    dependencies: [
        // DeallocTests only uses AsyncContainer's init, clean(), releaseSharedInstances() and
        // resolve(type:), which DI 1.x and 2.x both have.
        .package(url: "https://github.com/strvcom/ios-dependency-injection.git", "1.0.4" ..< "3.0.0")
    ],
    targets: [
        // Shared by DeallocTests and the upcoming DeallocWatcher: no XCTest, no Swift Testing,
        // no classes or actors (it may be linked into both an app and its test bundle)
        .target(
            name: "DeallocTestsCore"
        ),
        .target(
            name: "DeallocTests",
            dependencies: [
                "DeallocTestsCore",
                .product(
                    name: "DependencyInjection",
                    package: "ios-dependency-injection",
                    condition: .when(traits: ["DependencyInjection"])
                )
            ]
        ),
        .testTarget(
            name: "DeallocTestsCoreTests",
            dependencies: ["DeallocTestsCore"]
        ),
        .testTarget(
            name: "DeallocTestsTests",
            dependencies: [
                "DeallocTests",
                .product(
                    name: "DependencyInjection",
                    package: "ios-dependency-injection",
                    condition: .when(traits: ["DependencyInjection"])
                )
            ]
        ),
    ],
    swiftLanguageModes: [.v6]
)
