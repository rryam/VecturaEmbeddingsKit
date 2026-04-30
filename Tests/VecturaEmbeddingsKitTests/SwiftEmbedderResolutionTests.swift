import Foundation
import Testing
@testable import VecturaEmbeddingsKit
@testable import VecturaKit

@Suite("SwiftEmbedder Resolution")
struct SwiftEmbedderResolutionTests {
  @Test("Model source remains unchanged when cache directory is nil")
  func modelSourceUnchangedWithoutCacheDirectory() async throws {
    let source = VecturaModelSource.id("minishlab/potion-base-4M", type: .model2vec)
    let resolved = try await SwiftEmbedder.resolveModelSourceForLoading(
      source,
      configuration: .init(cacheDirectory: nil),
      downloader: { _, _ in
        Issue.record("Downloader should not be called when cache directory is nil")
        return URL(filePath: "/tmp/unused")
      }
    )
    #expect(resolved.description == source.description)
  }

  @Test("Folder source remains unchanged even when cache directory is set")
  func folderSourceUnchangedWithCacheDirectory() async throws {
    let folder = URL(filePath: "/tmp/fake-model")
    let source = VecturaModelSource.folder(folder, type: .model2vec)
    let resolved = try await SwiftEmbedder.resolveModelSourceForLoading(
      source,
      configuration: .init(cacheDirectory: URL(filePath: "/tmp/cache")),
      downloader: { _, _ in
        Issue.record("Downloader should not be called for folder model sources")
        return URL(filePath: "/tmp/unused")
      }
    )
    #expect(resolved.description == source.description)
  }

  @Test("ID source resolves to downloaded folder when cache directory is set")
  func idSourceResolvesToDownloadedFolderWithCacheDirectory() async throws {
    let cacheDirectory = URL(filePath: "/tmp/vectura-cache")
    let downloadedFolder = URL(filePath: "/tmp/vectura-cache/models--minishlab--potion-base-4M")
    let source = VecturaModelSource.id("minishlab/potion-base-4M", type: .model2vec)

    let resolved = try await SwiftEmbedder.resolveModelSourceForLoading(
      source,
      configuration: .init(cacheDirectory: cacheDirectory),
      downloader: { modelId, cacheDirectory in
        #expect(modelId == "minishlab/potion-base-4M")
        #expect(cacheDirectory == URL(filePath: "/tmp/vectura-cache"))
        return downloadedFolder
      }
    )

    switch resolved {
    case .folder(let url, let type):
      #expect(url == downloadedFolder)
      #expect(type == .model2vec)
    case .id:
      Issue.record("Expected downloaded ID source to resolve to a folder source")
    }
  }

  @Test("Cached ID source preserves inferred model type")
  func cachedIDSourcePreservesInferredModelType() async throws {
    let cacheDirectory = URL(filePath: "/tmp/vectura-cache")
    let downloadedFolder = cacheDirectory
      .appending(path: "models--minishlab--potion-base-4M")
      .appending(path: "snapshots")
      .appending(path: "abcdef1234567890")
    let source = VecturaModelSource.id("minishlab/potion-base-4M")

    let resolved = try await SwiftEmbedder.resolveModelSourceForLoading(
      source,
      configuration: .init(cacheDirectory: cacheDirectory),
      downloader: { _, _ in downloadedFolder }
    )

    #expect(SwiftEmbedder.resolveModelFamily(for: resolved) == .model2vec)
  }

  @Test("Explicit model type overrides heuristics")
  func explicitModelTypeOverridesHeuristics() {
    let source = VecturaModelSource.id("minishlab/potion-base-4M", type: .bert)
    let family = SwiftEmbedder.resolveModelFamily(for: source)
    #expect(family == .bert)
  }

  @Test("Model2Vec family inferred from known ids")
  func inferModel2VecFamily() {
    let source = VecturaModelSource.id("minishlab/potion-base-4M")
    let family = SwiftEmbedder.resolveModelFamily(for: source)
    #expect(family == .model2vec)
  }

  @Test("StaticEmbeddings family inferred from known ids")
  func inferStaticEmbeddingsFamily() {
    let source = VecturaModelSource.id("sentence-transformers/static-retrieval-mrl-en-v1")
    let family = SwiftEmbedder.resolveModelFamily(for: source)
    #expect(family == .staticEmbeddings)
  }

