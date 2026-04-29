// swift-tools-version:5.9
import PackageDescription

let package = Package(
    name: "skylight-cli",
    platforms: [
        .macOS(.v12)
    ],
    products: [
        .executable(name: "skylight", targets: ["skylight"])
    ],
    targets: [
        .executableTarget(
            name: "skylight",
            path: "Sources/skylight",
            linkerSettings: [
                // SkyLight wird zur Laufzeit per dlopen geladen, der Pfad muss aber
                // dem Linker bekannt sein, falls man später statisch verlinken will.
                .unsafeFlags(["-F/System/Library/PrivateFrameworks"])
            ]
        )
    ]
)
