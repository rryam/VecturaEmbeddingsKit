import Foundation
import Testing
@testable import VecturaEmbeddingsKit
@testable import VecturaKit

@Suite("SwiftEmbedder Integration")
struct SwiftEmbedderIntegrationTests {
  @Test("Downloads model into custom cache directory")
  func downloadsModelIntoCustomCacheDirectory() async throws {
    guard ProcessInfo.processInfo.environment["VECTURA_RUN_EMBEDDINGS_INTEGRATION_TESTS"] == "1" else {
      return
    }

    let tempRoot = URL(filePath: NSTemporaryDirectory())
      .appendingPathComponent("SwiftEmbedderCache-\(UUID().uuidString)", isDirectory: true)
    try FileManager.default.createDirectory(
      at: tempRoot,
      withIntermediateDirectories: true
    )
    defer { try? FileManager.default.removeItem(at: tempRoot) }

    let directory = URL(filePath: NSTemporaryDirectory())
      .appendingPathComponent("SwiftEmbedderIntegration-\(UUID().uuidString)", isDirectory: true)
    try FileManager.default.createDirectory(
      at: directory,
      withIntermediateDirectories: true
    )
    defer { try? FileManager.default.removeItem(at: directory) }

    let config = try VecturaConfig(name: "integration-db", directoryURL: directory)
    let vectura = try await VecturaKit(
      config: config,
      embedder: SwiftEmbedder(
        modelSource: .default,
        configuration: .init(cacheDirectory: tempRoot)
      )
    )

    let documents = [
      "The quick brown fox jumps over the lazy dog",
      "Pack my box with five dozen liquor jugs",
      "How vexingly quick daft zebras jump",
    ]

    let ids = try await vectura.addDocuments(texts: documents)
    #expect(ids.count == 3)

    let results = try await vectura.search(query: "quick jumping animals")
    #expect(results.count >= 2)

    let downloadedModelRoot = VecturaModelSource.defaultModelId
      .split(separator: "/")
      .reduce(tempRoot.appending(path: "models")) { partialResult, pathComponent in
        partialResult.appending(path: String(pathComponent))
      }
    #expect(
      FileManager.default.fileExists(atPath: downloadedModelRoot.path(percentEncoded: false)),
      "Expected downloaded model cache under \(downloadedModelRoot.path())"
    )
  }
}
