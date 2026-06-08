// swift-tools-version: 6.0

import PackageDescription

let package = Package(
    name: "Barcade",
    platforms: [
        .macOS(.v14)
    ],
    products: [
        .executable(name: "Barcade", targets: ["Barcade"])
    ],
    targets: [
        .executableTarget(
            name: "Barcade",
            path: "Sources",
            swiftSettings: [
                .swiftLanguageMode(.v5)
            ]
        ),
        .testTarget(
            name: "BarcadeTests",
            dependencies: ["Barcade"],
            path: "Tests/BarcadeTests",
            swiftSettings: [
                .swiftLanguageMode(.v5)
            ]
        )
    ]
)
