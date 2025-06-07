// swift-tools-version:5.5
import PackageDescription

let package = Package(
    name: "HelpingHand",
    platforms: [
        .iOS(.v15)
    ],
    products: [
        .library(
            name: "HelpingHand",
            targets: ["HelpingHand"]),
    ],
    dependencies: [
        .package(url: "https://github.com/MacPaw/OpenAI.git", .upToNextMajor(from: "0.2.4")),
    ],
    targets: [
        .target(
            name: "HelpingHand",
            dependencies: [
                .product(name: "OpenAI", package: "OpenAI"),
            ]),
    ]
)
