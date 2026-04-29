# VecturaEmbeddingsKit

`VecturaEmbeddingsKit` is the planned `swift-embeddings` integration package for [VecturaKit](https://github.com/rryam/VecturaKit).

The package exists so `VecturaKit` can stay focused on storage, indexing, hybrid search, and the shared `VecturaEmbedder` protocol while local embedding backends evolve independently.

## Planned Scope

- Move `SwiftEmbedder` out of `VecturaKit`.
- Move `VecturaModelSource` and model-family resolution into this package.
- Keep `swift-embeddings` dependency management here.
- Provide a drop-in `VecturaEmbedder` implementation for Model2Vec, StaticEmbeddings, NomicBERT, ModernBERT, RoBERTa, XLM-RoBERTa, and BERT models.

## Relationship To VecturaKit

`VecturaEmbeddingsKit` depends on `VecturaKit` for the core database and embedding protocol:

```swift
import VecturaKit
import VecturaEmbeddingsKit

let embedder = SwiftEmbedder(modelSource: .default)
let database = try await VecturaKit(config: config, embedder: embedder)
```

The `SwiftEmbedder` migration has not landed in this repository yet.

## License

MIT License. See [LICENSE](LICENSE).
