//
//  PDFBuilder.swift
//  Docchy
//
//  Created by Vittorio Monfrecola on 12/07/2026.
//

import UIKit
import PDFKit

enum PDFBuilder {

    static func makePDF(from images: [UIImage]) throws -> String {
        let pdfDocument = PDFDocument()

        for (index, image) in images.enumerated() {
            guard let page = PDFPage(image: image) else { continue }
            pdfDocument.insert(page, at: index)
        }

        let fileName = "scan_\(UUID().uuidString).pdf"
        let url = FileManager.default
            .urls(for: .documentDirectory, in: .userDomainMask)[0]
            .appendingPathComponent(fileName)

        guard pdfDocument.write(to: url) else {
            throw NSError(domain: "PDFBuilder", code: 1,
                           userInfo: [NSLocalizedDescriptionKey: String(localized: "Impossibile salvare il PDF")])
        }

        return fileName
    }

    static func deleteFile(named fileName: String) {
        let url = FileManager.default
            .urls(for: .documentDirectory, in: .userDomainMask)[0]
            .appendingPathComponent(fileName)
        try? FileManager.default.removeItem(at: url)
    }
}
