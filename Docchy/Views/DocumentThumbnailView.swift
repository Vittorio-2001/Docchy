//
//  DocumentThumbnailView.swift
//  Docchy
//
//  Created by Vittorio Monfrecola on 04/08/2026.
//


import SwiftUI
import PDFKit

struct DocumentThumbnailView: View {
    let document: ScannedDocument
    @State private var thumbnail: UIImage?

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 4)
                .fill(.fill.tertiary)

            if let thumbnail {
                Image(uiImage: thumbnail)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .clipShape(RoundedRectangle(cornerRadius: 4))
            } else {
                Image(systemName: "doc.text")
                    .font(.title2)
                    .foregroundStyle(.secondary)
            }
        }
        .frame(width: 38, height: 48)
        .task(id: document.fileName) {
            thumbnail = await Self.loadThumbnail(url: document.fileURL)
        }
    }

    private static func loadThumbnail(url: URL) async -> UIImage? {
        await Task.detached(priority: .utility) {
            guard let pdfDocument = PDFDocument(url: url),
                  let page = pdfDocument.page(at: 0) else {
                return nil
            }
            return await page.rasterized(scale: 0.3)
        }.value
    }
}
