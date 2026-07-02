import Foundation
import Testing
@testable import VecturaEmbeddingsKit
@testable import VecturaKit

@Suite("SwiftEmbedder Resolution")
struct SwiftEmbedderResolutionTests {
  @Test("ID source resolves through default cache directory when cache directory is nil")
  func idSourceResolvesThroughDefaultCacheDirectory() async throws {
    let source = VecturaModelSource.id("minishlab/potion-base-4M", type: .model2vec)
    let downloadedFolder = SwiftEmbedder.defaultModelCacheDirectory
      .appending(path: "models--minishlab--potion-base-4M")
      .appending(path: "snapshots")
      .appending(path: "abcdef1234567890")

    let resolved = try await SwiftEmbedder.resolveModelSourceForLoading(
      source,
      configuration: .init(cacheDirectory: nil),
      downloader: { modelId, requestedCacheDirectory in
        #expect(modelId == "minishlab/potion-base-4M")
        #expect(requestedCacheDirectory == SwiftEmbedder.defaultModelCacheDirectory)
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
    let cacheDirectory = URL(filePath: "/tmp/vectura-cache-\(UUID().uuidString)")
    let downloadedFolder = cacheDirectory.appending(path: "models--minishlab--potion-base-4M")
    let source = VecturaModelSource.id("minishlab/potion-base-4M", type: .model2vec)

    let resolved = try await SwiftEmbedder.resolveModelSourceForLoading(
      source,
      configuration: .init(cacheDirectory: cacheDirectory),
      downloader: { modelId, requestedCacheDirectory in
        #expect(modelId == "minishlab/potion-base-4M")
        #expect(requestedCacheDirectory == cacheDirectory)
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
    let cacheDirectory = URL(filePath: "/tmp/vectura-cache-\(UUID().uuidString)")
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

  @Test("Concurrent ID source resolutions share in-flight download")
  func concurrentIDSourceResolutionsShareInFlightDownload() async throws {
    let cacheDirectory = URL(filePath: "/tmp/vectura-cache-\(UUID().uuidString)")
    let downloadedFolder = cacheDirectory
      .appending(path: "models--minishlab--potion-base-4M")
      .appending(path: "snapshots")
      .appending(path: "abcdef1234567890")
    let source = VecturaModelSource.id("minishlab/potion-base-4M", type: .model2vec)
    let probe = DownloadProbe(downloadedFolder: downloadedFolder)

    let resolvedSources = try await withThrowingTaskGroup(of: VecturaModelSource.self) { group in
      for _ in 0..<8 {
        group.addTask {
          try await SwiftEmbedder.resolveModelSourceForLoading(
            source,
            configuration: .init(cacheDirectory: cacheDirectory),
            downloader: { modelId, cacheDirectory in
              try await probe.download(modelId: modelId, cacheDirectory: cacheDirectory)
            }
          )
        }
      }

      var resolvedSources: [VecturaModelSource] = []
      for try await resolvedSource in group {
        resolvedSources.append(resolvedSource)
      }
      return resolvedSources
    }

    let downloadCount = await probe.downloadCount
    #expect(downloadCount == 1)
    #expect(resolvedSources.count == 8)
    for resolvedSource in resolvedSources {
      switch resolvedSource {
      case .folder(let url, let type):
        #expect(url == downloadedFolder)
        #expect(type == .model2vec)
      case .id:
        Issue.record("Expected downloaded ID source to resolve to a folder source")
      }
    }
  }

  @Test("Concurrent default-cache ID source resolutions share in-flight download")
  func concurrentDefaultCacheIDSourceResolutionsShareInFlightDownload() async throws {
    let downloadedFolder = SwiftEmbedder.defaultModelCacheDirectory
      .appending(path: "models--minishlab--potion-base-4M")
      .appending(path: "snapshots")
      .appending(path: "abcdef1234567890")
    let source = VecturaModelSource.id("minishlab/potion-base-4M", type: .model2vec)
    let probe = DownloadProbe(downloadedFolder: downloadedFolder)

    let resolvedSources = try await withThrowingTaskGroup(of: VecturaModelSource.self) { group in
      for _ in 0..<8 {
        group.addTask {
          try await SwiftEmbedder.resolveModelSourceForLoading(
            source,
            configuration: .init(cacheDirectory: nil),
            downloader: { modelId, cacheDirectory in
              #expect(cacheDirectory == SwiftEmbedder.defaultModelCacheDirectory)
              return try await probe.download(modelId: modelId, cacheDirectory: cacheDirectory)
            }
          )
        }
      }

      var resolvedSources: [VecturaModelSource] = []
      for try await resolvedSource in group {
        resolvedSources.append(resolvedSource)
      }
      return resolvedSources
    }

    let downloadCount = await probe.downloadCount
    #expect(downloadCount == 1)
    #expect(resolvedSources.count == 8)
    for resolvedSource in resolvedSources {
      switch resolvedSource {
      case .folder(let url, let type):
        #expect(url == downloadedFolder)
        #expect(type == .model2vec)
      case .id:
        Issue.record("Expected downloaded ID source to resolve to a folder source")
      }
    }
  }

  @Test("Cancelled waiter does not clear in-flight download")
  func cancelledWaiterDoesNotClearInFlightDownload() async throws {
    let cacheDirectory = URL(filePath: "/tmp/vectura-cache-\(UUID().uuidString)")
    let downloadedFolder = cacheDirectory
      .appending(path: "models--minishlab--potion-base-4M")
      .appending(path: "snapshots")
      .appending(path: "abcdef1234567890")
    let source = VecturaModelSource.id("minishlab/potion-base-4M", type: .model2vec)
    let probe = ControlledDownloadProbe(downloadedFolder: downloadedFolder)

    let firstResolution = Task {
      try await SwiftEmbedder.resolveModelSourceForLoading(
        source,
        configuration: .init(cacheDirectory: cacheDirectory),
        downloader: { modelId, cacheDirectory in
          try await probe.download(modelId: modelId, cacheDirectory: cacheDirectory)
        }
      )
    }

    while await probe.downloadCount == 0 {
      try await Task.sleep(nanoseconds: 5_000_000)
    }

    firstResolution.cancel()
    try await Task.sleep(nanoseconds: 20_000_000)

    let secondResolution = Task {
      try await SwiftEmbedder.resolveModelSourceForLoading(
        source,
        configuration: .init(cacheDirectory: cacheDirectory),
        downloader: { modelId, cacheDirectory in
          try await probe.download(modelId: modelId, cacheDirectory: cacheDirectory)
        }
      )
    }

    try await Task.sleep(nanoseconds: 20_000_000)
    let downloadCount = await probe.downloadCount
    #expect(downloadCount == 1)

    await probe.release()
    let resolvedSource = try await secondResolution.value
    _ = try? await firstResolution.value

    switch resolvedSource {
    case .folder(let url, let type):
      #expect(url == downloadedFolder)
      #expect(type == .model2vec)
    case .id:
      Issue.record("Expected downloaded ID source to resolve to a folder source")
    }
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

private actor DownloadProbe {
  let downloadedFolder: URL
  private var calls = 0

  init(downloadedFolder: URL) {
    self.downloadedFolder = downloadedFolder
  }

  var downloadCount: Int {
    calls
  }

  func download(modelId: String, cacheDirectory: URL) async throws -> URL {
    #expect(modelId == "minishlab/potion-base-4M")
    calls += 1
    try await Task.sleep(nanoseconds: 50_000_000)
    return downloadedFolder
  }
}

private actor ControlledDownloadProbe {
  let downloadedFolder: URL
  private var calls = 0
  private var isReleased = false

  init(downloadedFolder: URL) {
    self.downloadedFolder = downloadedFolder
  }

  var downloadCount: Int {
    calls
  }

  func release() {
    isReleased = true
  }

  func download(modelId: String, cacheDirectory: URL) async throws -> URL {
    #expect(modelId == "minishlab/potion-base-4M")
    calls += 1
    while !isReleased {
      try await Task.sleep(nanoseconds: 5_000_000)
    }
    return downloadedFolder
  }
}
