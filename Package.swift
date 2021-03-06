// swift-tools-version:5.0
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
        .iOS(.v10),
    ],
    products: [
        .library(
            name: "DeallocTests",
            targets: ["DeallocTests"]
        ),
        .library(
            name: "DeallocTestsSwinjectFree",
            targets: ["DeallocTestsSwinjectFree"]
        ),
    ],
    dependencies: [
        // Dependencies declare other packages that this package depends on.
        .package(url: "https://github.com/Swinject/Swinject.git", from: "2.7.0"),
    ],
    targets: [
        .target(
            name: "DeallocTests",
            dependencies: ["Swinject"],
            path: "Sources/DeallocTests"
        ),
        .target(
            name: "DeallocTestsSwinjectFree",
            path: "Sources/DeallocTestsSwinjectFree"
        ),
        .testTarget(
            name: "DeallocTestsTests",
            dependencies: ["DeallocTests"],
            path: "Tests"
        ),
    ],
    swiftLanguageVersions: [.v5]
)
