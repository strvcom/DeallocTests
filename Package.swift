// swift-tools-version:5.9
//
//  DeallocTests.swift
//  DeallocTests
//
//  Created by Daniel Cech on 01/04/19.
//  Copyright © 2019 DanielCech. All rights reserved.
//

import PackageDescription

let package = Package(
    name: "DeallocTests",
    platforms: [
        .iOS(.v17)
    ],
    products: [
        .library(
            name: "DeallocTests",
            targets: ["DeallocTests"]
        ),
        .library(
            name: "DeallocTestsDIFree",
            targets: ["DeallocTestsDIFree"]
        ),
    ],
    dependencies: [
        // Dependencies declare other packages that this package depends on.
        .package(url: "git@github.com:strvcom/ios-dependency-injection.git", branch: "feat/rob-async-init"),
    ],
    targets: [
        .target(
            name: "DeallocTests",
            dependencies: [.product(name: "DependencyInjection", package: "ios-dependency-injection")],
            path: "Sources/DeallocTests"
        ),
        .target(
            name: "DeallocTestsDIFree",
            path: "Sources/DeallocTestsDIFree"
        ),
        .testTarget(
            name: "DeallocTestsTests",
            dependencies: ["DeallocTests"],
            path: "Tests"
        ),
    ],
    swiftLanguageVersions: [.v5]
)
