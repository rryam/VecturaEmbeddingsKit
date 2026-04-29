// swift-tools-version: 6.0
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
  name: "VecturaEmbeddingsKit",
  platforms: [
    .macOS(.v15),
    .iOS(.v18),
    .tvOS(.v18),
    .visionOS(.v2),
    .watchOS(.v11),
  ],
  products: [
    .library(
      name: "VecturaEmbeddingsKit",
      targets: ["VecturaEmbeddingsKit"]
    ),
  ],
  dependencies: [
    .package(url: "https://github.com/rryam/VecturaKit.git", from: "6.0.0"),
    .package(url: "https://github.com/jkrukowski/swift-embeddings.git", from: "0.0.26"),
  ],
  targets: [
    .target(
      name: "VecturaEmbeddingsKit",
      dependencies: [
        .product(name: "VecturaKit", package: "VecturaKit"),
        .product(name: "Embeddings", package: "swift-embeddings"),
      ]
    ),
    .testTarget(
      name: "VecturaEmbeddingsKitTests",
      dependencies: ["VecturaEmbeddingsKit"]
    ),
  ],
  swiftLanguageModes: [.v6]
)
