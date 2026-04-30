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
    .executable(
      name: "vectura-embeddings-cli",
      targets: ["VecturaEmbeddingsCLI"]
    ),
  ],
  dependencies: [
    .package(url: "https://github.com/rryam/VecturaKit.git", from: "6.0.0"),
    .package(url: "https://github.com/jkrukowski/swift-embeddings.git", from: "0.0.26"),
    .package(url: "https://github.com/apple/swift-argument-parser.git", from: "1.4.0"),
    .package(url: "https://github.com/huggingface/swift-transformers.git", from: "1.1.2"),
  ],
  targets: [
    .target(
      name: "VecturaEmbeddingsKit",
      dependencies: [
        .product(name: "VecturaKit", package: "VecturaKit"),
        .product(name: "Embeddings", package: "swift-embeddings"),
        .product(name: "Hub", package: "swift-transformers"),
      ]
    ),
    .executableTarget(
      name: "VecturaEmbeddingsCLI",
      dependencies: [
        .product(name: "VecturaKit", package: "VecturaKit"),
        "VecturaEmbeddingsKit",
        .product(name: "ArgumentParser", package: "swift-argument-parser"),
      ],
      resources: [
        .copy("Resources/mock_documents.json")
      ]
    ),
    .executableTarget(
      name: "TestEmbeddingsExamples",
      dependencies: [
        .product(name: "VecturaKit", package: "VecturaKit"),
        "VecturaEmbeddingsKit",
      ]
    ),
    .testTarget(
      name: "VecturaEmbeddingsKitTests",
      dependencies: [
        "VecturaEmbeddingsKit",
        .product(name: "VecturaKit", package: "VecturaKit"),
      ]
    ),
  ],
  swiftLanguageModes: [.v6]
)
