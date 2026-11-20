// swift-tools-version:5.5
import PackageDescription

let package = Package(
    name: "AdnuntiusSDK",
    platforms: [.iOS(.v15), .macOS(.v10_15)],
    products: [.library(name: "AdnuntiusSDK", targets: ["AdnuntiusSDK"])],
    targets: [
        .target(
            name: "AdnuntiusSDK",
            path: "AdnuntiusSDK"
        )
    ]
)
