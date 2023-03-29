// swift-tools-version:5.7
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "swift-tts",
    platforms: [.iOS(.v15), .macOS(.v13)],
    products: [
        .library(name: "SwiftTTS", targets: ["SwiftTTS"]),
        .library(name: "SwiftTTSDependency", targets: ["SwiftTTSDependency"]),
        .library(name: "SwiftTTSCombine", targets: ["SwiftTTSCombine"]),
    ],
    dependencies: [
        .package(url: "https://github.com/pointfreeco/swift-dependencies", from: "0.2.0"),
    ],
    targets: [
        .target(name: "SwiftTTS", dependencies: []),
        .testTarget(name: "SwiftTTSTests", dependencies: ["SwiftTTS"]),
        .target(
            name: "SwiftTTSDependency",
            dependencies: [
                .product(name: "Dependencies", package: "swift-dependencies"),
                "SwiftTTS",
            ]
        ),
        .target(name: "SwiftTTSCombine", dependencies: []),
    ]
)
