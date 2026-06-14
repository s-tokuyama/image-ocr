// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "image-ocr",
    platforms: [
        .macOS(.v13)
    ],
    products: [
        .executable(
            name: "image-ocr",
            targets: ["ImageOCR"]
        )
    ],
    targets: [
        .executableTarget(
            name: "ImageOCR",
            linkerSettings: [
                .linkedFramework("Vision"),
                .linkedFramework("AppKit")
            ]
        )
    ]
)
