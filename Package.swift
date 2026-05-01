// swift-tools-version:5.9
import PackageDescription

let package = Package(
    name: "skylight-cli",
    platforms: [
        .macOS(.v12)
    ],
    products: [
        .executable(name: "skylight", targets: ["skylight"]),
    ],
    targets: [
        .executableTarget(
            name: "skylight",
            path: "Sources/skylight",
            linkerSettings: [
                .unsafeFlags(["-F/System/Library/PrivateFrameworks"])
            ]
        ),
        .testTarget(
            name: "SkylightCliTests",
            dependencies: ["skylight"],
            path: "Tests/SkylightCliTests"
        ),
    ]
)
