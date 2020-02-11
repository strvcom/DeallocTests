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
        .iOS(.v8),
        .macOS(.v10_10),
        .tvOS(.v9),
        .watchOS(.v2),
    ],
    products: [
        .library(
            name: "DeallocTests",
            targets: ["DeallocTests-iOS"]
        ),
    ],
    dependencies: [
        .package(url: "https://github.com/Swinject/Swinject.git", from: "2.7.1"),
    ],
    targets: [
        .target(
            name: "DeallocTests-iOS",
            dependencies: [],
            path: "Sources"
        ),
        .testTarget(
            name: "DeallocTestsTests-iOS",
            dependencies: ["DeallocTests-iOS"],
            path: "Tests"
        ),
    ],
    swiftLanguageVersions: [.v5]
)
