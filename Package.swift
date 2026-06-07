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
    targets: [
        .executableTarget(
            name: "Ninji",
            dependencies: [],
            path: "Sources/Ninji",
            resources: [
                .process("TrackObserver.js")
            ]
        )
    ]
)
