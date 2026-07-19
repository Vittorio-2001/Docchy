//
//  DocumentInsight.swift
//  Docchy
//
//  Created by Vittorio Monfrecola on 12/07/2026.
//


import UIKit
import Vision

struct DocumentInsight {
    let recognizedText: String
    let hasReadableText: Bool
}

/// Esegue il riconoscimento del testo (OCR) sulle pagine scansionate usando
/// il framework Vision di Apple: tutto on-device, nessuna rete, nessun costo.
enum DocumentAnalyzer {

    static func analyze(pages: [UIImage]) async -> DocumentInsight {
        var recognizedPages: [String] = []

        for image in pages {
            guard let cgImage = image.cgImage else { continue }
            let text = await recognizeText(in: cgImage)
            if !text.isEmpty {
                recognizedPages.append(text)
            }
        }

        let combined = recognizedPages.joined(separator: "\n")
        // Soglia minima: sotto una certa lunghezza consideriamo la scansione poco leggibile
        // (es. foto sfocata, documento capovolto, pagina quasi vuota)
        let hasReadableText = combined.trimmingCharacters(in: .whitespacesAndNewlines).count >= 20

        return DocumentInsight(recognizedText: combined, hasReadableText: hasReadableText)
    }

    private static func recognizeText(in cgImage: CGImage) async -> String {
        await withCheckedContinuation { continuation in
            let request = VNRecognizeTextRequest { request, error in
                guard error == nil,
                      let observations = request.results as? [VNRecognizedTextObservation] else {
                    continuation.resume(returning: "")
                    return
                }
                let text = observations
                    .compactMap { $0.topCandidates(1).first?.string }
                    .joined(separator: "\n")
                continuation.resume(returning: text)
            }
            request.recognitionLevel = .accurate
            request.recognitionLanguages = ["it-IT", "en-US"]
            request.usesLanguageCorrection = true

            let handler = VNImageRequestHandler(cgImage: cgImage, options: [:])
            do {
                try handler.perform([request])
            } catch {
                continuation.resume(returning: "")
            }
        }
    }
}