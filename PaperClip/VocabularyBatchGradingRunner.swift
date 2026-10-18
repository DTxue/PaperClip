import Foundation
import PencilKit
import UIKit
import Vision

struct VocabularyHandwritingGradingCard: Sendable {
    let term: String
    let definition: String
    let englishDefinition: String
}

struct VocabularyBatchGradingRequest {
    let batchIndex: Int
    let batchID: Int
    let context: VocabularyTestGradingTaskContext
    let kind: VocabularyHandwritingTestKind
    let isChinese: Bool
    let usesChineseCharacterByCharacterRecognition: Bool
    let usesLocalChineseRecognition: Bool
    let canvasSize: CGSize
    let cards: [VocabularyHandwritingGradingCard]
    let drawings: [PKDrawing]
}

struct VocabularyBatchGradingCallbacks {
    let isCurrent: @MainActor @Sendable (VocabularyTestGradingTaskContext, Int, Int) -> Bool
    let finishSuccess: @MainActor @Sendable (Int, [UIImage?], VocabularyGradingResult, VocabularyTestGradingTaskContext) -> Void
    let finishFailure: @MainActor @Sendable (Int, [UIImage?], String, VocabularyTestGradingTaskContext) -> Void
    let clearTask: @MainActor @Sendable (Int, UUID) -> Void
}

enum VocabularyBatchGradingRunner {
    static func makeTask(
        request: VocabularyBatchGradingRequest,
        callbacks: VocabularyBatchGradingCallbacks
    ) -> Task<Void, Never> {
        Task {
            @MainActor
            func isCurrentBatch() -> Bool {
                callbacks.isCurrent(request.context, request.batchID, request.batchIndex)
            }

            let images = await VocabularyHandwritingImageRenderer.render(request.drawings)
            guard !Task.isCancelled else {
                await callbacks.clearTask(request.batchID, request.context.taskID)
                return
            }
            let hasVisibleAnswers = images.map { $0 != nil }

            guard await isCurrentBatch() else { return }

            do {
                let result: VocabularyGradingResult
                if hasVisibleAnswers.contains(true) {
                    let recognitionResult: VocabularyGradingResult
                    if request.isChinese {
                        if request.usesChineseCharacterByCharacterRecognition {
                            recognitionResult = try await VocabularyChineseHandwritingRecognizer.recognizeGrid(
                                drawings: request.drawings,
                                canvasSize: request.canvasSize,
                                engine: request.usesLocalChineseRecognition ? .localVision : .ai
                            )
                        } else if request.usesLocalChineseRecognition {
                            recognitionResult = try await VocabularyChineseHandwritingRecognizer.recognizeWholeAnswers(
                                images: images
                            )
                        } else {
                            recognitionResult = try await AIService.recognizeVocabularyHandwriting(
                                handwritingImages: images,
                                isChinese: true
                            )
                        }
                    } else {
                        recognitionResult = try await AIService.recognizeVocabularyHandwriting(
                            handwritingImages: images,
                            isChinese: false
                        )
                    }
                    result = VocabularyGradingPolicy.validated(
                        recognitionResult,
                        expectedAnswers: request.cards.map {
                            request.kind.referenceAnswer(
                                term: $0.term,
                                englishDefinition: $0.englishDefinition
                            )
                        },
                        hasVisibleAnswers: hasVisibleAnswers,
                        matchPolicy: request.kind == .englishDefinition
                            ? .englishDefinition
                            : request.isChinese ? .chineseDictation : .spelling
                    )
                } else {
                    result = VocabularyGradingPolicy.validated(
                        VocabularyGradingResult(items: []),
                        expectedAnswers: request.cards.map {
                            request.kind.referenceAnswer(
                                term: $0.term,
                                englishDefinition: $0.englishDefinition
                            )
                        },
                        hasVisibleAnswers: hasVisibleAnswers,
                        matchPolicy: request.kind == .englishDefinition
                            ? .englishDefinition
                            : request.isChinese ? .chineseDictation : .spelling
                    )
                }
                await MainActor.run {
                    guard isCurrentBatch() else {
                        return
                    }
                    callbacks.finishSuccess(
                        request.batchIndex,
                        images,
                        result,
                        request.context
                    )
                }
                return
            } catch is CancellationError {
                await callbacks.clearTask(request.batchID, request.context.taskID)
            } catch {
                let message = error.localizedDescription
                await MainActor.run {
                    guard isCurrentBatch() else { return }
                    guard !Task.isCancelled else {
                        callbacks.clearTask(request.batchID, request.context.taskID)
                        return
                    }
                    callbacks.finishFailure(
                        request.batchIndex,
                        images,
                        message,
                        request.context
                    )
                }
            }
        }
    }
}

