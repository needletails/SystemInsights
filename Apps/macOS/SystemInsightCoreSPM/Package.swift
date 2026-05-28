// swift-tools-version: 6.0
// macOS Xcode wrapper — remote NeedleTailLogger; sources symlinked from ../../../Sources/SystemInsightCore.
import PackageDescription

let package = Package(
    name: "SystemInsightCoreSPM",
    platforms: [
        .macOS(.v14)
    ],
    products: [
        .library(name: "SystemInsightCore", targets: ["SystemInsightCore"])
    ],
    dependencies: [
        .package(url: "https://github.com/needletails/needletail-logger.git", from: "3.1.4")
    ],
    targets: [
        .target(
            name: "SystemInsightCore",
            dependencies: [
                .product(name: "NeedleTailLogger", package: "needletail-logger")
            ],
            path: "Sources/SystemInsightCore"
        )
    ],
    swiftLanguageModes: [.v6]
)
