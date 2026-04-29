# VecturaEmbeddingsKit

`VecturaEmbeddingsKit` provides the [`swift-embeddings`](https://github.com/jkrukowski/swift-embeddings) integration for [VecturaKit](https://github.com/rryam/VecturaKit).

Use this package when you want local, on-device embedding models such as Model2Vec, StaticEmbeddings, NomicBERT, ModernBERT, RoBERTa, XLM-RoBERTa, or BERT with VecturaKit's storage and hybrid search engine.

## Why This Package Exists

`VecturaKit` owns the shared vector database pieces:

- persistent document storage
- vector search and hybrid BM25 search
- memory strategies for full-memory and indexed search
- the `VecturaEmbedder` protocol

`VecturaEmbeddingsKit` owns the heavier local-model backend:

- `SwiftEmbedder`
- `VecturaModelSource`
- `swift-embeddings` dependency management
- model-family resolution for supported `swift-embeddings` model types

This keeps the core database package small while letting local embedding backends evolve independently.

## Installation

Add the package to your `Package.swift`:

```swift
dependencies: [
  .package(url: "https://github.com/rryam/VecturaEmbeddingsKit.git", from: "1.0.1"),
]
```

Then add the products to your target:

```swift
.target(
  name: "MyApp",
  dependencies: [
    .product(name: "VecturaKit", package: "VecturaKit"),
    .product(name: "VecturaEmbeddingsKit", package: "VecturaEmbeddingsKit"),
  ]
)
```

## Quick Start

```swift
import VecturaKit
import VecturaEmbeddingsKit

let config = try VecturaConfig(
  name: "documents",
  dimension: nil
)

let embedder = SwiftEmbedder(modelSource: .default)
let database = try await VecturaKit(config: config, embedder: embedder)

try await database.addDocuments(texts: [
  "Swift is a safe and expressive programming language.",
  "Vector databases make semantic search practical on-device.",
  "Embeddings map text into numerical vectors.",
])

let results = try await database.search(
  query: "semantic search with Swift",
  numResults: 3,
  threshold: 0.5
)

for result in results {
  print("\(result.score): \(result.text)")
}
```

## Model Sources

Use the default Model2Vec model:

```swift
let embedder = SwiftEmbedder(modelSource: .default)
```

Load a remote model by identifier:

```swift
let embedder = SwiftEmbedder(
  modelSource: .id("minishlab/potion-base-4M")
)
```

Load a local model folder:

```swift
let embedder = SwiftEmbedder(
  modelSource: .folder(modelDirectoryURL)
)
```

Pass an explicit model type when automatic inference is not enough:

```swift
let embedder = SwiftEmbedder(
  modelSource: .id(
    "sentence-transformers/all-MiniLM-L6-v2",
    type: .bert
  )
)
```

## Supported Model Families

`SwiftEmbedder` can resolve and load these `swift-embeddings` model families:

- BERT
- Model2Vec
- StaticEmbeddings
- NomicBERT
- ModernBERT
- RoBERTa
- XLM-RoBERTa

Automatic model-family detection uses known model identifier patterns. Prefer an explicit `VecturaModelSource.ModelType` when a model name is ambiguous.

## StaticEmbeddings Truncation

For StaticEmbeddings models, you can request a truncated output dimension:

```swift
let embedder = SwiftEmbedder(
  modelSource: .id(
    "sentence-transformers/static-retrieval-mrl-en-v1",
    type: .staticEmbeddings
  ),
  configuration: .init(staticEmbeddingsTruncateDimension: 256)
)
```

Values less than `1` are rejected with `VecturaError.invalidInput`. Values larger than the model dimension are capped at the model dimension.

## Migration From VecturaKit

Older `VecturaKit` versions shipped `SwiftEmbedder` directly from the core package:

```swift
import VecturaKit

let embedder = SwiftEmbedder(modelSource: .default)
```

After the split, add `VecturaEmbeddingsKit` and import both modules:

```swift
import VecturaKit
import VecturaEmbeddingsKit

let embedder = SwiftEmbedder(modelSource: .default)
```

The database APIs stay the same because `SwiftEmbedder` still conforms to `VecturaEmbedder`.

## Relationship To Other Backends

- Use `VecturaEmbeddingsKit` for local `swift-embeddings` models.
- Use [`VecturaMLXKit`](https://github.com/rryam/VecturaMLXKit) for MLX-backed local models.
- Use `VecturaOAIKit`, shipped with `VecturaKit`, for hosted or local OpenAI-compatible `/v1/embeddings` APIs.
- Use `VecturaNLKit`, shipped with `VecturaKit`, for Apple's NaturalLanguage embeddings with no external model dependency.

## Development

Build and test:

```bash
swift build
swift test
swift build -c release
swift test -c release
```

When testing this package alongside an unreleased local `VecturaKit` branch:

```bash
swift package edit VecturaKit --path ../VecturaKit
swift test
swift package unedit VecturaKit --force
```

## License

MIT License. See [LICENSE](LICENSE).
