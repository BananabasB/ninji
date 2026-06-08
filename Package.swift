// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "Ninji",
    platforms: [
        .macOS(.v12)
    ],
    products: [
        .executable(name: "Ninji", targets: ["Ninji"])
    ],
    dependencies: [
        .package(url: "https://github.com/sparkle-project/Sparkle.git", from: "2.5.0")
    ],
    targets: [
        .executableTarget(
            name: "Ninji",
            dependencies: [
                .product(name: "Sparkle", package: "Sparkle")
            ],
            path: "Sources/Ninji",
            resources: [
                .process("TrackObserver.js")
            ]
        )
    ]
)
