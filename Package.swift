// swift-tools-version:5.0

import PackageDescription

let package = Package(
    name: "DeallocTests",
    platforms: [
        .iOS(.v8)
    ],
    products: [
        .library(name: "DeallocTests", targets: ["DeallocTests"]),
    ],
    dependencies: [
        .package(url: "https://github.com/Swinject/Swinject.git", from: "2.7.1"),
    ],
    targets: {
        var targets: [Target] = [
            .testTarget(
                name: "DeallocTestsTests",
                dependencies: [],
                path: "Tests"
            ),
        ]
// #if os(macOS)
//        targets.append(contentsOf: [
//            .target(name: "QuickSpecBase", dependencies: []),
//            .target(name: "Quick", dependencies: [ "QuickSpecBase" ]),
//        ])
// #else
        targets.append(contentsOf: [
            .target(name: "DeallocTests", dependencies: [], path: "Sources"),
        ])
//#endif
        return targets
    }(),
    swiftLanguageVersions: [.v5]
)
