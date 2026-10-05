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
            description: "Integration with STRV Dependency Injection: the AsyncContainer in DeallocTester"
        ),
        .default(enabledTraits: ["DependencyInjection"]),
    ],
    dependencies: [
        .package(url: "https://github.com/strvcom/ios-dependency-injection.git", "1.0.4" ..< "3.0.0")
    ],
    targets: [
        .target(
            name: "DeallocTests",
            dependencies: [
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