private enum VocabularyChineseHandwritingRecognizer {
    enum Engine: Sendable {
        case localVision
        case ai
    }

    static func recognizeWholeAnswers(images: [UIImage?]) async throws -> VocabularyGradingResult {
        var items: [VocabularyGradingItem] = []
        items.reserveCapacity(images.count)
        for (offset, image) in images.enumerated() {
            let recognizedText: String
            if let image {
                recognizedText = try await recognizeLocally(image: image, requiresSingleCharacter: false)
            } else {
                recognizedText = ""
            }
            items.append(VocabularyGradingItem(
                index: offset + 1,
                isCorrect: false,
                comment: "",
                recognizedText: recognizedText
            ))
        }
        return VocabularyGradingResult(items: items)
    }

    static func recognizeGrid(
        drawings: [PKDrawing],
        canvasSize: CGSize,
        engine: Engine
    ) async throws -> VocabularyGradingResult {
        guard canvasSize.width > 0, canvasSize.height > 0 else {
            throw NSError(
                domain: "VocabularyChineseGridRecognition",
                code: 1,
                userInfo: [NSLocalizedDescriptionKey: "无法读取方格画布尺寸，请重试。"]
            )
        }

        let cellSide = VocabularyChineseGridLayout.cellSide
        let columns = Int(ceil(canvasSize.width / cellSide))
        let rows = Int(ceil(canvasSize.height / cellSide))
        var items: [VocabularyGradingItem] = []
        items.reserveCapacity(drawings.count)

        for (drawingIndex, drawing) in drawings.enumerated() {
            var occupiedCells = Set<Int>()
            for stroke in drawing.strokes {
                let bounds = stroke.renderBounds
                let centerX = bounds.midX
                let centerY = bounds.midY
                guard centerX >= 0, centerY >= 0,
                      centerX < canvasSize.width, centerY < canvasSize.height else {
                    continue
                }
                let column = min(Int(centerX / cellSide), columns - 1)
                let row = min(Int(centerY / cellSide), rows - 1)
                occupiedCells.insert(row * columns + column)
            }

            var recognizedText = ""
            if !occupiedCells.isEmpty {
                let occupiedCellImages = occupiedCells.sorted().map { cellIndex in
                    let row = cellIndex / columns
                    let column = cellIndex % columns
                    let cellRect = CGRect(
                        x: CGFloat(column) * cellSide,
                        y: CGFloat(row) * cellSide,
                        width: cellSide,
                        height: cellSide
                    )
                    return (cellIndex, renderCell(drawing, cellRect: cellRect))
                }

                var recognizedByCell: [Int: String] = [:]
                try await withThrowingTaskGroup(of: (Int, String).self) { group in
                    var nextImageIndex = 0
                    let initialTaskCount = min(4, occupiedCellImages.count)
                    for _ in 0..<initialTaskCount {
                        let (cellIndex, cellImage) = occupiedCellImages[nextImageIndex]
                        nextImageIndex += 1
                        group.addTask {
                            let character: String
                            switch engine {
                            case .localVision:
                                character = try await recognizeLocally(
                                    image: cellImage,
                                    requiresSingleCharacter: true
                                )
                            case .ai:
                                character = try await AIService.recognizeChineseHandwrittenCharacter(
                                    image: cellImage
                                )
                            }
                            return (cellIndex, character)
                        }
                    }

                    while let result = try await group.next() {
                        recognizedByCell[result.0] = result.1
                        guard nextImageIndex < occupiedCellImages.count else { continue }
                        let (cellIndex, cellImage) = occupiedCellImages[nextImageIndex]
                        nextImageIndex += 1
                        group.addTask {
                            let character: String
                            switch engine {
                            case .localVision:
                                character = try await recognizeLocally(
                                    image: cellImage,
                                    requiresSingleCharacter: true
                                )
                            case .ai:
                                character = try await AIService.recognizeChineseHandwrittenCharacter(
                                    image: cellImage
                                )
                            }
                            return (cellIndex, character)
                        }
                    }
                }

                // Blank grid cells are not failed recognition attempts. Only
                // concatenate cells containing ink; otherwise unused cells at
                // the end of one writing row become phantom replacement marks.
                recognizedText = occupiedCellImages.map { cell in
                    recognizedByCell[cell.0] ?? "�"
                }.joined()
            }

            items.append(VocabularyGradingItem(
                index: drawingIndex + 1,
                isCorrect: false,
                comment: "",
                recognizedText: recognizedText
            ))
        }

        return VocabularyGradingResult(items: items)
    }

