// swift-tools-version:5.7
import PackageDescription

let package = Package(
    name: "HelpingHand",
    platforms: [
        .iOS(.v15)
    ],
    dependencies: [
        .package(url: "https://github.com/MacPaw/OpenAI.git", from: "0.2.4")
    ],
    targets: [
        .target(
            name: "HelpingHand",
            dependencies: ["OpenAI"]
        )
    ]
)
