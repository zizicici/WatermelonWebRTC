// swift-tools-version: 5.9

import PackageDescription

let package = Package(
    name: "WatermelonWebRTC",
    platforms: [.iOS(.v14)],
    products: [
        .library(name: "WebRTC", targets: ["WebRTC"]),
    ],
    targets: [
        .binaryTarget(
            name: "WebRTC",
            url: "https://github.com/zizicici/WatermelonWebRTC/releases/download/144.7559.1/WebRTC-144.7559.1.xcframework.zip",
            checksum: "e87460923a392ff295a51c5b90b5111c5c277c398112239723c9709be0401b2a"
        ),
    ]
)

