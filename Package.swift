// swift-tools-version: 6.2
import PackageDescription

let package = Package(
    name: "OpenMeteoKit",
    platforms: [
        .watchOS(.v10),
        .iOS(.v17),
        // macOS only so `swift test` runs on CI; the views are made for Apple Watch and iPhone.
        .macOS(.v14),
    ],
    products: [
        .library(name: "OpenMeteoKit", targets: ["OpenMeteoKit"]),
        .library(name: "OpenMeteoUI", targets: ["OpenMeteoUI"]),
    ],
    targets: [
        .target(name: "OpenMeteoKit"),
        .target(name: "OpenMeteoUI", dependencies: ["OpenMeteoKit"]),
        .testTarget(
            name: "OpenMeteoKitTests",
            dependencies: ["OpenMeteoKit"],
            resources: [.copy("Fixtures")]
        ),
    ]
)
