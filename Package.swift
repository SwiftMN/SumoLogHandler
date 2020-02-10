// swift-tools-version:5.1
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
  name: "SumoLogHandler",
  platforms: [
    .iOS(.v12)
  ],
  products: [
    .library(
      name: "SumoLogHandler",
      targets: ["SumoLogHandler"]),
  ],
  dependencies: [
    .package(url: "https://github.com/apple/swift-log.git", from: "1.2.0"),
    .package(url: "https://github.com/1024jp/GzipSwift", from: "5.1.1"),
    .package(url: "https://github.com/SwiftMN/ThreadSafeCollections", from: "1.0.0")
  ],
  targets: [
    .target(
      name: "SumoLogHandler",
      dependencies: ["Logging", "Gzip", "ThreadSafeCollections"]),
    .testTarget(
      name: "SumoLogHandlerTests",
      dependencies: ["SumoLogHandler"]),
  ]
)
