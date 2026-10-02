// swift-tools-version:6.0.0
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
        .iOS(.v17),
        .macOS(.v13)
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
        .package(url: "https://github.com/strvcom/ios-dependency-injection.git", .upToNextMajor(from: "2.0.0"))
    ],
    targets: [
        .target(
            name: "DeallocTests",
            dependencies: [.product(name: "DependencyInjection", package: "ios-dependency-injection")],
            path: "Sources/DeallocTests",
            swiftSettings: [.define("DEALLOC_TESTS_DI")]
        ),
        .target(
            name: "DeallocTestsDIFree",
            path: "Sources/DeallocTestsDIFree"
        ),
        .testTarget(
            name: "DeallocTestsTests",
            dependencies: ["DeallocTests"],
            path: "Tests/DeallocTestsTests"
        ),
        .testTarget(
            name: "DeallocTestsDIFreeTests",
            dependencies: ["DeallocTestsDIFree"],
            path: "Tests/DeallocTestsDIFreeTests"
        ),
    ],
    swiftLanguageModes: [.v6]
)
