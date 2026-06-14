import AppKit
import Foundation
import Vision

enum ImageOCRError: LocalizedError {
    case fileNotFound(String)
    case noText(String)
    case clipboardWriteFailed

    var errorDescription: String? {
        switch self {
        case .fileNotFound(let path):
            return "ファイルが見つかりません: \(path)"
        case .noText(let path):
            return "文字を認識できませんでした: \(path)"
        case .clipboardWriteFailed:
            return "クリップボードへの書き込みに失敗しました"
        }
    }
}

struct RecognizedLine {
    let text: String
    let boundingBox: CGRect
}

func printUsage() {
    let command = URL(fileURLWithPath: CommandLine.arguments[0]).lastPathComponent
    FileHandle.standardError.write(
        Data("""
        使い方:
          \(command) IMAGE [IMAGE ...]

        動作:
          - Apple Visionで日本語・英語を文字認識
          - 元画像と同じフォルダに「元画像名.ocr.txt」を保存
          - 全画像の認識結果をクリップボードへコピー

        例:
          \(command) ~/Desktop/screenshot.png
          \(command) ~/Desktop/page1.png ~/Desktop/page2.jpg

        """.utf8)
    )
}

func sidecarURL(for imageURL: URL) -> URL {
    let baseName = imageURL.deletingPathExtension().lastPathComponent
    return imageURL
        .deletingLastPathComponent()
        .appendingPathComponent("\(baseName).ocr.txt")
}

func recognizeText(in imageURL: URL) throws -> String {
    guard FileManager.default.fileExists(atPath: imageURL.path) else {
        throw ImageOCRError.fileNotFound(imageURL.path)
    }

    let request = VNRecognizeTextRequest()
    request.recognitionLevel = .accurate
    request.recognitionLanguages = ["ja-JP", "en-US"]
    request.usesLanguageCorrection = true

    let handler = VNImageRequestHandler(url: imageURL, options: [:])
    try handler.perform([request])

    let lines = (request.results ?? [])
        .compactMap { observation -> RecognizedLine? in
            guard let candidate = observation.topCandidates(1).first else {
                return nil
            }
            return RecognizedLine(
                text: candidate.string,
                boundingBox: observation.boundingBox
            )
        }
        .sorted { lhs, rhs in
            // Visionの座標系は左下原点。上から下、同じ行では左から右へ並べる。
            let lhsRow = Int((lhs.boundingBox.midY * 200).rounded())
            let rhsRow = Int((rhs.boundingBox.midY * 200).rounded())

            if lhsRow != rhsRow {
                return lhsRow > rhsRow
            }
            return lhs.boundingBox.minX < rhs.boundingBox.minX
        }

    let text = lines
        .map(\.text)
        .joined(separator: "\n")
        .trimmingCharacters(in: .whitespacesAndNewlines)

    guard !text.isEmpty else {
        throw ImageOCRError.noText(imageURL.path)
    }

    return text
}

func copyToClipboard(_ text: String) throws {
    let pasteboard = NSPasteboard.general
    pasteboard.clearContents()

    guard pasteboard.setString(text, forType: .string) else {
        throw ImageOCRError.clipboardWriteFailed
    }
}

let arguments = Array(CommandLine.arguments.dropFirst())

guard !arguments.isEmpty else {
    printUsage()
    exit(64)
}

var clipboardBlocks: [String] = []
var failed = false

for argument in arguments {
    let imageURL = URL(fileURLWithPath: argument).standardizedFileURL

    do {
        let text = try recognizeText(in: imageURL)
        let outputURL = sidecarURL(for: imageURL)

        try text.write(
            to: outputURL,
            atomically: true,
            encoding: .utf8
        )

        if arguments.count == 1 {
            clipboardBlocks.append(text)
        } else {
            clipboardBlocks.append(
                """
                ## \(imageURL.lastPathComponent)

                \(text)
                """
            )
        }

        print("\(imageURL.path) -> \(outputURL.path)")
    } catch {
        failed = true
        let message = "エラー: \(error.localizedDescription)\n"
        FileHandle.standardError.write(Data(message.utf8))
    }
}

if !clipboardBlocks.isEmpty {
    do {
        try copyToClipboard(clipboardBlocks.joined(separator: "\n\n"))
    } catch {
        failed = true
        let message = "エラー: \(error.localizedDescription)\n"
        FileHandle.standardError.write(Data(message.utf8))
    }
}

exit(failed ? 1 : 0)
