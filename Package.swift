// swift-tools-version:5.7
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "swift-tts",
    platforms: [
        .iOS(.v15),
        .macOS(.v13),
    ],
    products: [
        .library(name: "SwiftTTS", targets: ["SwiftTTS"]),
        .library(name: "SwiftTTSCombine", targets: ["SwiftTTSCombine"]),
    ],
    dependencies: [],
    targets: [
        .target(name: "SwiftTTS", dependencies: []),
        .testTarget(name: "SwiftTTSTests", dependencies: ["SwiftTTS"]),
        .target(name: "SwiftTTSCombine", dependencies: []),
    ]
)
