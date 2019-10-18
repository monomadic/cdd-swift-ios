// swift-tools-version:5.0
// The swift-tools-version declares the minimum version of Swift required to build this package.
// SPDX-License-Identifier: (Apache-2.0 OR MIT)

import PackageDescription

let package = Package(
    name: "CDDSwift",
	platforms: [
		.macOS(.v10_13)
	],
    products: [
        .executable(name: "cdd-swift", targets: ["CDDSwift"]),
    ],
    dependencies: [
        .package(url: "https://github.com/apple/swift-syntax.git", .exact("0.50000.0")),
        .package(url: "https://github.com/jpsim/Yams.git", from: "1.0.2"),
        .package(url: "https://github.com/kylef/PathKit.git", from: "0.9.0"),
        .package(url: "https://github.com/yonaskolb/JSONUtilities.git", from: "4.1.0"),
		.package(url: "https://github.com/onevcat/Rainbow", from: "3.0.0"),
		.package(url: "https://github.com/Nike-Inc/Willow.git", from: "5.0.0"),
		.package(url: "https://github.com/jakeheis/SwiftCLI", from: "5.0.0")
    ],
    targets: [
        .target(
            name: "CDDSwift",
            dependencies: ["SwiftSyntax", "Yams", "PathKit", "JSONUtilities", "Rainbow", "SwiftCLI", "Willow"]),
        .testTarget(
            name: "CDDSwiftTests",
            dependencies: ["CDDSwift"]
        ),
    ]
)
