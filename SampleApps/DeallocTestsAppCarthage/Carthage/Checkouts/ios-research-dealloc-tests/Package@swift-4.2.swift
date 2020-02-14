// swift-tools-version:4.2
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
    products: [
        .library(
            name: "DeallocTests",
            targets: ["DeallocTests"]
        ),
    ],
    dependencies: [
        // Dependencies declare other packages that this package depends on.
        // .package(url: /* package url */, from: "1.0.0"),
    ],
    targets: [
        .target(
            name: "DeallocTests",
            dependencies: [],
            path: "Sources"
        ),
        .testTarget(
            name: "DeallocTestsTests",
            dependencies: ["DeallocTests"],
            path: "Tests"
        ),
    ],
    swiftLanguageVersions: [.v4, .v4_2]
)