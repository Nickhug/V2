// swift-tools-version:5.9
import PackageDescription

let package = Package(
    name: "V2",
    platforms: [
        .iOS(.v17),
        .macOS(.v14)
    ],
    products: [
        .library(
            name: "V2",
            targets: ["V2"]),
    ],
    dependencies: [
        .package(url: "https://github.com/supabase/supabase-swift.git", from: "2.3.1")
    ],
    targets: [
        .target(
            name: "V2",
            dependencies: [
                .product(name: "Supabase", package: "supabase-swift"),
                .product(name: "Auth", package: "supabase-swift"),
                .product(name: "Functions", package: "supabase-swift"),
                .product(name: "PostgREST", package: "supabase-swift"),
                .product(name: "Realtime", package: "supabase-swift"),
                .product(name: "Storage", package: "supabase-swift")
            ],
            swiftSettings: [
                .enableUpcomingFeature("BareSlashRegexLiterals"),
                .enableExperimentalFeature("StrictConcurrency")
            ]),
        .testTarget(
            name: "V2Tests",
            dependencies: ["V2"]),
    ]
) 