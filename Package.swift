// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "Speakwerk",
    platforms: [
        .macOS(.v14)
    ],
    products: [
        .executable(name: "Speakwerk", targets: ["Speakwerk"])
    ],
    dependencies: [
        .package(url: "https://github.com/argmaxinc/argmax-oss-swift.git", from: "1.0.0"),
        .package(url: "https://github.com/sparkle-project/Sparkle.git", from: "2.0.0")
    ],
    targets: [
        .executableTarget(
            name: "Speakwerk",
            dependencies: [
                .product(name: "WhisperKit", package: "argmax-oss-swift"),
                .product(name: "Sparkle", package: "Sparkle")
            ],
            path: "Sources/Speakwerk"
        ),
        .testTarget(
            name: "SpeakwerkTests",
            dependencies: ["Speakwerk"],
            path: "Tests"
        )
    ]
)
