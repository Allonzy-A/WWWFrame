// swift-tools-version: 5.7
import PackageDescription

let package = Package(
    name: "WWWFrame",
    platforms: [
        .iOS(.v15)
    ],
    products: [
        .library(
            name: "WWWFrame",
            targets: ["WWWFrame"]),
    ],
    dependencies: [],
    targets: [
        .target(
            name: "WWWFrame",
            dependencies: []),
        .testTarget(
            name: "WWWFrameTests",
            dependencies: ["WWWFrame"]),
    ]
) 