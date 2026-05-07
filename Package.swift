// swift-tools-version:5.9
import PackageDescription

let package = Package(
  name: "RRuleSwift",
  platforms: [.iOS(.v15)],
  products: [
    .library(name: "RRuleSwift", targets: ["RRuleSwift"]),
  ],
  targets: [
    .target(
      name: "RRuleSwift",
      path: "Sources",
      exclude: ["Supporting Files"],
      resources: [
        .copy("lib"),
      ]
    ),
  ]
)
