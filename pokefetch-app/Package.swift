// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "PokefetchApp",
    platforms: [.macOS(.v13)],
    dependencies: [
        .package(path: "../../LiquidTerminal/Vendor/SwiftTerm"),
    ],
    targets: [
        .executableTarget(
            name: "PokefetchApp",
            dependencies: [
                .product(name: "SwiftTerm", package: "SwiftTerm")
            ]
        )
    ]
)
