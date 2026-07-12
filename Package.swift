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
            checksum: "b180926d9024b639fe2ff316893403fdf8a4538e9ee537243c706d46067ae2fc"
        ),
    ]
)

