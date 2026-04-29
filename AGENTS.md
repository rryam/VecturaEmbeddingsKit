# Repository Guidelines

## Project Structure & Module Organization

VecturaEmbeddingsKit is a Swift package that provides `SwiftEmbedder`, `VecturaModelSource`, and model-family resolution for VecturaKit's `VecturaEmbedder` protocol. Source files live in `Sources/VecturaEmbeddingsKit`, and Swift Testing suites live in `Tests/VecturaEmbeddingsKitTests`.

## Build, Test, and Development Commands

- `swift build` compiles the library in debug mode.
- `swift test` runs the Swift Testing suites.
- `swift build -c release` validates release compilation through the full `swift-embeddings` dependency graph.
- `swift test -c release` runs the tests against release builds.
- `swift package edit VecturaKit --path ../VecturaKit` tests this package against a local VecturaKit checkout; run `swift package unedit VecturaKit --force` afterward.

## Coding Style & Naming Conventions

Follow Swift 6 defaults with two-space indentation and a 120-character soft wrap. Keep public types UpperCamelCase and members lowerCamelCase. Public APIs should include concise `///` documentation, especially when they expose model-loading behavior or configuration.

## Testing Guidelines

Use Swift Testing with `@Suite` and `@Test`. Prefer fast tests that exercise model-family resolution, configuration validation, and protocol conformance without downloading large model artifacts. Add opt-in integration tests for real model downloads only when they can be skipped by default.

## Commit & Pull Request Guidelines

Commits should be imperative and scoped, such as `Port SwiftEmbedder integration` or `Document model source usage`. Pull requests should summarize API changes, dependency impact, and verification commands. Keep changes coordinated with VecturaKit when the shared `VecturaEmbedder` contract changes.