  @Test("NomicBert family inferred from known ids")
  func inferNomicBertFamily() {
    let source = VecturaModelSource.id("nomic-ai/nomic-embed-text-v1.5")
    let family = SwiftEmbedder.resolveModelFamily(for: source)
    #expect(family == .nomicBert)
  }

  @Test("ModernBert family inferred from known ids")
  func inferModernBertFamily() {
    let source = VecturaModelSource.id("nomic-ai/modernbert-embed-base")
    let family = SwiftEmbedder.resolveModelFamily(for: source)
    #expect(family == .modernBert)
  }

  @Test("Explicit ModernBert type overrides heuristics")
  func explicitModernBertTypeOverridesHeuristics() {
    let source = VecturaModelSource.id("sentence-transformers/all-MiniLM-L6-v2", type: .modernBert)
    let family = SwiftEmbedder.resolveModelFamily(for: source)
    #expect(family == .modernBert)
  }

  @Test("RoBERTa family inferred from known ids")
  func inferRobertaFamily() {
    let source = VecturaModelSource.id("FacebookAI/roberta-base")
    let family = SwiftEmbedder.resolveModelFamily(for: source)
    #expect(family == .roberta)
  }

  @Test("XLM-RoBERTa family inferred from known ids")
  func inferXlmRobertaFamily() {
    let source = VecturaModelSource.id("FacebookAI/xlm-roberta-base")
    let family = SwiftEmbedder.resolveModelFamily(for: source)
    #expect(family == .xlmRoberta)
  }

  @Test("XLM-RoBERTa family inferred from multilingual e5 ids")
  func inferXlmRobertaFamilyFromE5() {
    let source = VecturaModelSource.id("intfloat/multilingual-e5-small")
    let family = SwiftEmbedder.resolveModelFamily(for: source)
    #expect(family == .xlmRoberta)
  }

  @Test("Explicit XLM-RoBERTa type overrides heuristics")
  func explicitXlmRobertaTypeOverridesHeuristics() {
    let source = VecturaModelSource.id("FacebookAI/roberta-base", type: .xlmRoberta)
    let family = SwiftEmbedder.resolveModelFamily(for: source)
    #expect(family == .xlmRoberta)
  }

  @Test("Folder inference uses only the model directory name")
  func folderInferenceUsesModelDirectoryName() {
    let source = VecturaModelSource.folder(URL(filePath: "/Users/roberta/models/bert-model"))
    let family = SwiftEmbedder.resolveModelFamily(for: source)
    #expect(family == .bert)
  }

  @Test("Folder inference still detects family from model directory")
  func folderInferenceDetectsModelDirectory() {
    let source = VecturaModelSource.folder(URL(filePath: "/tmp/models/FacebookAI/roberta-base"))
    let family = SwiftEmbedder.resolveModelFamily(for: source)
    #expect(family == .roberta)
  }

  @Test("Unknown models default to BERT family")
  func unknownModelDefaultsToBertFamily() {
    let source = VecturaModelSource.id("sentence-transformers/all-MiniLM-L6-v2")
    let family = SwiftEmbedder.resolveModelFamily(for: source)
    #expect(family == .bert)
  }

  @Test("Static dimension uses base when truncate not set")
  func staticDimensionNoTruncate() throws {
    let resolved = try SwiftEmbedder.resolvedStaticEmbeddingDimension(
      baseDimension: 768,
      truncateDimension: nil
    )
    #expect(resolved == 768)
  }

  @Test("Static dimension is truncated when requested")
  func staticDimensionTruncated() throws {
    let resolved = try SwiftEmbedder.resolvedStaticEmbeddingDimension(
      baseDimension: 768,
      truncateDimension: 256
    )
    #expect(resolved == 256)
  }

  @Test("Static dimension caps truncate at base dimension")
  func staticDimensionCappedAtBase() throws {
    let resolved = try SwiftEmbedder.resolvedStaticEmbeddingDimension(
      baseDimension: 384,
      truncateDimension: 768
    )
    #expect(resolved == 384)
  }

  @Test("Static dimension rejects non-positive truncation")
  func staticDimensionRejectsInvalidTruncation() {
    #expect(throws: VecturaError.self) {
      _ = try SwiftEmbedder.resolvedStaticEmbeddingDimension(
        baseDimension: 384,
        truncateDimension: 0
      )
    }
  }
}
