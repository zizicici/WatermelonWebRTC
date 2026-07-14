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
            url: "https://github.com/zizicici/WatermelonWebRTC/releases/download/144.7559.2-watermelon.1/WebRTC-144.7559.2-watermelon.1.xcframework.zip",
            checksum: "ed55a50ce98c2f59f726a6d1e54bea075e7ecdabee8b7bc93910969ec603fa14"
        ),
    ]
)

