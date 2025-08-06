// swift-tools-version:5.7
import PackageDescription

let package = Package(
    name: "EdvironSDK",
    platforms: [
        .iOS(.v12)
    ],
    products: [
        .library(
            name: "EdvironSDK",
            targets: ["EdvironSDK"]
        ),
    ],
    targets: [
        .target(
            name: "EdvironSDK",
            dependencies: [],
            path: "Sources/EdvironSDK",
            resources: []
        )
    ]
)
