import Testing
@testable import VecturaEmbeddingsKit

@Suite("VecturaEmbeddingsKit")
struct VecturaEmbeddingsKitTests {
  @Test("Exposes package namespace")
  func packageName() {
    #expect(VecturaEmbeddingsKit.name == "VecturaEmbeddingsKit")
  }
}
