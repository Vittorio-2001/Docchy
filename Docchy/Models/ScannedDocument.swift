//
//  ScannedDocument.swift
//  Docchy
//
//  Created by Vittorio Monfrecola on 11/07/2026.
//


import Foundation
import SwiftData

@Model
final class ScannedDocument {
    var id: UUID
    var title: String
    var createdAt: Date
    var pageCount: Int
    var fileName: String
    var recognizedText: String
    var expirationDate: Date?
    var isLocked: Bool

    init(
        id: UUID = UUID(),
        title: String,
        createdAt: Date = .now,
        pageCount: Int,
        fileName: String,
        recognizedText: String = "",
        expirationDate: Date? = nil,
        isLocked: Bool = false
    ) {
        self.id = id
        self.title = title
        self.createdAt = createdAt
        self.pageCount = pageCount
        self.fileName = fileName
        self.recognizedText = recognizedText
        self.expirationDate = expirationDate
        self.isLocked = isLocked
    }

    var fileURL: URL {
        FileManager.default
            .urls(for: .documentDirectory, in: .userDomainMask)[0]
            .appendingPathComponent(fileName)
    }
}
