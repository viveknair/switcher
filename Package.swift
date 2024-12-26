// swift-tools-version: 5.7

import PackageDescription

let package = Package(
    name: "switcher",
    defaultLocalization: "en",
    platforms: [
        .macOS(.v13)
    ],
    dependencies: [
        .package(url: "https://github.com/soffes/HotKey", exact: "0.1.3"),
        .package(url: "https://github.com/sindresorhus/Settings", exact: "3.1.1"),
        .package(url: "https://github.com/jamesrochabrun/SwiftOpenAI.git", from: "3.9.3")
    ],
    targets: [
        .executableTarget(
            name: "switcher",
            dependencies: [
                "HotKey",
                "Settings",
                .product(name: "SwiftOpenAI", package: "SwiftOpenAI")
            ],
            path: "switcher"
        )
    ]
)
