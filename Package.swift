// swift-tools-version: 6.1
import PackageDescription

let package = Package(
    name: "INDICLIKit",
    platforms: [
        .macOS(.v14)
    ],
    products: [
        .executable(name: "indi-cli", targets: ["indi-cli"])
    ],
    dependencies: [
        .package(url: "https://github.com/apple/swift-argument-parser.git", from: "1.5.0"),
        .package(path: "../INDIMCPKit"),
    ],
    targets: [
        .executableTarget(
            name: "indi-cli",
            dependencies: [
                .product(name: "ArgumentParser", package: "swift-argument-parser"),
                .product(name: "INDIMCPKit", package: "INDIMCPKit"),
            ]
        )
    ]
)
