// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "DesktopBuddies",
    platforms: [
        .macOS(.v13)
    ],
    products: [
        .executable(name: "DesktopBuddies", targets: ["DesktopBuddies"])
    ],
    targets: [
        .executableTarget(
            name: "DesktopBuddies",
            path: "Sources/DesktopBuddies"
        )
    ]
)
