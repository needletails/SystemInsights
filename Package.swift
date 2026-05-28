// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "SystemInsights",
    platforms: [
        .macOS(.v13)
    ],
    products: [
        .library(name: "SystemInsightCore", targets: ["SystemInsightCore"]),
        .executable(name: "system-insights", targets: ["SystemInsightsCLI"])
    ],
    dependencies: [
        .package(url: "https://github.com/apple/swift-crypto.git", from: "3.10.0"),
        .package(url: "https://github.com/needletails/needletail-logger.git", from: "3.1.4")
    ],
    targets: [
        .target(
            name: "SystemInsightCore",
            dependencies: [
                .product(
                    name: "Crypto",
                    package: "swift-crypto",
                    condition: .when(platforms: [.linux])
                ),
                .product(name: "NeedleTailLogger", package: "needletail-logger")
            ]
        ),
        .executableTarget(
            name: "SystemInsightsCLI",
            dependencies: ["SystemInsightCore"]
        ),
        .testTarget(
            name: "SystemInsightCoreTests",
            dependencies: ["SystemInsightCore"]
        )
    ],
    swiftLanguageModes: [.v6]
)
