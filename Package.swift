// swift-tools-version:5.1
import PackageDescription

let package = Package(
    name: "AdnuntiusSDK",
    platforms: [.iOS(.v9), .macOS(.v10_15)],
    products: [.library(name: "AdnuntiusSDK", targets: ["AdnuntiusSDK"])],
    targets: [
        .target(
            name: "AdnuntiusSDK",
            path: "AdnuntiusSDK"
        )
    ]
)
