//
//  ImageExporter.swift
//  Docchy
//
//  Created by Vittorio Monfrecola on 12/07/2026.
//

import UIKit
import PDFKit

enum ImageExportFormat {
    case jpeg
    case png
}

enum ImageExporter {

    /// Copia un file in una cartella temporanea usando il nome scelto dall'utente
    /// (es. il titolo del documento) invece del nome interno generato allo scan.
    /// Usato per far comparire il nome giusto quando si condivide il PDF originale.
    static func renamedCopy(of sourceURL: URL, as baseName: String, extension fileExtension: String) throws -> URL {
        let safeName = baseName.replacingOccurrences(of: "/", with: "-")
        let tempDir = FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString, isDirectory: true)
        try FileManager.default.createDirectory(at: tempDir, withIntermediateDirectories: true)

        let destinationURL = tempDir.appendingPathComponent("\(safeName).\(fileExtension)")
        try FileManager.default.copyItem(at: sourceURL, to: destinationURL)
        return destinationURL
    }

    /// Estrae ogni pagina del PDF come immagine e la salva in una cartella
    /// temporanea nel formato richiesto. Ritorna gli URL dei file generati,
    /// pronti per essere condivisi (es. tramite share sheet).
    static func exportPages(from pdfURL: URL, format: ImageExportFormat, baseName: String) throws -> [URL] {
        guard let document = PDFDocument(url: pdfURL) else {
            throw NSError(domain: "ImageExporter", code: 1,
                           userInfo: [NSLocalizedDescriptionKey: String(localized: "PDF non leggibile")])
        }

        let tempDir = FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString, isDirectory: true)
        try FileManager.default.createDirectory(at: tempDir, withIntermediateDirectories: true)

        var urls: [URL] = []
        let safeName = baseName.replacingOccurrences(of: "/", with: "-")

        for index in 0..<document.pageCount {
            guard let page = document.page(at: index) else { continue }
            let image = page.rasterized(scale: 2.0)

            let fileExtension = format == .jpeg ? "jpg" : "png"
            let data: Data? = format == .jpeg
                ? image.jpegData(compressionQuality: 0.9)
                : image.pngData()

            guard let data else { continue }

            let fileURL = tempDir.appendingPathComponent("\(safeName)_pagina\(index + 1).\(fileExtension)")
            try data.write(to: fileURL)
            urls.append(fileURL)
        }

        return urls
    }
}

extension PDFPage {
    /// Rasterizza la pagina PDF in una UIImage ad alta risoluzione
    func rasterized(scale: CGFloat) -> UIImage {
        let pageBounds = bounds(for: .mediaBox)
        let size = CGSize(width: pageBounds.width * scale, height: pageBounds.height * scale)

        let renderer = UIGraphicsImageRenderer(size: size)
        return renderer.image { context in
            UIColor.white.set()
            context.fill(CGRect(origin: .zero, size: size))

            context.cgContext.translateBy(x: 0, y: size.height)
            context.cgContext.scaleBy(x: scale, y: -scale)

            draw(with: .mediaBox, to: context.cgContext)
        }
    }
}