    private static func recognizeLocally(
        image: UIImage,
        requiresSingleCharacter: Bool
    ) async throws -> String {
        guard let cgImage = image.cgImage else { return "�" }
        return try await Task.detached(priority: .userInitiated) {
            let request = VNRecognizeTextRequest()
            request.recognitionLevel = .accurate
            request.recognitionLanguages = ["zh-Hans"]
            request.automaticallyDetectsLanguage = false
            request.usesLanguageCorrection = false
            request.minimumTextHeight = 0.02

            let handler = VNImageRequestHandler(cgImage: cgImage, options: [:])
            try handler.perform([request])

            let observations = request.results ?? []
            let recognizedText: String
            if requiresSingleCharacter {
                guard let observation = observations.max(by: { first, second in
                    (first.topCandidates(1).first?.confidence ?? 0)
                        < (second.topCandidates(1).first?.confidence ?? 0)
                }),
                      let candidate = observation.topCandidates(1).first else {
                    return "�"
                }
                recognizedText = candidate.string
            } else {
                recognizedText = observations
                    .sorted { first, second in
                        if abs(first.boundingBox.midY - second.boundingBox.midY) > 0.015 {
                            return first.boundingBox.midY > second.boundingBox.midY
                        }
                        return first.boundingBox.minX < second.boundingBox.minX
                    }
                    .compactMap { $0.topCandidates(1).first?.string }
                    .joined()
            }
            let trimmedText = recognizedText.trimmingCharacters(in: .whitespacesAndNewlines)
            guard !trimmedText.isEmpty else { return "�" }
            if requiresSingleCharacter && trimmedText.count != 1 {
                return "�"
            }
            return trimmedText
        }.value
    }

    private static func renderCell(_ drawing: PKDrawing, cellRect: CGRect) -> UIImage {
        var inkBounds = CGRect.null
        for stroke in drawing.strokes {
            let bounds = stroke.renderBounds
            guard cellRect.contains(CGPoint(x: bounds.midX, y: bounds.midY)) else { continue }
            let clippedBounds = bounds.intersection(cellRect)
            if !clippedBounds.isNull, !clippedBounds.isEmpty {
                inkBounds = inkBounds.isNull ? clippedBounds : inkBounds.union(clippedBounds)
            }
        }

        let padding = max(4, cellRect.width * 0.08)
        let cropRect = inkBounds
            .insetBy(dx: -padding, dy: -padding)
            .intersection(cellRect)
        guard !cropRect.isNull, !cropRect.isEmpty else {
            return renderBlankCell(size: cellRect.size)
        }

        // Give on-device Vision a close, high-resolution crop of this glyph.
        let format = UIGraphicsImageRendererFormat()
        format.scale = 3
        format.opaque = true
        let outputSize = CGSize(width: 192, height: 192)
        let renderer = UIGraphicsImageRenderer(size: outputSize, format: format)
        let characterDrawing = drawing.image(from: cropRect, scale: format.scale)
        return renderer.image { context in
            UIColor.white.setFill()
            context.fill(CGRect(origin: .zero, size: outputSize))
            let scale = min(outputSize.width / cropRect.width, outputSize.height / cropRect.height)
            let fittedSize = CGSize(width: cropRect.width * scale, height: cropRect.height * scale)
            let destination = CGRect(
                x: (outputSize.width - fittedSize.width) / 2,
                y: (outputSize.height - fittedSize.height) / 2,
                width: fittedSize.width,
                height: fittedSize.height
            )
            characterDrawing.draw(in: destination)
        }
    }

    private static func renderBlankCell(size: CGSize) -> UIImage {
        ImageRenderSupport.opaqueImage(size: size) { context in
            ImageRenderSupport.fillWhiteBackground(
                in: CGRect(origin: .zero, size: size),
                context: context
            )
        }
    }
}
