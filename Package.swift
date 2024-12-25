// swift-tools-version: 5.7

import PackageDescription

let package = Package(
    name: "switcher",
    defaultLocalization: "en",
    platforms: [.macOS(.v12)],
    products: [
        .executable(name: "switcher", targets: ["switcher"])
    ],
    dependencies: [
        .package(url: "https://github.com/soffes/HotKey", exact: "0.1.3")
    ],
    targets: [
        .executableTarget(
            name: "switcher",
            dependencies: ["HotKey"],
            path: "switcher",
            swiftSettings: [.unsafeFlags(["-suppress-warnings"])]
        )
    ]
)